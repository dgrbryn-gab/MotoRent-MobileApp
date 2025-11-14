# MotoRent Dumaguete - Flutter App

A premium motorcycle rental mobile application for Dumaguete, Philippines, built with Flutter and featuring a modern dark theme with neon accents.

## Features

### Customer Features
- **Browse Motorcycles**: View available motorcycles with detailed information
- **Advanced Search & Filtering**: Find motorcycles by name, brand, category
- **4-Step Booking Process**:
  1. Reserve Now
  2. Send Documents
  3. Wait for Owner's Approval
  4. Proceed to Payment
- **Document Upload**: Upload driver's license and required documents
- **Payment Options**: GCash and Cash payment methods
- **Reservation Management**: View and manage bookings
- **Real-time Status Updates**: Track booking progress
- **User Profile**: Manage personal information and preferences

### Admin Features
- **Dashboard**: Overview of key metrics and analytics
- **Fleet Management**: Add, edit, and manage motorcycle inventory
- **Reservation Management**: Approve/reject bookings and manage reservations
- **Payment Tracking**: Monitor payment status and history
- **GPS Tracking**: Real-time location tracking of rented motorcycles
- **Reports & Analytics**: Generate reports on rentals, revenue, and performance
- **Customer Management**: View and manage customer accounts

## Design System

### Color Palette
- **Background**: Dark blue gradient (#0D1B2A to #1B263B)
- **Primary**: Bright cyan (#00C6FF)
- **Secondary**: Bright orange (#FF7A00) - Used for action buttons and current steps
- **Success**: Green (#4CAF50)
- **Warning**: Gold (#FFC107)
- **Error**: Red (#D32F2F)
- **Card**: Dark blue (#1E2A3B)
- **Text Primary**: White (#FFFFFF)
- **Text Secondary**: Light gray (#B0BEC5)
- **Completed Steps**: Deep purple (#2E1A47)

### Progress Stepper
The app features a horizontal progress stepper for the booking flow:
- **Current Step**: Orange (#FF7A00)
- **Completed Steps**: Deep purple (#2E1A47)
- **Pending Steps**: Light gray (#B0B0B0)

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── theme/
│   └── app_theme.dart       # Theme configuration
├── models/
│   ├── motorcycle.dart      # Motorcycle model and data structure
│   ├── booking.dart         # Booking model with status enums
│   └── user.dart           # User model with role management
├── services/
│   ├── auth_service.dart    # Authentication and user management
│   ├── motorcycle_service.dart # Motorcycle data management
│   └── booking_service.dart # Booking operations and status management
├── data/
│   └── motorcycle_data.dart # Sample motorcycle data
├── screens/
│   ├── splash_screen.dart   # App splash screen
│   ├── get_started_screen.dart # Onboarding screen
│   ├── auth/
│   │   ├── auth_screen.dart     # Main auth container
│   │   ├── login_screen.dart    # Login form
│   │   ├── signup_screen.dart   # Registration form
│   │   └── forgot_password_screen.dart # Password reset
│   └── home/
│       └── home_screen.dart     # Main home screen with motorcycle grid
└── widgets/
    ├── custom_text_field.dart   # Reusable text input component
    ├── loading_button.dart      # Button with loading states
    ├── motorcycle_card.dart     # Motorcycle display card
    ├── search_bar.dart          # Search input component
    ├── filter_chips.dart        # Category filter chips
    └── bottom_navigation.dart   # Bottom navigation bar
```

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- iOS Simulator / Android Emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Authentication Setup

**Backend Integration Required:**
- This app requires backend API integration for authentication
- Update `lib/services/auth_service.dart` to connect to your authentication API
- Implement proper user registration, login, and session management
- Configure your database and user management system

## Architecture

The app follows a Provider-based state management pattern with clear separation of concerns:

- **Models**: Data structures and business logic
- **Services**: API calls, data management, and business operations
- **Screens**: UI components and user interactions
- **Widgets**: Reusable UI components
- **Theme**: Centralized styling and design tokens

## Key Dependencies

- **provider**: State management
- **http/dio**: Network requests
- **cached_network_image**: Optimized image loading
- **image_picker**: Camera and gallery access
- **shared_preferences**: Local data storage
- **google_maps_flutter**: Maps integration
- **location/geolocator**: GPS functionality
- **firebase_core/firebase_messaging**: Push notifications
- **intl**: Internationalization and date formatting

## Development Notes

### State Management
The app uses Provider for state management with three main services:
- `AuthService`: User authentication and profile management
- `MotorcycleService`: Motorcycle data and filtering
- `BookingService`: Reservation management and booking flow

### Booking Flow
The 4-step booking process is managed through the `BookingService`:
1. **Reserve Now**: Initial reservation creation
2. **Send Documents**: Document upload and verification
3. **Wait for Owner's Approval**: Admin approval process
4. **Proceed to Payment**: Payment processing and confirmation

### Theme System
The app uses a comprehensive theme system with:
- Consistent color palette
- Typography scales
- Component styles
- Dark theme optimizations

## Future Enhancements

- [ ] Real-time chat support
- [ ] In-app payments integration
- [ ] Offline mode support
- [ ] Multi-language support
- [ ] Advanced analytics dashboard
- [ ] Push notification system
- [ ] Social media integration
- [ ] Loyalty program features

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is proprietary software for MotoRent Dumaguete.