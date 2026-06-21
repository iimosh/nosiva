# Nosiva

Nosiva is a cross-platform mobile application for buying and selling pre-owned fashion items. The project is built with Flutter and Supabase, with support for authentication, marketplace listings, favorites, cart and orders, real-time messaging, notifications, and administrator moderation.
The application is designed as a second-hand fashion marketplace where users can create profiles, list clothing or accessories for sale, browse available products, save favorites, contact sellers, make offers, and manage purchases.

## Project Purpose

The purpose of Nosiva is to provide a complete mobile marketplace experience for sustainable fashion shopping. Instead of focusing only on static product browsing, the project includes account management, listing creation, image uploads, search and filtering, user-to-user communication, order tracking, and basic administration tools.

This project demonstrates:

- Mobile application development with Flutter
- Feature-based project architecture
- Authentication and session handling
- Supabase database integration
- Supabase Storage for uploaded images
- Real-time data updates for chat and notifications
- Role-based access control for normal users and administrators
- Clean UI components and reusable design system elements

## Main Features

### Authentication and Onboarding

Users can create an account, sign in, and keep their session active across app launches. After registration, users complete onboarding by selecting personal preferences such as categories, sizes, and styles. The application also includes OAuth button scaffolding for Google and Apple sign-in.

### User Profiles

Each user has a profile connected to their authenticated account. Profiles include information such as username, display name, avatar, biography, location, style tags, rating data, follower counts, and onboarding status.

### Listings

Users can create marketplace listings for fashion items. A listing can contain:

- Title and description
- Category
- Brand
- Size
- Condition
- Color
- Price
- Style tags
- Location
- Multiple uploaded images

Listings are stored in Supabase Postgres, while listing images are uploaded to Supabase Storage. Sellers can manage their own listings, and administrators can moderate listings through additional access policies.

### Browse, Search, and Filtering

The home and search screens allow users to browse active listings. The database includes full-text search support over listing title, description, and brand. Listings can also be organized and filtered using categories, price, status, and style tags.

### Listing Details

The listing detail page displays the selected item with its images, product information, price, seller details, favorite control, and buyer actions such as messaging the seller, making an offer, or buying the item.

### Favorites

Users can save listings to a personal favorites list. Favorite data is stored per user, and the listing favorite count is maintained automatically through database triggers.

### Messaging

Nosiva supports one-to-one conversations between buyers and sellers. Conversations are related to listings, and messages are delivered using Supabase Realtime. This allows users to communicate directly before completing a purchase.

### Offers

Buyers can send offers to sellers for specific listings. Offers include the listing, buyer, seller, amount, status, and optional message. The database supports offer states such as pending, accepted, declined, countered, and expired.

### Notifications

The notifications feature stores and displays user-specific notifications such as messages, offers, sales, follows, reviews, and system events. Notifications are protected so users can only view and update their own records.

### Admin Dashboard

The project includes an administrator role system. Administrators can manage user roles and moderate listings. Supabase Row Level Security policies and helper functions prevent normal users from promoting themselves or accessing admin-only actions.

### Design System

Reusable UI elements are located in the core widgets and theme folders. The application includes shared buttons, chips, text fields, heart buttons, loading states, shimmer placeholders, colors, typography, spacing, and light/dark themes.

## Technology Stack

| Area | Technology |
| --- | --- |
| Framework | Flutter |
| Language | Dart |
| State management | Riverpod |
| Routing | go_router |
| Backend | Supabase |
| Database | Supabase Postgres |
| Authentication | Supabase Auth |
| File storage | Supabase Storage |
| Realtime features | Supabase Realtime |
| Models and serialization | Freezed, json_serializable |
| Environment variables | flutter_dotenv |
| Image handling | image_picker, cached_network_image |
| Styling | Custom Flutter theme, Google Fonts |
| Testing | flutter_test |

## Architecture

Nosiva uses a feature-first architecture. Shared application services are placed in the `core` directory, while each main product area is separated into its own feature folder.

```text
lib/
|-- main.dart
|-- app.dart
|-- core/
|   |-- config/
|   |-- router/
|   |-- supabase/
|   |-- theme/
|   |-- utils/
|   `-- widgets/
|-- shell/
`-- features/
    |-- admin/
    |-- auth/
    |-- cart/
    |-- design_system/
    |-- favorites/
    |-- listings/
    |-- messaging/
    |-- notifications/
    |-- offers/
    |-- orders/
    `-- profile/
```

Most feature folders follow this structure:

```text
feature_name/
|-- data/
|-- domain/
`-- presentation/
```

- `data` contains repositories and Supabase queries.
- `domain` contains models, enums, and business data structures.
- `presentation` contains screens, widgets, and Riverpod controllers.

This structure keeps the code organized and makes each feature easier to maintain independently.

## Application Flow

The application starts in `main.dart`, where Flutter bindings are initialized, environment variables are loaded, Supabase is initialized, and the root application widget is started.

`app.dart` creates the `MaterialApp.router`, connects the application theme, and uses the router configuration from the core router module.

Routing is handled by `go_router`. The router includes authentication-aware redirects:

- Unauthenticated users are redirected to the welcome and sign-in/sign-up screens.
- Authenticated users without a completed profile are redirected to onboarding.
- Onboarded users are redirected to the main home screen.
- Admin routes are protected so only users with an admin role can access them.

The main application shell uses bottom navigation for the primary sections:

- Home
- Search
- Sell
- Inbox
- Profile

Additional screens such as listing details, favorites, cart, orders, notifications, chat, design system, and admin dashboard are opened through named application routes.

## Backend and Database

The backend is implemented with Supabase. Database migrations are stored in the `supabase/migrations` directory.

The main database tables include:

| Table | Purpose |
| --- | --- |
| `profiles` | User profile information linked to Supabase Auth users |
| `categories` | Reference table for listing categories |
| `style_tags` | Reference table for style labels |
| `listings` | Marketplace items created by sellers |
| `listing_images` | Images connected to listings |
| `favorites` | User wishlist records |
| `follows` | User follow relationships |
| `conversations` | Buyer-seller conversations |
| `messages` | Chat messages |
| `offers` | Buyer offers for listings |
| `orders` | Purchase records |
| `reviews` | Ratings and reviews between users |
| `notifications` | User notifications |

The database also includes triggers for:

- Updating `updated_at` timestamps
- Maintaining listing favorite counts
- Maintaining follower and following counts
- Updating review rating averages

Row Level Security is enabled on the project tables. Policies are used to make sure that users can only modify their own records, while public data such as active listings and reference tables can be read where appropriate. Admin users receive additional permissions through a secure role helper function.

## Conclusion

Nosiva is a full-featured Flutter marketplace application focused on second-hand fashion. It combines a structured mobile frontend with a Supabase backend, secure database policies, storage support, real-time communication, and role-based administration. The project demonstrates practical use of modern mobile development tools and backend-as-a-service architecture in one complete application.
