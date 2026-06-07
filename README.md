# Nosiva 💖

> Buy & sell pre-loved fashion with a community that gets your vibe.

Nosiva is a cross-platform (iOS + Android) second-hand fashion marketplace built
with **Flutter** and **Supabase** — think Vinted/Depop, but pinker and softer,
with main-character energy. ✨

---

## ✨ Features

| Area | What's built |
| --- | --- |
| **Auth** | Email/password + Google/Apple OAuth scaffolding, persisted session, onboarding (pick categories / sizes / styles) |
| **Listings** | Create with multiple photos (camera + gallery → Supabase Storage), category, brand, size, condition, color, style tags, price. Edit/delete own listings |
| **Browse & search** | Home feed, category browsing, full-text search, rich filters, infinite scroll + pagination |
| **Item detail** | Photo carousel, full info, seller card, favorite (heart), "Make an offer" & "Buy now" |
| **Favorites** | Save & view wishlist, optimistic likes |
| **Messaging** | Realtime 1:1 chat per item (Supabase Realtime), optimistic send |
| **Offers** | Buyer sends offer; seller accepts / declines / counters |
| **Cart & checkout** | Cart, shipping address, order summary, **stubbed Stripe integration point** |
| **Orders** | Buyer/seller history, status flow Pending → Shipped → Delivered |
| **Notifications** | In-app realtime list (messages, offers, sales, follows) |
| **Design system** | Live component showcase at `/design-system` |

---

## 🏗️ Architecture

- **State management:** Riverpod (`Notifier` / `AsyncNotifier`), used consistently.
- **Navigation:** `go_router` with an auth-aware redirect + a `StatefulShellRoute`
  bottom-nav shell.
- **Backend:** `supabase_flutter` — Postgres, Auth, Storage, Realtime.
- **Models:** `freezed` + `json_serializable` (run codegen — see below).
- **Images:** `image_picker` (camera/gallery) + `cached_network_image`.
- **Feature-first folders:**

```
lib/
├── main.dart                 # bootstrap: load env → init Supabase → runApp
├── app.dart                  # MaterialApp.router + theme wiring
├── core/
│   ├── config/               # env (flutter_dotenv)
│   ├── supabase/             # Supabase client + auth providers
│   ├── router/               # go_router config + route constants
│   ├── theme/                # colors, typography, spacing, theme, theme controller
│   ├── widgets/              # NosivaButton, chips, text fields, heart, shimmer, states
│   └── utils/                # validators, formatters, snackbars
├── shell/                    # bottom-nav shell
└── features/
    ├── auth/        {data, domain, presentation}
    ├── profile/     {data, domain, presentation}
    ├── listings/    {data, domain, presentation}
    ├── favorites/   {data, presentation}
    ├── messaging/   {data, domain, presentation}
    ├── offers/      {data, domain}
    ├── cart/        {presentation}
    ├── orders/      {data, domain, presentation}
    ├── notifications/{data, domain, presentation}
    └── design_system/{presentation}
```

Each feature follows `data` (repositories + Supabase queries) → `domain`
(freezed models + enums) → `presentation` (Riverpod controllers + screens/widgets).

---

## 🚀 Setup

### 1. Prerequisites
- Flutter 3.38+ / Dart 3.10+
- A free [Supabase](https://supabase.com) project

### 2. Install dependencies & generate code
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```
> `freezed` / `json_serializable` generate the `*.freezed.dart` and `*.g.dart`
> files. The app **will not compile until you run build_runner.**

### 3. Configure environment
```bash
cp .env.example .env
```
Fill in from **Supabase → Project Settings → API**:
```
SUPABASE_URL=https://YOUR-PROJECT-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-public-key
```

### 4. Run the database migrations
In the Supabase **SQL Editor**, run (in order):
1. `supabase/migrations/0001_init.sql` — schema, triggers, RLS, seed data
2. `supabase/migrations/0002_storage.sql` — `listing-images` & `avatars` buckets + policies

Or with the Supabase CLI:
```bash
supabase db push
```

### 5. Auth settings
- For local dev, **disable "Confirm email"** (Auth → Providers → Email) so sign-up
  returns a session immediately and the profile row can be created.
- To enable **Google/Apple**, turn them on under Auth → Providers and set the
  redirect URL in `auth_repository.dart` (`redirectTo`) + your platform deep link.

### 6. Run it
```bash
flutter run
```

---

## 💳 Stripe (stubbed)

Checkout creates `pending` orders without charging. The integration point is
clearly marked in `lib/features/cart/presentation/cart_screen.dart`. To go live:
1. Add `flutter_stripe` and your **publishable** key to `.env`.
2. Create a Supabase **Edge Function** that mints a `PaymentIntent` with your
   **secret** key (never ship the secret in the app).
3. Confirm the payment client-side, then create the order rows.

---

## 🎨 Brand guidelines

**Vibe:** feminine, playful, modern — Gen-Z "main character" energy.

**Palette**
| Token | Hex | Use |
| --- | --- | --- |
| Hot Pink | `#FF4D8D` | primary actions, accents |
| Soft Blush | `#FFD6E5` | secondary surfaces, avatars |
| Cream | `#FFF7FA` | light background |
| Deep Plum | `#3D1F2E` | text, dark surfaces |
| Lilac | `#C8A2E0` | accent, gradient pair |
| Mint `#7BD8B0` / Sun `#FFC857` | | success / ratings |

**Type:** Fraunces (display serif headers) + DM Sans (body) via `google_fonts`.

**Shape & feel:** rounded corners (16–24px), soft diffuse shadows, generous
whitespace, hearts & sparkle accents. Light theme by default with a polished
deep-plum dark mode (toggle in the home app bar).

**Microcopy:** friendly and a little playful — *"Your closet is empty bestie ✨"*,
*"Snatched! Added to favorites 💖"*, *"Time to make that coin 💸"*.

---

## 🖼️ App icon & splash (asset spec)

Generate and drop into `assets/images/` (then wire up `flutter_launcher_icons`
+ `flutter_native_splash`):

- **App icon:** 1024×1024. Pink→lilac diagonal gradient (`#FF4D8D → #C8A2E0`)
  rounded-square, centered white lowercase **"n"** in Fraunces, with a small
  sparkle (✨) top-right. Provide a flat-pink monochrome variant for adaptive
  Android foreground.
- **Splash:** full-bleed `splashGradient` (hot pink → light pink → lilac),
  centered white **"Nosiva"** wordmark (Fraunces, ~56pt) + tagline
  *"pre-loved, main character energy ✨"*. Matches `SplashScreen`.

---

## 🧪 Tests
```bash
flutter test
```

## 📌 Notable TODOs
- Edit-profile & follow/unfollow wiring
- Offer accept/decline/counter UI for sellers
- Image sharing inside chat
- Persisting cart & theme choice
- Real Stripe payment flow
