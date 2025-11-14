// This file re-exports MotorcycleServiceSupabase as MotorcycleService
// to maintain compatibility with existing screens while using Supabase backend

import 'package:moto_rent_dumaguete/services/motorcycle_service_supabase.dart';

// Type alias for backward compatibility
typedef MotorcycleService = MotorcycleServiceSupabase;
