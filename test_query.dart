import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print('Initializing Supabase...');
  try {
    await Supabase.initialize(
      url: 'https://nolawradcdkemdyumoqs.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vbGF3cmFkY2RrZW1keXVtb3FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU5MjAzNjIsImV4cCI6MjA5MTQ5NjM2Mn0.uwTp2g6yPJv6JUvyv4NBr1m0DgVt5fmKPiR3ED4hs4I',
    );
    final supabase = Supabase.instance.client;
    final storeId = 'c249606a-cbbb-4e40-9015-4754003c4a0f';
    final userId = '94435373-4779-4b9b-9d75-5ce1b48ab0ed';

    print('Testing query with .or()...');
    final response = await supabase
        .from('notifications')
        .select()
        .eq('store_id', storeId)
        .or('user_id.is.null,user_id.eq.$userId')
        .order('created_at', ascending: false)
        .limit(10);
    
    print('Query succeeded! Fetched ${response.length} items.');
    for (var row in response) {
      print(' - ID: ${row['id']}, user_id: ${row['user_id']}, type: ${row['type']}, title: ${row['title']}');
    }
  } catch (e, s) {
    print('Query failed with error: $e');
    print(s);
  }
}
