import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationTemplateSeeder {
  static Future<void> seedNotificationTemplates() async {
    final collection = FirebaseFirestore.instance.collection('notification_templates');
    final batch = FirebaseFirestore.instance.batch();

    for (final template in _templates) {
      batch.set(collection.doc(template.id), template.toFirestore(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  static final List<NotificationTemplateModel> _templates = [
    const NotificationTemplateModel(
      id: 'prep_default',
      departmentId: 'default',
      departmentName: 'Mặc định',
      templateType: 'preparation',
      title: 'Hướng dẫn chuẩn bị trước khám',
      message: 'Để quá trình khám diễn ra thuận lợi, vui lòng chuẩn bị:',
      instructions: [
        'Mang CCCD/CMND, thẻ bảo hiểm y tế nếu có.',
        'Đến sớm 15 phút để làm thủ tục.',
        'Mang theo kết quả xét nghiệm, đơn thuốc hoặc hồ sơ cũ nếu có.',
      ],
    ),
    const NotificationTemplateModel(
      id: 'prep_blood_test',
      departmentId: 'laboratory',
      departmentName: 'Xét nghiệm',
      templateType: 'preparation',
      title: 'Chuẩn bị xét nghiệm máu',
      message: 'Để kết quả xét nghiệm chính xác, vui lòng:',
      instructions: [
        'Nhịn ăn 8-10 giờ trước khi lấy máu nếu xét nghiệm đường huyết, mỡ máu.',
        'Có thể uống nước lọc, không uống cà phê, trà, rượu bia.',
        'Tránh vận động mạnh trong 24 giờ trước xét nghiệm.',
      ],
    ),
    const NotificationTemplateModel(
      id: 'prep_ultrasound',
      departmentId: 'ultrasound',
      departmentName: 'Siêu âm',
      templateType: 'preparation',
      title: 'Chuẩn bị trước siêu âm',
      message: 'Vui lòng lưu ý trước khi siêu âm:',
      instructions: [
        'Siêu âm bụng: nên nhịn ăn khoảng 6 giờ trước khi khám.',
        'Siêu âm tiết niệu/phụ khoa: uống nước và nhịn tiểu theo hướng dẫn.',
        'Mặc trang phục thoải mái, dễ thao tác.',
      ],
    ),
    const NotificationTemplateModel(
      id: 'prep_xray',
      departmentId: 'xray',
      departmentName: 'X-Quang',
      templateType: 'preparation',
      title: 'Chuẩn bị trước chụp X-Quang',
      message: 'Trước khi chụp X-Quang, vui lòng:',
      instructions: [
        'Thông báo cho nhân viên y tế nếu đang mang thai hoặc nghi ngờ mang thai.',
        'Tháo trang sức, vật dụng kim loại tại vùng cần chụp.',
        'Làm theo hướng dẫn giữ tư thế để ảnh chụp rõ nhất.',
      ],
    ),
    const NotificationTemplateModel(
      id: 'prep_cardiology',
      departmentId: 'cardiology',
      departmentName: 'Tim mạch',
      templateType: 'preparation',
      title: 'Chuẩn bị trước khám tim mạch',
      message: 'Để kết quả đo và khám tim mạch chính xác, vui lòng:',
      instructions: [
        'Tránh cà phê, trà đặc và vận động mạnh trước khi khám.',
        'Ngồi nghỉ 5-10 phút trước khi đo huyết áp.',
        'Mang danh sách thuốc đang sử dụng và kết quả khám cũ nếu có.',
      ],
    ),
  ];
}
