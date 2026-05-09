import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient('url', 'key');
  final int count = await supabase
      .from('agencies')
      .count(CountOption.exact)
      .eq('status', 'pending');
  print(count);
}
