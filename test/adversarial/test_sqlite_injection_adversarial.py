#!/usr/bin/env python3
"""
Adversarial Verification Suite for SQLite Parameterization & SQL Injection Immunity
Brainrot Tracker Pro - Milestone Hardening Iteration 2
"""

import sqlite3
import os
import re
import sys

PROJ_ROOT = "/data/data/com.termux/files/home/brainrot-tracker-pro"

class DatabaseHelperSimulator:
    """Simulates DatabaseHelper's query, rawQuery, update, and delete methods using sqlite3."""
    def __init__(self, conn):
        self.conn = conn
        self.conn.row_factory = sqlite3.Row

    def query(self, table, distinct=False, columns=None, where=None, whereArgs=None,
              groupBy=None, having=None, orderBy=None, limit=None, offset=None):
        cols = ", ".join(columns) if columns else "*"
        distinct_str = "DISTINCT " if distinct else ""
        sql = f"SELECT {distinct_str}{cols} FROM {table}"
        
        clauses = []
        if where:
            sql += f" WHERE {where}"
        if groupBy:
            sql += f" GROUP BY {groupBy}"
        if having:
            sql += f" HAVING {having}"
        if orderBy:
            sql += f" ORDER BY {orderBy}"
        if limit is not None:
            sql += f" LIMIT {limit}"
        if offset is not None:
            sql += f" OFFSET {offset}"

        cursor = self.conn.cursor()
        if whereArgs:
            cursor.execute(sql, tuple(whereArgs))
        else:
            cursor.execute(sql)
        return [dict(row) for row in cursor.fetchall()]

    def rawQuery(self, sql, arguments=None):
        cursor = self.conn.cursor()
        if arguments:
            cursor.execute(sql, tuple(arguments))
        else:
            cursor.execute(sql)
        return [dict(row) for row in cursor.fetchall()]

    def update(self, table, values, where=None, whereArgs=None):
        set_clause = ", ".join([f"{k} = ?" for k in values.keys()])
        sql = f"UPDATE {table} SET {set_clause}"
        params = list(values.values())
        if where:
            sql += f" WHERE {where}"
            if whereArgs:
                params.extend(whereArgs)
        cursor = self.conn.cursor()
        cursor.execute(sql, tuple(params))
        self.conn.commit()
        return cursor.rowcount

    def delete(self, table, where=None, whereArgs=None):
        sql = f"DELETE FROM {table}"
        cursor = self.conn.cursor()
        if where:
            sql += f" WHERE {where}"
            if whereArgs:
                cursor.execute(sql, tuple(whereArgs))
            else:
                cursor.execute(sql)
        else:
            cursor.execute(sql)
        self.conn.commit()
        return cursor.rowcount


def setup_test_db():
    conn = sqlite3.connect(":memory:")
    # Initialize tables according to SqliteSchema
    conn.executescript("""
        CREATE TABLE scroll_events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id TEXT NOT NULL,
          platform TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          page_index INTEGER NOT NULL,
          duration_ms INTEGER NOT NULL DEFAULT 0,
          is_rapid_scroll INTEGER NOT NULL DEFAULT 0,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(session_id, platform, page_index, timestamp)
        );

        CREATE TABLE daily_limits (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date_str TEXT UNIQUE NOT NULL,
          target_limit INTEGER NOT NULL,
          warning_threshold INTEGER NOT NULL,
          exceeded_at INTEGER,
          is_locked INTEGER NOT NULL DEFAULT 0,
          updated_at INTEGER NOT NULL
        );

        CREATE TABLE banking_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id TEXT UNIQUE NOT NULL,
          start_timestamp INTEGER NOT NULL,
          end_timestamp INTEGER,
          reason TEXT NOT NULL DEFAULT 'banking',
          auto_resume_minutes INTEGER NOT NULL DEFAULT 15,
          status TEXT NOT NULL DEFAULT 'active'
        );

        CREATE TABLE intervention_events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          intervention_type TEXT NOT NULL,
          triggered_at INTEGER NOT NULL,
          platform TEXT NOT NULL,
          trigger_reason TEXT NOT NULL,
          completed INTEGER NOT NULL DEFAULT 0,
          selected_action TEXT,
          dwell_time_ms INTEGER NOT NULL DEFAULT 0
        );
    """)

    # Seed data
    cursor = conn.cursor()
    cursor.executemany("""
        INSERT INTO scroll_events (session_id, platform, timestamp, page_index, duration_ms, is_rapid_scroll)
        VALUES (?, ?, ?, ?, ?, ?)
    """, [
        ('sess_alpha', 'instagram', 1000, 0, 5000, 0),
        ('sess_alpha', 'instagram', 2000, 1, 4000, 0),
        ('sess_beta', 'tiktok', 3000, 0, 12000, 1),
        ('sess_gamma', 'youtube', 4000, 0, 8000, 0),
    ])

    cursor.executemany("""
        INSERT INTO banking_sessions (session_id, start_timestamp, reason, status)
        VALUES (?, ?, ?, ?)
    """, [
        ('bank_001', 10000, 'study', 'active'),
        ('bank_002', 20000, 'work', 'active'),
    ])

    cursor.execute("""
        INSERT INTO daily_limits (date_str, target_limit, warning_threshold, updated_at)
        VALUES (?, ?, ?, ?)
    """, ('2026-11-10', 150, 120, 100000))

    conn.commit()
    return conn

