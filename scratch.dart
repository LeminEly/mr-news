import 'package:supabase/supabase.dart';

void main() async {
  const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNiZnVsZG1zd2x1end4ZmRpcHd5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NjQxOTQ4MCwiZXhwIjoyMDkxOTk1NDgwfQ.BgyB813SUM9wx7GzZUnN7iTb5DEprZVfdxzhyzD1tVo';
  const url = 'https://cbfuldmswluzwxfdipwy.supabase.co';
  
  final client = SupabaseClient(url, serviceRoleKey);
  
  try {
    final res = await client.from('reports').select('*, articles(title)');
    print('Reports: $res');
  } catch (e) {
    print('Error reports: $e');
  }
}