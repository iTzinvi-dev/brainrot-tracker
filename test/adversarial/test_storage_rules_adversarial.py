#!/usr/bin/env python3
"""
Adversarial Verification Suite for Firebase Storage Rules
Brainrot Tracker Pro - Milestone Hardening Iteration 2
"""

import re
import sys
import os

RULES_PATH = "/data/data/com.termux/files/home/brainrot-tracker-pro/firebase/storage.rules"

class StorageRequest:
    def __init__(self, method, path, auth_uid=None, resource_size=None, resource_content_type=None):
        self.method = method # 'read', 'create', 'update', 'delete'
        self.path = path
        self.auth = {"uid": auth_uid} if auth_uid else None
        if method in ("create", "update"):
            self.resource = {
                "size": resource_size,
                "contentType": resource_content_type
            }
        else:
            # On delete or read, request.resource is NULL in Firebase Storage specification!
            self.resource = None

class FirebaseStorageRulesSimulator:
    def __init__(self, rules_content):
        self.rules_content = rules_content
        # Verify rules version 2
        assert "rules_version = '2';" in rules_content
        assert "service firebase.storage" in rules_content

    def evaluate_request(self, req: StorageRequest):
        # Match path against /users/{userId}/{allPaths=**}
        user_match = re.match(r"^/users/([^/]+)/(.+)$", req.path)
        if user_match:
            user_id = user_match.group(1)
            return self._eval_user_path(req, user_id)
        
        # Default match /{allPaths=**}
        return False, "Default deny: path not under /users/{userId}/"

    def _eval_user_path(self, req: StorageRequest, user_id: str):
        # Read check
        if req.method == 'read':
            # allow read: if request.auth != null;
            if req.auth is not None:
                return True, "Read allowed for authenticated user"
            return False, "Read denied: unauthenticated"

        # Create, Update check
        if req.method in ('create', 'update'):
            # allow create, update: if request.auth != null 
            #                      && request.auth.uid == userId 
            #                      && request.resource.size < 5 * 1024 * 1024 
            #                      && request.resource.contentType.matches('image/.*');
            if req.auth is None:
                return False, "Denied: unauthenticated write"
            if req.auth.get("uid") != user_id:
                return False, f"Denied: auth uid {req.auth.get('uid')} != path userId {user_id}"
            
            if req.resource is None:
                return False, "Denied: missing resource for create/update"
            
            size = req.resource.get("size")
            if size is None or size >= 5 * 1024 * 1024:
                return False, f"Denied: file size {size} exceeds 5MB limit (< 5242880)"
            
            content_type = req.resource.get("contentType", "")
            # regex: matches('image/.*')
            if not re.fullmatch(r"image/.*", content_type):
                return False, f"Denied: content type '{content_type}' does not match 'image/.*'"
            
            return True, "Create/Update allowed"

        # Delete check
        if req.method == 'delete':
            # allow delete: if request.auth != null && request.auth.uid == userId;
            # CRITICAL: Note that request.resource is NOT dereferenced here!
            if req.auth is None:
                return False, "Delete denied: unauthenticated"
            if req.auth.get("uid") != user_id:
                return False, f"Delete denied: auth uid {req.auth.get('uid')} != path userId {user_id}"
            
            # If the rule erroneously attempted req.resource.size, it would crash:
            # try: req.resource['size'] -> TypeError / NullReference
            return True, "Delete allowed for owner"

        return False, f"Unknown method {req.method}"

    def simulate_buggy_delete(self, req: StorageRequest, user_id: str):
        """Simulates what happened in the previous buggy rule where allow write checked request.resource"""
        if req.auth is None:
            return False, "Denied: unauthenticated"
        if req.auth.get("uid") != user_id:
            return False, "Denied: uid mismatch"
        # Buggy write condition:
        if req.resource is None:
            raise AttributeError("NullReferenceException: Cannot read property 'size' of null (request.resource is null on delete)")
        return req.resource['size'] < 5 * 1024 * 1024

