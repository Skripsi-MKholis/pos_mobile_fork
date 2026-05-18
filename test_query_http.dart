import 'dart:convert';
import 'dart:io';

void main() async {
  final url = Uri.parse(
    'https://nolawradcdkemdyumoqs.supabase.co/rest/v1/notifications?store_id=eq.c249606a-cbbb-4e40-9015-4754003c4a0f&or=(user_id.is.null,user_id.eq.94435373-4779-4b9b-9d75-5ce1b48ab0ed)',
  );
  
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vbGF3cmFkY2RrZW1keXVtb3FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU5MjAzNjIsImV4cCI6MjA5MTQ5NjM2Mn0.uwTp2g6yPJv6JUvyv4NBr1m0DgVt5fmKPiR3ED4hs4I';

  print('Sending request to Supabase PostgREST endpoint directly...');
  print('URL: $url');
  
  final client = HttpClient();
  try {
    final request = await client.getUrl(url);
    request.headers.add('apikey', anonKey);
    request.headers.add('Authorization', 'Bearer $anonKey');
    request.headers.add('Prefer', 'return=representation');

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    
    print('HTTP Status Code: ${response.statusCode}');
    print('Response Headers:');
    response.headers.forEach((name, values) {
      print(' - $name: $values');
    });
    
    print('\nResponse Body:');
    print(body);
  } catch (e, s) {
    print('Error: $e');
    print(s);
  } finally {
    client.close();
  }
}
