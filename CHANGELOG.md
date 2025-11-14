# Changelog

All notable changes to MotoRent Dumaguete mobile app will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Pull-to-refresh functionality on Transactions, Notifications, Home, Manage Bookings, and Admin Dashboard screens
- Bulk delete functionality for transactions with selection mode
- Tabbed UI (Active/History) for transactions screen
- Direct database notification insertion for real-time status updates
- Enhanced admin dashboard with reservation management
- Document upload with public URL storage in Supabase
- Real-time notification system using Supabase subscriptions

### Changed
- Updated reservation service to create notifications directly in database
- Improved transaction screen layout with better status indicators
- Enhanced booking flow with 4-step process UI

### Fixed
- Notification delivery when admin approves/rejects reservations
- Transaction screen layout issues and malformed build errors
- Syntax errors in manage_bookings_screen after pull-to-refresh implementation
- License image upload now stores public URLs correctly

### Security
- Added .env to .gitignore to protect secrets
- Documented need to move Supabase credentials to environment variables

## [1.0.0] - 2025-11-09

### Added
- Initial release
- User authentication with Supabase
- Motorcycle browsing and filtering
- 4-step booking process
- Document upload and verification
- Payment options (GCash and Cash)
- Admin dashboard and reservation management
- Real-time notifications
- Profile management
- Dark theme with neon accents

### Technical
- Flutter 3.0+ with Dart 3.0+
- Supabase backend integration
- Provider state management
- Image picker for document uploads
- Shared preferences for local storage
- Intl for date formatting

---

## Guidelines for Updates

When adding entries:
- Use ### Added, ### Changed, ### Deprecated, ### Removed, ### Fixed, ### Security sections
- Add date in YYYY-MM-DD format when releasing a version
- Link to relevant GitHub issues/PRs when applicable
- Keep most recent changes at the top
