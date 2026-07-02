class Env {
  static const String supabaseUrl = 'https://nolawradcdkemdyumoqs.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vbGF3cmFkY2RrZW1keXVtb3FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU5MjAzNjIsImV4cCI6MjA5MTQ5NjM2Mn0.uwTp2g6yPJv6JUvyv4NBr1m0DgVt5fmKPiR3ED4hs4I';

  // ================================================================
  // Endpoint server prediksi Smart Analitik (LSTM/baseline statistik).
  // Bisa dioverride saat build/run tanpa mengubah kode:
  //   flutter run --dart-define=LSTM_HF_URL=https://xxx.hf.space
  //   flutter run --dart-define=LSTM_LOCAL_PHYSICAL_URL=http://192.168.1.50:5000
  // Atau simpan di file (lihat env.example.json) dan pakai:
  //   flutter run --dart-define-from-file=env.json
  // Tanpa argumen apa pun, nilai default di bawah ini yang dipakai.
  // ================================================================
  static const String lstmHfUrl = String.fromEnvironment(
    'LSTM_HF_URL',
    defaultValue: 'https://itsprzvl-ModelLSTM.hf.space',
  );

  static const String lstmLocalPhysicalUrl = String.fromEnvironment(
    'LSTM_LOCAL_PHYSICAL_URL',
    defaultValue: 'http://10.140.135.148:5000',
  );
}
