# Marnie Store POS v2.1 — Flutter

Full Point-of-Sale app built with Flutter, Firebase Firestore, and SQLite offline support.
Exact same data structure and UI logic as the original React web app.

---

## Quick Start

### 1. Firebase Setup (Required)

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create a project (or use existing)
3. Enable **Authentication → Email/Password**
4. Enable **Cloud Firestore** (production mode)
5. Add Android app with package name `com.marnie.pos`
6. Download `google-services.json`
7. Place it at `android/app/google-services.json`

**Firestore security rules:**
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 2. Local Development

```bash
# Install Flutter 3.22+ (stable)
# https://docs.flutter.dev/get-started/install

cd marnie_pos_flutter
flutter pub get

# Place google-services.json at android/app/google-services.json

# Run debug
flutter run

# Build release APK manually
flutter build apk --release \
  --dart-define=FIREBASE_API_KEY="AIza..." \
  --dart-define=FIREBASE_ANDROID_APP_ID="1:123:android:abc" \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="123456789" \
  --dart-define=FIREBASE_PROJECT_ID="your-project-id" \
  --dart-define=FIREBASE_STORAGE_BUCKET="your-project.appspot.com"
```

---

## GitHub Actions CI/CD

Push to `main` → APK is built automatically.

### Required Repository Secrets

Go to: **Settings → Secrets and variables → Actions → New repository secret**

| Secret | Where to find it |
|--------|-----------------|
| `GOOGLE_SERVICES_JSON` | Full JSON content of `google-services.json` |
| `FIREBASE_API_KEY` | Firebase Console → Project Settings → Web API Key |
| `FIREBASE_ANDROID_APP_ID` | e.g. `1:123456:android:abcdef` |
| `FIREBASE_MESSAGING_SENDER_ID` | Project number from Firebase |
| `FIREBASE_PROJECT_ID` | e.g. `marnie-pos-xxxxx` |
| `FIREBASE_STORAGE_BUCKET` | e.g. `marnie-pos-xxxxx.appspot.com` |
| `FIREBASE_AUTH_DOMAIN` | e.g. `marnie-pos-xxxxx.firebaseapp.com` |
| `FIREBASE_MEASUREMENT_ID` | e.g. `G-XXXXXX` (optional) |

### Optional: Release Signing

| Secret | Value |
|--------|-------|
| `KEYSTORE_BASE64` | `base64 -i your.keystore` |
| `KEYSTORE_PASSWORD` | keystore password |
| `KEY_ALIAS` | key alias |
| `KEY_PASSWORD` | key password |

**Generate a keystore:**
```bash
keytool -genkey -v -keystore marnie-pos.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias marnie-pos

# Encode for GitHub secret
base64 -i marnie-pos.jks | tr -d '\n'
```

### Download the APK
1. Go to **Actions** tab in GitHub
2. Click latest workflow run
3. Scroll to **Artifacts** → download `marnie-pos-release-N`

---

## Project Structure

```
lib/
├── main.dart                    # App entry, Firebase init, AuthGate
├── firebase_options.dart        # Config injected via --dart-define
├── models/
│   └── models.dart              # Product, Customer, Purchase, PurchaseItem
├── services/
│   ├── local_db.dart            # SQLite CRUD (sqflite)
│   ├── firestore_service.dart   # Firestore CRUD + real-time streams
│   └── data_provider.dart       # ChangeNotifier, online/offline bridge
├── screens/
│   ├── login_screen.dart
│   ├── home_screen.dart         # Tab bar + bottom nav
│   ├── dashboard_screen.dart    # Stats, recent tx, low-stock alerts
│   ├── products_screen.dart     # CRUD + barcode scanner
│   ├── new_purchase_screen.dart # Cart, customer autocomplete, receipt
│   ├── customers_screen.dart    # Purchase history, mark paid, edit/delete
│   └── settings_screen.dart     # Stats, export, sign out
├── widgets/
│   └── app_widgets.dart         # Shared UI components
└── utils/
    └── theme.dart               # Dark theme, AppColors
```

---

## Firebase Data Structure

Identical to the original web app:

### `products` collection
```json
{
  "productCode": "PRD-001",
  "name": "Coca Cola 1.5L",
  "costPrice": 50.0,
  "retailPrice": 65.0,
  "price": 65.0,
  "stock": 24,
  "lowStockThreshold": 5,
  "category": "Beverages",
  "createdAt": "2026-01-01T00:00:00.000Z"
}
```

### `customers` collection
```json
{
  "name": "Juan dela Cruz",
  "phone": "09171234567",
  "email": "juan@example.com",
  "createdAt": "2026-01-01T00:00:00.000Z"
}
```

### `purchases` collection
```json
{
  "created_by": "firebase-uid",
  "created_by_email": "user@email.com",
  "customer_id": "customer-doc-id",
  "customer_name": "Juan dela Cruz",
  "product_data": "[{\"product_id\":\"...\",\"name\":\"...\",\"price\":65,\"quantity\":2,\"subtotal\":130}]",
  "purchase_date": "2026-01-01T08:00:00.000Z",
  "status": "pending",
  "total_amount": 130.0
}
```
> `product_data` is a JSON string (same format as web app)

---

## Offline Architecture

```
ONLINE:   Firestore ←→ DataProvider ←→ SQLite (mirror)
OFFLINE:  SQLite ←→ DataProvider  (Firestore paused)

On reconnect:
  1. Unsynced local writes → pushed to Firestore  
  2. Pending local deletes → executed on Firestore  
  3. Firestore real-time listeners restart
  4. SQLite refreshed from Firestore
```

---

## Requirements

- Android 6.0+ (API 23)
- Camera permission for barcode scanning
- Internet for first login and initial sync
- Works fully offline after first load
