import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moto_rent_dumaguete/screens/home/home_screen.dart';
import 'package:moto_rent_dumaguete/screens/booking/booking_list_screen.dart';
import 'package:moto_rent_dumaguete/screens/rental_history/rental_history_screen.dart';
import 'package:moto_rent_dumaguete/screens/profile/profile_screen.dart';
import 'package:moto_rent_dumaguete/screens/notifications/notifications_screen.dart';
import 'package:moto_rent_dumaguete/services/notification_service_supabase.dart';
import 'package:moto_rent_dumaguete/widgets/bottom_navigation.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const BookingListScreen();
      case 2:
        return const RentalHistoryScreen();
      case 3:
        return ProfileScreen(
            key: ValueKey(DateTime.now().millisecondsSinceEpoch));
      default:
        return const HomeScreen();
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0 || _currentIndex == 1 || _currentIndex == 2
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                _currentIndex == 0
                    ? 'MotoRent'
                    : _currentIndex == 1
                        ? 'Reservations'
                        : 'Rental History',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                Consumer<NotificationServiceSupabase>(
                  builder: (context, notificationService, child) {
                    final unreadCount = notificationService.unreadCount;

                    return Stack(
                      children: [
                        IconButton(
                          onPressed: () {
                            // Navigate to notifications screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.notifications_outlined),
                        ),
                        // Notification badge - only show if there are unread notifications
                        if (unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: _getCurrentScreen(),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
      ),
    );
  }
}
