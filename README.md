# 🧹 Cleanova — On-Demand Cleaning Service App

A Flutter mobile application that connects **customers**, **cleaners**, and **admins** through a seamless cleaning service booking platform. Built with Flutter and Firebase.

---

## 📱 App Overview

Cleanova allows customers to book professional cleaning services, cleaners to manage and accept jobs, and admins to oversee the entire platform — including bookings, pricing, payments, and user management.

---
## 📦 Application Release

A pre-built Android APK is available in the GitHub Releases section.

Download the latest release:
[https://github.com/YOUR_USERNAME/cleanova/releases](https://github.com/cleanova95-cell/project-cleanova-/releases)

The APK allows testing without setting up Flutter locally.

## 1. Installation & Running the App

### Prerequisites

Ensure you have the following installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.x or later)
- [Dart SDK](https://dart.dev/get-dart) (comes bundled with Flutter)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter extension
- An Android emulator or physical device (Android 5.0+ / iOS 12+)
- [Firebase CLI](https://firebase.google.com/docs/cli) *(optional, for reconfiguring Firebase)*

### Step 1 — Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/cleanova.git
cd cleanova
```

### Step 2 — Install Dependencies

```bash
flutter pub get
```

### Step 3 — Firebase Setup

The app uses **Firebase** (Authentication, Firestore, Storage, Messaging). The `firebase_options.dart` file is already pre-configured for this project.

> **Note:** If you need to connect to your own Firebase project, replace `lib/firebase_options.dart` by running:
> ```bash
> flutterfire configure
> ```

The following Firebase services are used and must be enabled in your Firebase Console:
- **Authentication** → Email/Password sign-in
- **Cloud Firestore** → Main database
- **Firebase Storage** → Profile and receipt images
- **Firebase Cloud Messaging (FCM)** → Push notifications

### Step 4 — Stripe Payment Setup

The app uses **Stripe** for payments. The publishable key is already set in `lib/main.dart`. If using your own Stripe account, replace the key:

```dart
Stripe.publishableKey = 'your_stripe_publishable_key_here';
```

### Step 5 — Run the App

```bash
flutter run
```

To run on a specific device:

```bash
flutter devices          # list available devices
flutter run -d <device_id>
```

To build a release APK:

```bash
flutter build apk --release
```

---

## 🗄️ Database Setup (Firebase Firestore)

No manual database creation is required. Firestore collections will be generated automatically when users interact with the application.

The app uses **Cloud Firestore** as its primary database. No manual SQL setup is required. Collections are created automatically when users register.

### Firestore Collections

| Collection | Description |
|---|---|
| `users` | Stores all user profiles (customers, cleaners, admins) with their `role` field |
| `bookings` | Booking records including status, schedule, pricing, and assigned cleaner |
| `payments` | Payment records linked to bookings |
| `notifications` | In-app notification documents per user |
| `pricing` | Admin-managed service pricing configurations |

### Firestore Security Rules

Ensure your Firestore rules allow authenticated reads/writes during development:

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

> For production, restrict rules per collection based on user roles.

---

## 3. Default Credentials Per User Role

The app supports **three user roles**. Use the credentials below to log in and test each role.

> **Admin accounts are created directly in Firebase Console** (Firestore + Authentication). Customer and Cleaner accounts can be registered via the in-app registration flow.

The following accounts are provided for testing different user roles:

### 🔑 Admin

| Field | Value |
|---|---|
| **Email** | `fathihahafiqah@graduate.utm.my` |
| **Password** | `cleanova123` |
| **Role** | `admin` |
| **Access** | Full dashboard — booking management, user management, pricing, performance reports |

> Admin accounts must be manually created in Firebase Authentication and have their `role` field set to `"admin"` in Firestore under the `users` collection.

### 👤 Customer (Demo)

| Field | Value |
|---|---|
| **Email** | `hrizhatta@gmail.com` |
| **Password** | `123456` |
| **Role** | `customer` |
| **Access** | Browse services, book cleanings, track bookings, make payments, view history |

> Customers must verify their email before logging in. Use the demo account above or register a new account via **Register as Customer**.

### 🧹 Cleaner (Demo)

| Field | Value |
|---|---|
| **Email** | `nazimaaabbb@gmail.com` |
| **Password** | `123456` |
| **Role** | `cleaner` |
| **Access** | View assigned jobs, accept/decline bookings, track job history, manage profile |

> Cleaners must also verify their email. Use the demo account above or register via **Register as Cleaner**.

---

## ✨ Features

**Customer**
- Register, log in, and verify email
- Browse and book cleaning services
- Choose date, time, and address
- Pay via Stripe (card) or bank transfer
- View booking history and receipts
- Receive push notifications on booking status

**Cleaner**
- Register and manage profile
- View and accept available jobs
- Track assigned bookings and history
- Receive notifications for new job assignments

**Admin**
- Dashboard with customer/cleaner counts
- Manage all bookings (approve, assign, complete)
- Manage pricing for services
- View all users and manage accounts
- Track cleaner performance

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Backend / Database | Firebase Firestore |
| Authentication | Firebase Auth (Email/Password) |
| Storage | Firebase Storage |
| Notifications | Firebase Cloud Messaging + flutter_local_notifications |
| Payments | Stripe (`flutter_stripe`) |

---

## 📁 Project Structure

```
lib/
├── main.dart                     # App entry point, Firebase & Stripe init
├── firebase_options.dart         # Firebase configuration
├── splash_screen.dart            # Splash screen
├── login_page.dart               # Login (routes by role)
├── register_selection_page.dart  # Choose customer or cleaner registration
├── register_customer_page.dart   # Customer registration
├── register_cleaner_page.dart    # Cleaner registration
├── customer_dashboard.dart       # Customer home
├── cleaner_dashboard.dart        # Cleaner home
├── Admin_dashboard.dart          # Admin home
├── booking_page.dart             # Book a service
├── booking_detail_page.dart      # Booking detail (customer)
├── booking_detail_admin_page.dart# Booking detail (admin)
├── booking_management_page.dart  # Admin booking management
├── payment_page.dart             # Payment screen
├── bank_transfer_page.dart       # Bank transfer flow
├── receipt_page.dart             # Payment receipt
├── notifications_page.dart       # Notifications
├── notification_service.dart     # FCM service
└── ...
```

---

## 📄 License

This project is developed for academic purposes.
