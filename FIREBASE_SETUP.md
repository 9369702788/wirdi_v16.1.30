# Firebase Setup Guide for Wirdi

## Your Firebase Project
- **Project ID:** wirdi-cb813
- **Package name:** com.wirdi.wirdi
- **Console:** https://console.firebase.google.com/project/wirdi-cb813

> NOTE: an earlier project (`wirdi-cd6c0`) was retired during development.
> `wirdi-cb813` is the single current, live production project.

---

## Step 1 — Enable Authentication Methods

1. Go to **Firebase Console → Authentication → Sign-in method**
2. Enable **Email/Password** → Save
3. Enable **Google** → add your support email → Save
4. Enable **Apple** (only needed for iOS) → requires Apple Developer account

---

## Step 2 — Add SHA-1 Fingerprint (CRITICAL for Google Sign-In)

Google Sign-In on Android requires your app's SHA-1 fingerprint to be registered in Firebase.

### Get your debug SHA-1:
```bash
# On Mac/Linux:
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# On Windows:
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Add to Firebase:
1. Firebase Console → **Project Settings** (gear icon)
2. Scroll to **Your apps** → Android app (com.wirdi.wirdi)
3. Click **Add fingerprint**
4. Paste your SHA-1 → Save
5. **Download the new google-services.json** and replace the one in your repo

---

## Step 3 — Set Firestore Security Rules

1. Go to **Firestore Database → Rules**
2. Replace the default rules with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }
  }
}
```

3. Click **Publish**

---

## Step 4 — Verify Firestore is in Production Mode

1. Go to **Firestore Database**
2. Confirm it shows **Production mode** (not Test mode)
3. Test mode allows anyone to read/write — never ship with test mode!

---

## Step 5 — Enable Google Sign-In Web Client

After enabling Google Sign-In, Firebase creates a **Web Client ID**.
To find it:
1. Firebase Console → **Project Settings → General**
2. Scroll to **Your apps** → Web app (or create one)
3. Copy the **Web client ID** (ends in `.apps.googleusercontent.com`)
4. Add it to `lib/core/services/auth_service.dart`:

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
);
```

---

## Step 6 — For iOS (future)

1. Run `flutterfire configure` on a Mac with Xcode installed
2. This generates `GoogleService-Info.plist` and updates `lib/firebase_options.dart`
3. Add Apple Sign-In capability in Xcode

---

## Firestore Data Structure

Your data is stored at:
```
users/
  {userId}/
    profile        → name, email, photo, lastSyncAt
    settings       → theme, locale, fontSize, wirdTarget
    quran_progress → lastSurah, lastAyah, totalPagesRead
    tasbeeh        → phrases:{phraseId: count}, grandTotal
    achievements   → unlockedIds: [...]
    favorites      → data (JSON string)
    bookmarks      → data (JSON string)
    khatma         → plans (JSON string)
    prayer_log     → data (JSON string)
```

---

## Troubleshooting

| Problem | Solution |
|---|---|
| Google Sign-In fails silently | Add SHA-1 fingerprint (Step 2) |
| "PlatformException: sign_in_failed" | SHA-1 not registered, or Google not enabled |
| Firestore permission denied | Check security rules (Step 3) |
| Firebase.initializeApp() crashes | Check google-services.json is in android/app/ |
| Apple Sign-In not working | Requires Apple Developer account + Mac |
