# Database & Security Documentation

ShopFinder uses **Firebase Cloud Firestore** as its primary real-time database. The data is structured to support global scalability and secure role-based access.

## 🗄 Firestore Schema

### `users` (Collection)
Stores user profiles and roles.
*   `uid`: String (Document ID)
*   `email`: String
*   `displayName`: String
*   `role`: String (`'user'`, `'owner'`, `'admin'`)
*   `createdAt`: Timestamp

### `businesses` (Collection)
Stores business listings.
*   `id`: String (Document ID)
*   `ownerId`: String (Reference to users)
*   `name`: String
*   `category`: String
*   `location`: Map (`lat`, `lng`, `address`, `city`, `zipcode`)
*   `isVerified`: Boolean
*   `rating`: Number
*   `products`: Array of Maps

### `promos` (Collection)
Stores active "First N" promotional offers.
*   `id`: String (Document ID)
*   `businessId`: String
*   `title`: String
*   `code`: String
*   `limit`: Number (Total claims allowed)
*   `claimCount`: Number (Current claims)
*   `expiryDate`: Timestamp

### `reviews` (Collection)
User-generated feedback.
*   `id`: String (Document ID)
*   `businessId`: String
*   `userId`: String
*   `rating`: Number
*   `comment`: String
*   `reply`: String (Owner response)

## 🔐 Security Rules (Conceptual)

| Collection | Read Access | Write Access |
| :--- | :--- | :--- |
| `users` | Authenticated (Self) | Authenticated (Self) |
| `businesses` | Public (Guest) | Owner (Specific) / Admin |
| `promos` | Public (Guest) | Owner (Specific) / Admin |
| `reviews` | Public (Guest) | Authenticated User / Owner (Reply) |

## 📁 Storage Structure
Firebase Storage is used for hosting high-resolution images:
*   `/business_images/{businessId}/main.jpg`
*   `/product_images/{businessId}/{productId}.jpg`
*   `/user_profiles/{uid}.jpg`
