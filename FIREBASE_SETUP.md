# 🔥 Firebase Setup & Environment Guide

This document explains the Firebase configuration, environment variables, and steps to connect your own live Firebase project to **Brainrot Tracker Pro**.

---

## 🚀 Quick Start: Offline vs. Live Mode

The app supports **two modes** out of the box:

1. **Offline / Development Mode (Default)**:
   - Requires **zero setup**.
   - Built-in offline fallback options (`MockFirebaseOptions`) and local SQLite storage enable the app to run and pass all tests without internet or live Firebase keys.
2. **Live Cloud Mode (Production)**:
   - Syncs stats across devices.
   - Live friends leaderboard and remote stage threshold updates.

---

## 🔑 Environment Variables (`.env`)

The project uses `.env` with Flutter's native `--dart-define-from-file=.env` mechanism.

A template is provided in [`.env.example`](.env.example):

| Variable Name | Description | Example / Default |
| :--- | :--- | :--- |
| `FIREBASE_API_KEY_ANDROID` | Web/Android API Key from Firebase Console | `AIzaSy...` |
| `FIREBASE_APP_ID_ANDROID` | Android App ID from Firebase Project Settings | `1:123456789012:android:...` |
| `FIREBASE_MESSAGING_SENDER_ID` | Cloud Messaging Sender ID (Project Number) | `123456789012` |
| `FIREBASE_PROJECT_ID` | Unique Firebase Project ID | `brainrot-tracker-pro` |
| `FIREBASE_STORAGE_BUCKET` | Default Cloud Storage bucket | `brainrot-tracker-pro.appspot.com` |
| `FIREBASE_API_KEY_IOS` | iOS API Key (optional for Android builds) | `AIzaSy...` |
| `FIREBASE_APP_ID_IOS` | iOS App ID (optional) | `1:123456789012:ios:...` |

---

## 📋 Step-by-Step: Connecting Your Live Firebase Project

### Step 1: Create a Project in Firebase Console
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add Project** and name it (e.g., `Brainrot Tracker`).
3. (Optional) Enable Google Analytics.

---

### Step 2: Register the Android App
1. Inside your project overview, click the **Android** icon to add an app.
2. Enter the exact Android package name:
   ```text
   com.brainrot.tracker
   ```
3. (Optional) Enter an App nickname (e.g., `Brainrot Tracker Pro`).
4. Click **Register app**.
5. Download **`google-services.json`**.
6. Place the downloaded file into the Android app directory, replacing the placeholder:
   ```bash
   cp ~/Downloads/google-services.json android/app/google-services.json
   ```

---

### Step 3: Populate `.env`
1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```
2. Open `.env` and fill in your keys from **Project Settings ➡️ General ➡️ Your apps ➡️ Web / Android credentials**:
   ```env
   FIREBASE_API_KEY_ANDROID=AIzaSyYourActualKeyHere
   FIREBASE_APP_ID_ANDROID=1:123456789012:android:abcdef123456
   FIREBASE_MESSAGING_SENDER_ID=123456789012
   FIREBASE_PROJECT_ID=your-actual-firebase-project-id
   FIREBASE_STORAGE_BUCKET=your-actual-firebase-project-id.appspot.com
   ```

---

### Step 4: Enable Firebase Services in the Console

#### 1. Authentication
1. In the left navigation, click **Build ➡️ Authentication ➡️ Get Started**.
2. Under **Sign-in method**, enable **Anonymous** (allows instant onboarding with no email required).
3. (Optional) Enable **Google Sign-In** to allow users to link accounts across multiple phones.

#### 2. Cloud Firestore Database
1. In the left navigation, click **Build ➡️ Firestore Database ➡️ Create Database**.
2. Select your preferred database location (e.g., `nam5 (us-central)` or `asia-south1`).
3. Start in **Production mode**.
4. In the **Rules** tab, paste the rules from [`firebase/firestore.rules`](firebase/firestore.rules):
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read: if request.auth != null;
         allow write: if request.auth != null && request.auth.uid == userId;
       }
       match /daily_stats/{statId} {
         allow read: if request.auth != null;
         allow write: if request.auth != null && request.resource.data.userId == request.auth.uid;
       }
     }
   }
   ```

#### 3. Remote Config (Optional)
Under **Build ➡️ Remote Config**, you can dynamically tweak:
- `default_daily_swipe_limit` (Default: `150`)
- `velocity_spike_threshold_spm` (Default: `40.0`)
- `breathe_screen_duration_seconds` (Default: `5`)
- `banking_auto_resume_minutes` (Default: `15`)

---

## 🏃 Running the App with `.env`

To run the application with your custom environment variables loaded:

```bash
# Debug mode with environment definitions
flutter run --dart-define-from-file=.env

# Build production APK with environment definitions
flutter build apk --release --dart-define-from-file=.env
```
