import 'package:google_generative_ai/google_generative_ai.dart';

import '../constants.dart';
import 'firebase_query_service.dart';

class AiChatMessage {
  const AiChatMessage({required this.role, required this.content});

  final String role;
  final String content;

  bool get isUser => role == 'user';
}

class ChatAiService {
  ChatAiService({FirebaseQueryService? firebaseQueryService})
    : _firebaseQueryService = firebaseQueryService ?? FirebaseQueryService() {
    _model = _createModel();
    _chatSession = _model.startChat();
  }

  final FirebaseQueryService _firebaseQueryService;
  final List<AiChatMessage> _history = [];
  late final GenerativeModel _model;
  late ChatSession _chatSession;

  List<AiChatMessage> get history => List.unmodifiable(_history);

  void clearHistory() {
    _history.clear();
    _chatSession = _model.startChat();
  }

  Future<String> sendMessage(
    String userMessage, {
    String? firestoreContext,
  }) async {
    final question = userMessage.trim();
    if (question.isEmpty) {
      return 'Bạn vui lòng nhập câu hỏi cần hỗ trợ.';
    }

    if (AppConstants.geminiApiKey == 'YOUR_GEMINI_API_KEY' ||
        AppConstants.geminiApiKey.trim().isEmpty) {
      return 'Chưa cấu hình Gemini API key trong lib/constants.dart.';
    }

    _history.add(AiChatMessage(role: 'user', content: question));

    try {
      final firebaseData =
          firestoreContext ??
          await _firebaseQueryService.buildContextForQuestion(question);
      final now = DateTime.now();
      final todayText =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

      final messageToSend =
          '''
Ngày hiện tại theo ứng dụng: $todayText.
Khi người dùng nói "hôm nay", "ngày mai", "ngày kia", phải suy ra từ ngày hiện tại này.

Dữ liệu hệ thống:
$firebaseData

Câu hỏi:
$question
''';

      final response = await _chatSession.sendMessage(
        Content.text(messageToSend),
      );

      final reply = response.text?.trim() ?? '';
      if (reply.isEmpty) {
        throw StateError('Gemini API không trả về nội dung.');
      }

      _history.add(AiChatMessage(role: 'assistant', content: reply));
      return reply;
    } catch (e) {
      const errorMessage =
          'Xin lỗi, tôi chưa thể xử lý câu hỏi này. Vui lòng thử lại sau hoặc liên hệ nhân viên bệnh viện.';
      _history.add(AiChatMessage(role: 'assistant', content: errorMessage));
      return '$errorMessage\nChi tiết lỗi: $e';
    }
  }

  GenerativeModel _createModel() {
    return GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: AppConstants.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.2,
        maxOutputTokens: 700,
      ),
      systemInstruction: Content.system('''
Bạn là trợ lý AI của bệnh viện, hỗ trợ 2 việc chính:

1. Tra cứu thông tin từ hệ thống bệnh viện
   (lịch hẹn, bác sĩ, bệnh nhân, hoá đơn, bảo hiểm)
   dựa trên dữ liệu được cung cấp trong mỗi tin nhắn.

2. Tư vấn y tế cơ bản: giải thích triệu chứng,
   gợi ý khoa khám phù hợp, thông tin sức khoẻ phổ thông.
   KHÔNG chẩn đoán bệnh. KHÔNG kê đơn thuốc.

Quy tắc quan trọng:
- Luôn trả lời bằng tiếng Việt, lịch sự, ngắn gọn.
- Nếu dữ liệu hệ thống không có thông tin phù hợp, nói rõ là không tìm thấy, không được bịa.
- Không tiết lộ dữ liệu không liên quan đến câu hỏi.
- Với triệu chứng nguy hiểm như đau ngực dữ dội, khó thở, yếu liệt, mất ý thức, sốt cao kéo dài ở trẻ em: khuyên đi cấp cứu hoặc gặp bác sĩ ngay.
- Nếu câu hỏi vượt ngoài khả năng, khuyên bệnh nhân gặp trực tiếp nhân viên bệnh viện.
'''),
    );
  }
}
