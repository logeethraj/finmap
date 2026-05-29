# Finmap 💰

A personal finance tracker app built with Flutter & Supabase.

## Features

- 🔐 Email authentication with Supabase
- 📊 Net worth dashboard with assets & liabilities
- 💼 Asset management (Equity, Gold, Real Estate, Crypto, PPF, etc.)
- 💸 Income & expense tracking with savings rate
- 🎯 Financial goals with progress bars
- ⚙️ Settings with currency preferences

## Tech Stack

- **Frontend:** Flutter 3.x (Dart)
- **Backend:** Supabase (PostgreSQL + Auth)
- **State:** Flutter setState + Supabase Realtime
- **Packages:** supabase_flutter, fl_chart, shared_preferences, go_router

## Screens

| Screen | Description |
|--------|-------------|
| Login | Email/password authentication |
| Dashboard | Net worth overview with summary cards |
| Assets | Add/delete investment assets |
| Transactions | Log income and expenses |
| Goals | Set and track financial goals |
| Settings | Currency and theme preferences |

## Setup

1. Clone the repo
2. Run `flutter pub get`
3. Add your Supabase URL and anon key in `lib/main.dart`
4. Run `flutter run`

## Screenshots

Coming soon

---

Built as part of an internship project — Finmap helps users track their net worth, manage assets, and achieve financial goals.