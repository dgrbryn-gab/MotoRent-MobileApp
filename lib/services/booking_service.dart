// This file re-exports ReservationServiceSupabase as BookingService
// to maintain compatibility with existing screens while using Supabase backend

import 'package:moto_rent_dumaguete/services/reservation_service_supabase.dart';

// Type alias for backward compatibility
typedef BookingService = ReservationServiceSupabase;
