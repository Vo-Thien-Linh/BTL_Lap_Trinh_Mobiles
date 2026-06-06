class AppConstants {
  AppConstants._();

  // Lấy API key Gemini tại https://aistudio.google.com/app/apikey.
  // Không commit API key thật lên GitHub.
  static const String geminiApiKey = '';
  static const String geminiModel = 'gemini-2.5-flash';

  // Backend public API used by the patient app to request payOS checkout links.
  // Configure at runtime:
  // flutter run --dart-define=PAYMENT_API_BASE_URL=https://your-ngrok.ngrok-free.dev
  static const String paymentApiBaseUrl = String.fromEnvironment(
    'PAYMENT_API_BASE_URL',
    defaultValue: '',
  );
}