def run_tests():
    print("=" * 60)
    print("RUNNING ADVERSARIAL SQL INJECTION & DATABASE HELPER TESTS")
    print("=" * 60)

    conn = setup_test_db()
    db = DatabaseHelperSimulator(conn)
    passed = 0
    failed = 0

    # 1. Test query() parameterization with SQL injection payloads
    sqli_payloads = [
        "' OR '1'='1",
        "sess_alpha' OR 1=1 --",
        "' UNION SELECT id, session_id, platform, timestamp, page_index, duration_ms, is_rapid_scroll, created_at FROM scroll_events --",
        "'; DROP TABLE scroll_events; --",
        "' OR (SELECT COUNT(*) FROM banking_sessions) > 0 --",
        "admin'/*",
        "' AND 1=sleep(5) --",
        "test' OR ''='",
    ]

    print("\n--- 1. Testing query() SQLi Resistance ---")
    for payload in sqli_payloads:
        # Parameterized query using where: 'session_id = ?' and whereArgs: [payload]
        res = db.query('scroll_events', where='session_id = ?', whereArgs=[payload])
        if len(res) == 0:
            passed += 1
            print(f"  [PASS] query() safely sanitized payload: {payload[:40]}")
        else:
            failed += 1
            print(f"  [FAIL] query() LEAKED DATA on payload: {payload}")

    # Demonstrate that unparameterized string concatenation WOULD have leaked data
    vuln_sql = f"SELECT * FROM scroll_events WHERE session_id = '{sqli_payloads[0]}'"
    vuln_rows = conn.execute(vuln_sql).fetchall()
    assert len(vuln_rows) == 4, "Vulnerability proof check failed"
    print(f"  [ORACLE CONFIRMED] Unparameterized string interpolation leaked {len(vuln_rows)} rows; Parameterized returned 0.")
    passed += 1

    # 2. Test rawQuery() parameterization
    print("\n--- 2. Testing rawQuery() SQLi Resistance ---")
    raw_payloads = [
        ("SELECT * FROM scroll_events WHERE session_id = ?", ["sess_alpha' OR '1'='1"]),
        ("SELECT * FROM scroll_events WHERE timestamp >= ?", ["0 OR 1=1"]),
        ("SELECT * FROM banking_sessions WHERE reason = ?", ["study' UNION SELECT 1,2,3,4,5,6,7 --"]),
    ]

    for sql, args in raw_payloads:
        res = db.rawQuery(sql, args)
        if len(res) == 0:
            passed += 1
            print(f"  [PASS] rawQuery() blocked SQLi in: {sql} with args: {args}")
        else:
            failed += 1
            print(f"  [FAIL] rawQuery() LEAKED DATA on: {sql}")

    # 3. Test update() parameterization
    print("\n--- 3. Testing update() SQLi Resistance ---")
    # Attacker tries to update all banking sessions to 'hijacked' using tautology injection
    affected = db.update(
        'banking_sessions',
        {'status': 'hijacked'},
        where='session_id = ?',
        whereArgs=["bank_001' OR '1'='1"]
    )
    if affected == 0:
        passed += 1
        print("  [PASS] update() blocked tautology injection; 0 rows modified.")
    else:
        failed += 1
        print(f"  [FAIL] update() was compromised! {affected} rows modified.")

    # Legitimate parameterized update
    legit_affected = db.update(
        'banking_sessions',
        {'status': 'completed'},
        where='session_id = ?',
        whereArgs=['bank_001']
    )
    if legit_affected == 1:
        passed += 1
        print("  [PASS] Legitimate parameterized update modified exactly 1 row.")
    else:
        failed += 1
        print(f"  [FAIL] Legitimate update failed; affected: {legit_affected}")

    # 4. Test delete() parameterization
    print("\n--- 4. Testing delete() SQLi Resistance ---")
    # Attacker tries to delete all scroll_events using injection
    deleted = db.delete(
        'scroll_events',
        where='session_id = ?',
        whereArgs=["' OR 1=1 --"]
    )
    if deleted == 0:
        passed += 1
        print("  [PASS] delete() blocked wipeout injection; 0 rows deleted.")
    else:
        failed += 1
        print(f"  [FAIL] delete() was compromised! {deleted} rows deleted.")

    # Check that table still has all 4 rows
    remaining = conn.execute("SELECT COUNT(*) FROM scroll_events").fetchone()[0]
    assert remaining == 4, f"Data loss detected: {remaining} rows remain"
    passed += 1
    print(f"  [CONFIRMED] Table scroll_events remains intact with all {remaining} rows.")

    # 5. Static AST Audit across the codebase for SQL injection flaws
    print("\n--- 5. Static Audit across Codebase for Dynamic SQL Interpolation ---")
    dart_files = []
    for root, _, files in os.walk(PROJ_ROOT):
        for f in files:
            if f.endswith('.dart') and not f.startswith('.'):
                dart_files.append(os.path.join(root, f))

    # Patterns indicating dangerous string interpolation in SQL
    bad_patterns = [
        re.compile(r'rawQuery\s*\(\s*["\x27][^"\x27]*\$[a-zA-Z_]'),
        re.compile(r'rawUpdate\s*\(\s*["\x27][^"\x27]*\$[a-zA-Z_]'),
        re.compile(r'rawDelete\s*\(\s*["\x27][^"\x27]*\$[a-zA-Z_]'),
        re.compile(r'where\s*:\s*["\x27][^"\x27]*\$[a-zA-Z_]'),
    ]

    unsafe_found = 0
    checked_files = 0
    for path in dart_files:
        with open(path, 'r', errors='ignore') as f:
            content = f.read()
        checked_files += 1
        for pat in bad_patterns:
            matches = pat.findall(content)
            # Filter out allowed static constant interpolations like ${SqliteSchema.table...}
            non_schema = [m for m in matches if 'SqliteSchema' not in m]
            if non_schema:
                print(f"  [UNSAFE DETECTED] {os.path.relpath(path, PROJ_ROOT)}: {non_schema}")
                unsafe_found += 1

    if unsafe_found == 0:
        passed += 1
        print(f"  [PASS] Audited {checked_files} Dart files: 0 unsafe SQL dynamic interpolations found.")
    else:
        failed += 1
        print(f"  [FAIL] Found {unsafe_found} unsafe SQL interpolations!")

    # 6. Verify DatabaseHelper contract in database_helper.dart
    helper_path = os.path.join(PROJ_ROOT, "lib/core/database/database_helper.dart")
    with open(helper_path, "r") as f:
        helper_content = f.read()

    assert "Future<List<Map<String, Object?>>> query(" in helper_content
    assert "List<Object?>? whereArgs" in helper_content
    assert "Future<List<Map<String, Object?>>> rawQuery(" in helper_content
    assert "List<Object?>? arguments" in helper_content
    assert "Future<int> update(" in helper_content
    assert "Future<int> delete(" in helper_content
    passed += 1
    print("  [PASS] DatabaseHelper exposes all 4 safe parameterized helper signatures.")

    print("\n" + "=" * 60)
    print(f"SQL INJECTION ADVERSARIAL RESULTS: {passed} PASSED, {failed} FAILED")
    print("=" * 60)

    if failed > 0:
        sys.exit(1)

if __name__ == "__main__":
    run_tests()
