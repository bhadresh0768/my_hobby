# BizNearby

**BizNearby** is a global, cloud-powered directory for physical shops built with Flutter. It connects customers with local businesses through a "Guest First" experience, featuring real-time promos, location-based discovery, and a robust admin verification system.

## 📱 Key Features (Launch Scope)

### For Customers
*   **Guest Access**: Browse and search without registration.
*   **Global Search**: Find businesses by name, category, or products.
*   **Trust System**: Star ratings and community reviews.
*   **Direct Interaction**: One-tap Call or WhatsApp buttons.
*   **Exclusive Promos**: Claim limited-time "First N" promo codes.
*   **Multi-Language**: Support for 13+ languages including English, Hindi, Spanish, Chinese, and Arabic.

### For Business Owners
*   **Profile Management**: Create professional listings with images and inventory.
*   **Promo Engine**: Create engagement-driving promo codes.
*   **Verification**: Earn a "Verified" badge via admin approval.

### For Administrators
*   **Global Dashboard**: Real-time stats on users and business growth.
*   **Moderation**: Tools to manage reviews and business listings.

## 🛠 Tech Stack

*   **Frontend**: Flutter (Mobile & Web)
*   **State Management**: BLoC (Business Logic Component) + Provider
*   **Backend**: Firebase (Firestore, Auth, Storage, Cloud Messaging)
*   **Ads**: Google Mobile Ads (AdMob)
*   **Localization**: Flutter Intl (arb files)

## 📁 Project Structure

```text
lib/
├── app/            # Feature-specific screens and UI logic
│   ├── bloc/       # BLoC implementation for state management
│   ├── screens/    # UI Screens (Auth, Business, Home, etc.)
│   └── widgets/    # Feature-specific widgets (Ad widgets, etc.)
├── common/         # Shared resources
│   ├── models/     # Data models (User, Business, Promo, etc.)
│   ├── theme/      # App styling and themes
│   └── widgets/    # Reusable UI components
├── core/           # Underlying infrastructure
│   ├── repositories/# Data access layers (Firestore interaction)
│   └── utils/      # Helpers (Ads, Location, Validators)
└── l10n/           # Localization files (.arb)
```

## 🚀 Getting Started

1.  **Clone the repository**: `git clone [repository-url]`
2.  **Install dependencies**: `flutter pub get`
3.  **Setup Firebase**: Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
4.  **Run the app**: `flutter run`

---

## 📈 Future Roadmap (Post-Launch)
*   Interactive GPS Maps
*   QR Code Redemption
*   AI-Powered Recommendations
*   In-App Messaging