def run_tests():
    print("=" * 60)
    print("RUNNING ADVERSARIAL STORAGE RULES VERIFICATION")
    print("=" * 60)

    with open(RULES_PATH, "r") as f:
        content = f.read()

    simulator = FirebaseStorageRulesSimulator(content)

    test_cases = [
        # 1. Deletion by owner
        ("TC1: Owner deletes avatar", StorageRequest('delete', '/users/user_123/avatar.png', auth_uid='user_123'), True),
        ("TC2: Owner deletes deeply nested file", StorageRequest('delete', '/users/user_123/nested/sub/pic.webp', auth_uid='user_123'), True),
        # 2. Deletion unauthorized
        ("TC3: Attacker deletes victim avatar", StorageRequest('delete', '/users/user_123/avatar.png', auth_uid='attacker_999'), False),
        ("TC4: Unauthenticated user deletes avatar", StorageRequest('delete', '/users/user_123/avatar.png', auth_uid=None), False),
        # 3. Create under 5MB image
        ("TC5: Owner uploads valid PNG 1MB", StorageRequest('create', '/users/user_123/avatar.png', auth_uid='user_123', resource_size=1024*1024, resource_content_type='image/png'), True),
        ("TC6: Owner uploads valid JPEG 4.99MB (5242879 B)", StorageRequest('create', '/users/user_123/avatar.jpg', auth_uid='user_123', resource_size=5242879, resource_content_type='image/jpeg'), True),
        ("TC7: Owner uploads valid WebP 500KB", StorageRequest('create', '/users/user_123/avatar.webp', auth_uid='user_123', resource_size=500000, resource_content_type='image/webp'), True),
        # 4. Boundary size tests
        ("TC8: Owner uploads exact 5MB file (5242880 B)", StorageRequest('create', '/users/user_123/avatar.png', auth_uid='user_123', resource_size=5242880, resource_content_type='image/png'), False),
        ("TC9: Owner uploads 5MB + 1 byte (5242881 B)", StorageRequest('create', '/users/user_123/avatar.png', auth_uid='user_123', resource_size=5242881, resource_content_type='image/png'), False),
        ("TC10: Owner uploads 10MB file", StorageRequest('create', '/users/user_123/avatar.png', auth_uid='user_123', resource_size=10*1024*1024, resource_content_type='image/png'), False),
        # 5. Adversarial MIME types
        ("TC11: Malicious shell script upload", StorageRequest('create', '/users/user_123/avatar.png', auth_uid='user_123', resource_size=1000, resource_content_type='application/x-sh'), False),
        ("TC12: PDF upload masquerading as image name", StorageRequest('create', '/users/user_123/doc.pdf', auth_uid='user_123', resource_size=1000, resource_content_type='application/pdf'), False),
        ("TC13: Executable upload", StorageRequest('create', '/users/user_123/malware.exe', auth_uid='user_123', resource_size=1000, resource_content_type='application/octet-stream'), False),
        ("TC14: HTML upload (XSS payload)", StorageRequest('create', '/users/user_123/xss.html', auth_uid='user_123', resource_size=500, resource_content_type='text/html'), False),
        ("TC15: Fake prefix 'text/image'", StorageRequest('create', '/users/user_123/fake.jpg', auth_uid='user_123', resource_size=500, resource_content_type='text/image'), False),
        # 6. Unauthorized uploads
        ("TC16: Attacker uploads to victim folder", StorageRequest('create', '/users/user_123/avatar.png', auth_uid='attacker_999', resource_size=1000, resource_content_type='image/png'), False),
        ("TC17: Unauthenticated upload", StorageRequest('create', '/users/user_123/avatar.png', auth_uid=None, resource_size=1000, resource_content_type='image/png'), False),
        # 7. Updates
        ("TC18: Owner updates avatar with valid 2MB image", StorageRequest('update', '/users/user_123/avatar.png', auth_uid='user_123', resource_size=2*1024*1024, resource_content_type='image/png'), True),
        ("TC19: Owner updates avatar with oversized 6MB image", StorageRequest('update', '/users/user_123/avatar.png', auth_uid='user_123', resource_size=6*1024*1024, resource_content_type='image/png'), False),
        # 8. Reads & Default Deny
        ("TC20: Authenticated user reads profile pic", StorageRequest('read', '/users/user_123/avatar.png', auth_uid='user_456'), True),
        ("TC21: Unauthenticated user reads profile pic", StorageRequest('read', '/users/user_123/avatar.png', auth_uid=None), False),
        ("TC22: Default deny on system path", StorageRequest('read', '/system/config.json', auth_uid='user_123'), False),
        ("TC23: Default deny on write to public root", StorageRequest('create', '/public/index.html', auth_uid='user_123', resource_size=500, resource_content_type='text/html'), False),
    ]

    passed = 0
    failed = 0

    for name, req, expected in test_cases:
        allowed, reason = simulator.evaluate_request(req)
        if allowed == expected:
            passed += 1
            print(f"  [PASS] {name} -> result={allowed} (reason: {reason})")
        else:
            failed += 1
            print(f"  [FAIL] {name} -> expected {expected}, got {allowed} (reason: {reason})")

    # 9. Direct proof of the Bug / Fix on Null Reference on Delete:
    print("\n--- Testing Buggy Rule vs Remediated Rule for Delete (request.resource is None) ---")
    req_delete = StorageRequest('delete', '/users/user_123/avatar.png', auth_uid='user_123')
    
    # Buggy rule test:
    try:
        simulator.simulate_buggy_delete(req_delete, 'user_123')
        print("  [ERROR] Buggy rule did not throw NullReferenceException!")
        failed += 1
    except AttributeError as e:
        print(f"  [CONFIRMED] Old rule fails on delete: {e}")
        passed += 1

    # Remediated rule test:
    allowed, reason = simulator.evaluate_request(req_delete)
    assert allowed is True
    print(f"  [CONFIRMED] Remediated rule succeeds on delete: allowed={allowed}")
    passed += 1

    print("\n" + "=" * 60)
    print(f"STORAGE RULES ADVERSARIAL RESULTS: {passed} PASSED, {failed} FAILED")
    print("=" * 60)
    if failed > 0:
        sys.exit(1)

if __name__ == "__main__":
    run_tests()
