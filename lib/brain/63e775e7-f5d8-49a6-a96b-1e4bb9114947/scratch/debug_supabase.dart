import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mauritanie_news/shared/models/agency_model.dart';

Future<void> debugSupabase() async {
  final supabase = Supabase.instance.client;

  print('--- DEBUG SUPABASE ---');

  try {
    // 1. Check agencies table
    final agenciesRaw = await supabase.from('agencies').select().limit(5);
    print('Raw agencies count (limit 5): ${agenciesRaw.length}');
    if (agenciesRaw.isNotEmpty) {
      print('First agency keys: ${agenciesRaw.first.keys.toList()}');
      print('First agency status: ${agenciesRaw.first['status']}');
    } else {
      print(
          'WARNING: agencies table seems EMPTY or RLS blocked for current user.');
    }

    // 2. Check pending specifically
    final pendingCount =
        await supabase.from('agencies').select('id').eq('status', 'pending');
    print('Count with status="pending": ${pendingCount.length}');

    final pendingCountUpper =
        await supabase.from('agencies').select('id').eq('status', 'PENDING');
    print('Count with status="PENDING": ${pendingCountUpper.length}');

    // 3. Check reports table
    final reportsRaw = await supabase.from('reports').select().limit(5);
    print('Raw reports count: ${reportsRaw.length}');
  } catch (e) {
    print('ERROR DURING DEBUG: $e');
  }
  print('--- END DEBUG ---');
}
