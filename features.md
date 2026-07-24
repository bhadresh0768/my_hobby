# Business Diary - Features Documentation

Business Diary is a global, cloud-powered business directory designed to connect local business owners with customers through a seamless, "Guest First" experience.

---

## 👥 User Roles

### 1. End Users (Customers)
*   **Guest Access**: Browse, search, and view business profiles without registration.
*   **Global Search**: Find businesses by name, category, or specific products.
*   **Location-Based Discovery**: Filter businesses by city, zipcode, country, or proximity.
*   **Direct Interaction**: One-tap buttons to **Call** or **WhatsApp** business owners.
*   **Trust System**: View star ratings and read community reviews.
*   **Exclusive Promos**: Discover and claim limited-time promo codes (e.g., "First 100 users").
*   **Multi-Language**: Toggle UI between **English, Hindi, Spanish, Chinese, German, Italian, Urdu, and Arabic** (expandable to more).

### 2. Business Owners
*   **Secure Registration**: Create and manage a professional business profile.
*   **Inventory Management**: Showcase products with images, descriptions, and pricing.
*   **Promo Engine**: Create "First N People" promo codes to drive rapid customer engagement.
*   **Feedback Loop**: View and respond to user reviews to build customer relationships.
*   **Verification Badge**: Get a "Verified" tick after admin approval to build trust.

### 3. Administrators (Super-User)
*   **Global Dashboard**: View real-time stats (Total Users, Businesses, Active Promos).
*   **Moderation Tools**: Delete inappropriate reviews or fraudulent business listings.
*   **Business Verification**: Review and verify business registrations globally.
*   **System Health**: Monitor app growth and promo code usage trends.

---

## 🚀 Technical Highlights

### Core Architecture
*   **Flutter (Cross-Platform)**: Single codebase for Android, iOS, and Web.
*   **BLoC + Provider**: Industry-standard state management for scalability and performance.
*   **Clean Architecture**: Modular folder structure (`common/`, `app/`, `admin/`) for easy maintenance.

### Backend (Firebase)
*   **Cloud Firestore**: Real-time global database with ACID transactions for promo counting.
*   **Firebase Auth**: Secure login for owners/admins and anonymous access for guests.
*   **Cloud Storage**: High-speed hosting for business logos and product photos.
*   **Push Notifications (FCM)**: Real-time alerts for new offers and verification updates.

### User Interface
*   **Material 3 Design**: Utilizing the latest UI principles from Google.
*   **"Modern Trust" Palette**: Deep Indigo (#3F51B5) and Mint Green (#00C853).
*   **Responsive Web**: Admin panel optimized for desktop browsers.

---

## 📈 Roadmap (Future Enhancements)
- [ ] **Interactive Maps**: View businesses on a real-time GPS map.
- [ ] **QR Code Redemption**: Scan codes at physical stores to redeem promos.
- [ ] **AI-Powered Recommendations**: Suggest businesses based on user behavior.
- [ ] **In-App Messaging**: Chat directly with owners without leaving the app.
