class AppConstants {
  AppConstants._();

  // Lấy API key Gemini tại https://aistudio.google.com/app/apikey
  // Trước khi push GitHub, hãy đổi lại thành 'YOUR_GEMINI_API_KEY'.
  static const String geminiApiKey = '';
  static const String geminiModel = 'gemini-2.5-flash';

  // Backend public API used by the patient app to request payOS checkout links.
  // Android emulator can reach the host machine through 10.0.2.2.
  // Override when needed:
  // flutter run --dart-define=PAYMENT_API_BASE_URL=https://your-api.example.com
  static const String paymentApiBaseUrl = String.fromEnvironment(
    'PAYMENT_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5071',
  );
}
