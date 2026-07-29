# ShopFinder - Features Documentation

ShopFinder is a global, cloud-powered directory designed to connect local physical shop owners with customers through a seamless, "Guest First" experience.

---

## 👥 User Roles

### 1. End Users (Customers)
*   **Guest Access**: Browse, search, and view shop profiles without registration.
*   **Global Search**: Find shops by name, category, or specific products.
*   **Location-Based Discovery**: Filter shops by city, zipcode, country, or proximity.
*   **Direct Interaction**: One-tap buttons to **Call** or **WhatsApp** shop owners.
*   **Trust System**: View star ratings and read community reviews.
*   **Exclusive Promos**: Discover and claim limited-time promo codes (e.g., "First 100 users").
*   **Multi-Language**: Toggle UI between **English, Hindi, Spanish, Chinese, German, Italian, Urdu, Arabic, French, Bengali, Portuguese, Russian, and Japanese**.

### 2. Business Owners
*   **Secure Registration**: Create and manage a professional shop profile.
*   **Inventory Management**: Showcase products with images, descriptions, and pricing.
*   **Promo Engine**: Create "First N People" promo codes to drive rapid customer engagement.
*   **Feedback Loop**: View and respond to user reviews to build customer relationships.
*   **Verification Badge**: Get a "Verified" tick after admin approval to build trust.

### 3. Administrators (Super-User)
*   **Global Dashboard**: View real-time stats (Total Users, Shops, Active Promos).
*   **Moderation Tools**: Delete inappropriate reviews or fraudulent shop listings.
*   **Business Verification**: Review and verify shop registrations globally.
*   **System Health**: Monitor app growth and promo code usage trends.

---

## 🚀 Technical Highlights

### Core Architecture
*   **Flutter (Cross-Platform)**: Single codebase for Android, iOS, and Web.
*   **BLoC + Provider**: Industry-standard state management for scalability and performance.
*   **Clean Architecture**: Modular folder structure (`common/`, `app/`, `admin/`) for easy maintenance.

### Backend (Firebase)
*   **Cloud Firestore**: Real-time global database with role-based security rules.
*   **Firebase Auth**: Secure login for owners/admins and anonymous access for guests.
*   **Cloud Storage**: High-speed hosting for images with secure access controls.
*   **Push Notifications (FCM)**: Real-time alerts for new offers and verification updates.

### Monetization & Scalability
*   **AdMob Integration**: Google Mobile Ads (v9.0.0) integrated with Banner, Interstitial (Guest-only), and Native ads.

---

## 📈 Roadmap (Post-Launch Phase)

The following features are scheduled for implementation **after the first launch**:

- [ ] **Interactive Maps**: View shops on a real-time GPS map.
- [ ] **QR Code Redemption**: Scan codes at physical stores to redeem promos.
- [ ] **AI-Powered Recommendations**: Suggest shops based on user behavior.
- [ ] **In-App Messaging**: Chat directly with owners without leaving the app.
