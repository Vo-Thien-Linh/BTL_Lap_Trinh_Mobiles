import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

import '../constants.dart';

// ─────────────────────────────────────────────
// Intent model — Gemini trả về JSON này
// ─────────────────────────────────────────────
class _QueryIntent {
  const _QueryIntent({
    required this.needsFirebase,
    required this.queryType,
    required this.entityName,
  });

  /// Có cần tra Firebase không
  final bool needsFirebase;

  /// Loại query: appointments_today | doctor_availability |
  ///             patient_appointments | department_doctors |
  ///             doctor_list | invoice | insurance | general | none
  final String queryType;

  /// Tên bác sĩ / bệnh nhân / khoa được đề cập (nếu có)
  final String entityName;

  factory _QueryIntent.fromJson(Map<String, dynamic> json) {
    return _QueryIntent(
      needsFirebase: json['needsFirebase'] as bool? ?? false,
      queryType: json['queryType'] as String? ?? 'none',
      entityName: json['entityName'] as String? ?? '',
    );
  }

  factory _QueryIntent.noFirebase() => const _QueryIntent(
    needsFirebase: false,
    queryType: 'none',
    entityName: '',
  );
}

// ─────────────────────────────────────────────
// Main service
// ─────────────────────────────────────────────
class FirebaseQueryService {
  FirebaseQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );

  // Model nhỏ, temperature=0 để parse JSON chính xác
  late final GenerativeModel _intentModel = GenerativeModel(
    model: AppConstants.geminiModel,
    apiKey: AppConstants.geminiApiKey,
    generationConfig: GenerationConfig(temperature: 0, maxOutputTokens: 200),
  );

  // ── Phân tích intent bằng Gemini ────────────────────────────────────────
  Future<_QueryIntent> _detectIntent(String question) async {
    try {
      final prompt =
          '''
Phân tích câu hỏi bên dưới và trả về JSON (không markdown, không giải thích).

Các queryType hợp lệ:
- "appointments_today"   : hỏi lịch hẹn hôm nay, số ca khám, tổng lịch...
- "doctor_availability"  : hỏi lịch trống / còn chỗ của bác sĩ cụ thể
- "doctor_schedule_date" : hỏi bác sĩ nào có lịch trực/lịch làm việc vào một ngày cụ thể, ví dụ hôm nay, ngày mai
- "patient_appointments" : hỏi lịch hẹn của bệnh nhân cụ thể
- "department_doctors"   : hỏi bác sĩ trực / có mặt tại khoa cụ thể hôm nay
- "doctor_list"          : hỏi danh sách bác sĩ, số lượng bác sĩ chung chung
- "invoice"              : hỏi hoá đơn, thanh toán của bệnh nhân
- "insurance"            : hỏi bảo hiểm y tế của bệnh nhân
- "general"              : hỏi chung về bệnh viện, hệ thống mà không rõ loại
- "none"                 : câu hỏi y tế / sức khoẻ, không cần tra Firebase

Trả về JSON:
{
  "needsFirebase": true/false,
  "queryType": "<một trong các giá trị trên>",
  "entityName": "<tên bác sĩ / bệnh nhân / khoa nếu có, để trống nếu không>"
}

Câu hỏi: "$question"
''';

      final response = await _intentModel.generateContent([
        Content.text(prompt),
      ]);
      final raw = response.text?.trim() ?? '{}';
      // Bỏ ```json ``` nếu model vẫn trả về
      final clean = raw.replaceAll(RegExp(r'```json|```'), '').trim();
      final json = jsonDecode(clean) as Map<String, dynamic>;
      return _QueryIntent.fromJson(json);
    } catch (_) {
      // Fallback: nếu parse lỗi thì dùng keyword đơn giản
      return _fallbackIntent(question);
    }
  }

  // Fallback keyword cơ bản khi Gemini intent lỗi
  _QueryIntent _fallbackIntent(String question) {
    final q = _normalize(question);
    if (q.contains('lich hen') ||
        q.contains('lich kham') ||
        q.contains('lich hen hom nay')) {
      return const _QueryIntent(
        needsFirebase: true,
        queryType: 'appointments_today',
        entityName: '',
      );
    }
    final hasExplicitDate = RegExp(
      r'(?:ngay\s*)?\d{1,2}\s*[\/\-]\s*\d{1,2}(?:\s*[\/\-]\s*\d{2,4})?',
    ).hasMatch(q);
    final hasWeekday = _weekdayFromQuestion(q) != null;
    if ((q.contains('ngay mai') ||
            q.contains('hom nay') ||
            q.contains('ngay kia') ||
            hasExplicitDate ||
            hasWeekday ||
            q.contains(' lam ') ||
            q.contains('truc')) &&
        (q.contains('bac si') || q.contains('bs '))) {
      return const _QueryIntent(
        needsFirebase: true,
        queryType: 'doctor_schedule_date',
        entityName: '',
      );
    }
    if (q.contains('bac si') || q.contains('bs ')) {
      return const _QueryIntent(
        needsFirebase: true,
        queryType: 'doctor_list',
        entityName: '',
      );
    }
    if (q.contains('benh nhan')) {
      return const _QueryIntent(
        needsFirebase: true,
        queryType: 'patient_appointments',
        entityName: '',
      );
    }
    if (q.contains('hoa don') || q.contains('thanh toan')) {
      return const _QueryIntent(
        needsFirebase: true,
        queryType: 'invoice',
        entityName: '',
      );
    }
    if (q.contains('bao hiem')) {
      return const _QueryIntent(
        needsFirebase: true,
        queryType: 'insurance',
        entityName: '',
      );
    }
    return _QueryIntent.noFirebase();
  }

  // ── Entry point chính ────────────────────────────────────────────────────
  Future<String> buildContextForQuestion(String question) async {
    try {
      if (_isDoctorScheduleQuestion(question)) {
        return _getLiveDoctorScheduleByQuestion(question);
      }

      final intent = await _detectIntent(question);

      if (!intent.needsFirebase) {
        return 'Không cần tra cứu Firebase cho câu hỏi này.';
      }

      switch (intent.queryType) {
        case 'appointments_today':
          return _getTodayAppointmentSummary();
        case 'doctor_availability':
          return _getDoctorAvailability(
            intent.entityName.isNotEmpty ? intent.entityName : question,
          );
        case 'doctor_schedule_date':
          return _getLiveDoctorScheduleByQuestion(
            question,
            doctorName: intent.entityName,
          );
        case 'patient_appointments':
          return _getPatientAppointments(
            intent.entityName.isNotEmpty ? intent.entityName : question,
          );
        case 'department_doctors':
          return _getDepartmentDoctorsOnDuty(
            intent.entityName.isNotEmpty ? intent.entityName : question,
          );
        case 'doctor_list':
          return _getDoctorDirectorySummary(question);
        case 'invoice':
          return _getPatientInvoices(
            intent.entityName.isNotEmpty ? intent.entityName : question,
          );
        case 'insurance':
          return _getPatientInsurance(
            intent.entityName.isNotEmpty ? intent.entityName : question,
          );
        case 'general':
        default:
          return _getGeneralHospitalContext(question);
      }
    } catch (e) {
      return 'Không thể truy vấn Firebase lúc này. Lỗi: $e';
    }
  }

  // ── Giữ lại để tương thích ngược nếu cần ────────────────────────────────
  static bool shouldQueryFirebase(String question) {
    // Luôn trả về true — để AI tự quyết định trong buildContextForQuestion
    return true;
  }

  // ─────────────────────────────────────────────
  // Các hàm query Firebase (giữ nguyên logic cũ)
  // ─────────────────────────────────────────────

  Future<String> _getTodayAppointmentSummary() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('Appointments')
        .where(
          'appointmentDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where('appointmentDate', isLessThan: Timestamp.fromDate(end))
        .get();

    if (snapshot.docs.isEmpty) {
      return 'Dữ liệu hệ thống: Hôm nay chưa có lịch hẹn nào trong Firestore.';
    }

    final statusCount = <String, int>{};
    for (final doc in snapshot.docs) {
      final status = _text(doc.data()['status'], fallback: 'không rõ');
      statusCount[status] = (statusCount[status] ?? 0) + 1;
    }

    final details = snapshot.docs
        .take(8)
        .map((doc) {
          return '- ${_appointmentLine(doc.id, doc.data())}';
        })
        .join('\n');

    return '''
Dữ liệu hệ thống:
- Tổng lịch hẹn hôm nay: ${snapshot.docs.length}
- Theo trạng thái: ${statusCount.entries.map((e) => '${e.key}: ${e.value}').join(', ')}
- Một số lịch hẹn:
$details
''';
  }

  Future<String> _getDoctorAvailability(String nameOrQuestion) async {
    final doctor = await _findDoctorByName(nameOrQuestion);
    if (doctor == null) {
      return 'Dữ liệu hệ thống: Không tìm thấy bác sĩ phù hợp với câu hỏi.';
    }

    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 7));
    final schedules = await _firestore
        .collection('DoctorSchedules')
        .where('doctorId', isEqualTo: doctor.id)
        .where(
          'scheduleDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where('scheduleDate', isLessThan: Timestamp.fromDate(end))
        .get();

    if (schedules.docs.isEmpty) {
      return 'Dữ liệu hệ thống: ${doctor.name} chưa có lịch làm việc trong 7 ngày tới.';
    }

    final available = schedules.docs.where((doc) {
      final data = doc.data();
      return data['isAvailable'] != false &&
          _intValue(data['availableSlots']) > 0;
    }).toList();

    final lines = schedules.docs
        .take(12)
        .map((doc) {
          final data = doc.data();
          final date = _toDateTime(data['scheduleDate']);
          final shift = _text(data['shiftId'], fallback: 'không rõ ca');
          final slots = _intValue(data['availableSlots']);
          final maxSlots = _intValue(data['maxSlots']);
          return '- ${date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Không rõ ngày'}, ca $shift: còn $slots/$maxSlots chỗ';
        })
        .join('\n');

    return '''
Dữ liệu hệ thống:
- Bác sĩ: ${doctor.name}
- Chuyên khoa: ${doctor.specialization}
- Có lịch trống trong 7 ngày tới: ${available.isNotEmpty ? 'Có' : 'Không'}
- Lịch làm việc:
$lines
''';
  }

  Future<String> _getPatientAppointments(String nameOrQuestion) async {
    final patient = await _findPatientByName(nameOrQuestion);
    if (patient == null) {
      return 'Dữ liệu hệ thống: Không tìm thấy bệnh nhân phù hợp với câu hỏi.';
    }

    final appointments = await _firestore
        .collection('Appointments')
        .where('patientId', isEqualTo: patient.id)
        .limit(20)
        .get();

    if (appointments.docs.isEmpty) {
      return 'Dữ liệu hệ thống: Bệnh nhân ${patient.name} hiện chưa có lịch hẹn.';
    }

    final lines = appointments.docs
        .map((doc) {
          return '- ${_appointmentLine(doc.id, doc.data())}';
        })
        .join('\n');

    return '''
Dữ liệu hệ thống:
- Bệnh nhân: ${patient.name}
- Số lịch hẹn tìm thấy: ${appointments.docs.length}
$lines
''';
  }

  Future<String> _getDepartmentDoctorsOnDuty(String nameOrQuestion) async {
    final department = await _findDepartmentByName(nameOrQuestion);
    if (department == null) {
      return 'Dữ liệu hệ thống: Không tìm thấy khoa/phòng ban phù hợp với câu hỏi.';
    }

    final doctors = await _firestore
        .collection('Doctors')
        .where('departmentId', isEqualTo: department.id)
        .limit(30)
        .get();

    if (doctors.docs.isEmpty) {
      return 'Dữ liệu hệ thống: Khoa ${department.name} chưa có bác sĩ trong Firestore.';
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final lines = <String>[];

    for (final doctorDoc in doctors.docs) {
      final doctor = await _doctorFromDoc(doctorDoc);
      final schedules = await _firestore
          .collection('DoctorSchedules')
          .where('doctorId', isEqualTo: doctor.id)
          .where(
            'scheduleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where('scheduleDate', isLessThan: Timestamp.fromDate(end))
          .get();

      for (final schedule in schedules.docs) {
        final data = schedule.data();
        if (data['isAvailable'] == false) continue;
        lines.add(
          '- ${doctor.name}, ca ${_text(data['shiftId'])}, còn ${_intValue(data['availableSlots'])}/${_intValue(data['maxSlots'])} chỗ',
        );
      }
    }

    if (lines.isEmpty) {
      return 'Dữ liệu hệ thống: Hôm nay chưa có bác sĩ khoa ${department.name} trực hoặc còn lịch trống.';
    }

    return '''
Dữ liệu hệ thống:
- Khoa/phòng ban: ${department.name}
- Bác sĩ trực hôm nay:
${lines.join('\n')}
''';
  }

  // ignore: unused_element
  Future<String> _getDoctorsOnDutyByDate(String question) async {
    final targetDate = _targetDateFromQuestion(question);
    final start = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final end = start.add(const Duration(days: 1));

    final schedules = await _firestore
        .collection('DoctorSchedules')
        .where(
          'scheduleDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where('scheduleDate', isLessThan: Timestamp.fromDate(end))
        .get();

    if (schedules.docs.isEmpty) {
      return 'Dữ liệu hệ thống: Không tìm thấy lịch trực của bác sĩ vào ngày ${DateFormat('dd/MM/yyyy').format(start)}.';
    }

    final lines = <String>[];
    for (final schedule in schedules.docs) {
      final data = schedule.data();
      if (data['isAvailable'] == false) continue;

      final doctorId = _text(data['doctorId']);
      final doctor = await _doctorById(doctorId);
      final doctorName = doctor?.name ?? 'Bác sĩ $doctorId';
      final department = doctor?.departmentName ?? doctor?.specialization ?? '';
      final shift = _text(data['shiftId'], fallback: 'không rõ ca');
      final slots = _intValue(data['availableSlots']);
      final maxSlots = _intValue(data['maxSlots']);

      lines.add(
        '- $doctorName${department.isNotEmpty ? ' - $department' : ''}, ca $shift, còn $slots/$maxSlots chỗ',
      );
    }

    if (lines.isEmpty) {
      return 'Dữ liệu hệ thống: Ngày ${DateFormat('dd/MM/yyyy').format(start)} có lịch trong DoctorSchedules nhưng không có ca nào đang mở.';
    }

    return '''
Dữ liệu hệ thống:
- Ngày cần tra cứu: ${DateFormat('dd/MM/yyyy').format(start)}
- Số ca trực/làm việc tìm thấy: ${lines.length}
- Bác sĩ có lịch:
${lines.join('\n')}
''';
  }

  Future<String> _getLiveDoctorScheduleByQuestion(
    String question, {
    String doctorName = '',
  }) async {
    final normalized = _normalize(question);
    final doctorQuery = doctorName.trim().isNotEmpty ? doctorName : question;
    final doctor = await _findDoctorByName(doctorQuery);
    final weekday = _weekdayFromQuestion(normalized);
    final hasExplicitDate =
        _explicitDateFromQuestion(normalized, DateTime.now()) != null ||
        normalized.contains('hom nay') ||
        normalized.contains('ngay mai') ||
        normalized.contains('ngay kia');

    if (weekday != null && !hasExplicitDate) {
      return _getLiveDoctorSchedulesByWeekday(weekday, doctor: doctor);
    }

    final targetDate = _targetDateFromQuestion(question);
    final start = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final end = start.add(const Duration(days: 1));

    var query = _firestore
        .collection('DoctorSchedules')
        .where(
          'scheduleDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where('scheduleDate', isLessThan: Timestamp.fromDate(end));
    if (doctor != null) {
      query = query.where('doctorId', isEqualTo: doctor.id);
    }

    final schedules = await query.get();
    final lines = <String>[];
    for (final schedule in schedules.docs) {
      final data = schedule.data();
      if (!_isScheduleOpen(data)) continue;
      lines.add(await _scheduleLine(data, doctor: doctor));
    }

    final dateText = DateFormat('dd/MM/yyyy').format(start);
    if (lines.isEmpty) {
      final doctorText = doctor != null ? ' của ${doctor.name}' : '';
      return 'Dữ liệu hệ thống: Không tìm thấy lịch làm việc$doctorText vào ngày $dateText.';
    }

    return '''
Dữ liệu hệ thống:
- Nguồn dữ liệu: Doctors + DoctorSchedules hiện tại trên Firebase.
- Ngày cần tra cứu: $dateText
- ${doctor != null ? 'Bác sĩ: ${doctor.name}' : 'Số ca làm việc tìm thấy: ${lines.length}'}
- Lịch làm việc:
${lines.join('\n')}
''';
  }

  Future<String> _getLiveDoctorSchedulesByWeekday(
    int weekday, {
    _DoctorInfo? doctor,
  }) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 56));

    var query = _firestore
        .collection('DoctorSchedules')
        .where(
          'scheduleDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where('scheduleDate', isLessThan: Timestamp.fromDate(end));
    if (doctor != null) {
      query = query.where('doctorId', isEqualTo: doctor.id);
    }

    final schedules = await query.get();
    final matched =
        schedules.docs.where((doc) {
          final data = doc.data();
          final date = _toDateTime(data['scheduleDate']);
          return date != null &&
              date.weekday == weekday &&
              _isScheduleOpen(data);
        }).toList()..sort((a, b) {
          final aDate = _toDateTime(a.data()['scheduleDate']) ?? start;
          final bDate = _toDateTime(b.data()['scheduleDate']) ?? start;
          return aDate.compareTo(bDate);
        });

    final weekdayName = _weekdayName(weekday);
    if (matched.isEmpty) {
      final doctorText = doctor != null ? ' của ${doctor.name}' : '';
      return 'Dữ liệu hệ thống: Không tìm thấy lịch làm việc$doctorText vào $weekdayName trong 8 tuần tới.';
    }

    final lines = <String>[];
    for (final schedule in matched.take(20)) {
      lines.add(await _scheduleLine(schedule.data(), doctor: doctor));
    }

    return '''
Dữ liệu hệ thống:
- Nguồn dữ liệu: Doctors + DoctorSchedules hiện tại trên Firebase.
- Thứ cần tra cứu: $weekdayName
- Khoảng tra cứu: ${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end.subtract(const Duration(days: 1)))}
- ${doctor != null ? 'Bác sĩ: ${doctor.name}' : 'Số ca phù hợp: ${matched.length}'}
- Lịch làm việc:
${lines.join('\n')}
''';
  }

  Future<String> _scheduleLine(
    Map<String, dynamic> data, {
    _DoctorInfo? doctor,
  }) async {
    final date = _toDateTime(data['scheduleDate']);
    final doctorId = _text(data['doctorId']);
    final scheduleDoctor = doctor ?? await _doctorById(doctorId);
    final scheduleDoctorName = scheduleDoctor?.name ?? 'Bác sĩ $doctorId';
    final department =
        scheduleDoctor?.departmentName ?? scheduleDoctor?.specialization ?? '';
    final shift = _text(data['shiftId'], fallback: 'không rõ ca');
    final room = _firstNonEmpty([data['roomNumber'], data['roomId']]);
    final slots = _intValue(data['availableSlots']);
    final maxSlots = _intValue(data['maxSlots']);
    return '- ${date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Không rõ ngày'}: $scheduleDoctorName${department.isNotEmpty ? ' - $department' : ''}, ca $shift${room.isNotEmpty ? ', phòng $room' : ''}, còn $slots/$maxSlots chỗ';
  }

  Future<String> _getDoctorDirectorySummary(String question) async {
    final normalized = _normalize(question);
    final doctors = await _firestore.collection('Doctors').limit(100).get();

    if (doctors.docs.isEmpty) {
      return 'Dữ liệu hệ thống: Chưa tìm thấy bác sĩ nào trong collection Doctors.';
    }

    final departmentCount = <String, int>{};
    final doctorLines = <String>[];

    for (final doc in doctors.docs) {
      final doctor = await _doctorFromDoc(doc);
      final dept = doctor.departmentName.isNotEmpty
          ? doctor.departmentName
          : doctor.specialization;
      if (dept.isNotEmpty) {
        departmentCount[dept] = (departmentCount[dept] ?? 0) + 1;
      }
      doctorLines.add(_doctorLine(doctor));
    }

    final rankingNote = normalized.contains('gioi')
        ? '\n- Ghi chú: Không có trường đánh giá/xếp hạng trong Firestore.'
        : '';

    return '''
Dữ liệu hệ thống:
- Số bác sĩ: ${doctors.docs.length}
${departmentCount.isNotEmpty ? '- Theo khoa: ${departmentCount.entries.map((e) => '${e.key}: ${e.value}').join(', ')}' : ''}
$rankingNote
- Danh sách bác sĩ:
${doctorLines.take(20).join('\n')}
''';
  }

  Future<String> _getPatientInvoices(String nameOrQuestion) async {
    final patient = await _findPatientByName(nameOrQuestion);
    if (patient == null) {
      return 'Dữ liệu hệ thống: Không tìm thấy bệnh nhân phù hợp để tra cứu hóa đơn.';
    }

    final invoicesByPatient = await _firestore
        .collection('Invoices')
        .where('patientId', isEqualTo: patient.id)
        .limit(20)
        .get();

    if (invoicesByPatient.docs.isEmpty) {
      return 'Dữ liệu hệ thống: Không tìm thấy hóa đơn của bệnh nhân ${patient.name}.';
    }

    var total = 0.0;
    final lines = invoicesByPatient.docs
        .map((doc) {
          final data = doc.data();
          final amount = _doubleValue(
            data['amount'] ?? data['total'] ?? data['totalAmount'],
          );
          total += amount;
          final status = _text(data['status'], fallback: 'không rõ');
          final createdAt = _toDateTime(data['createdAt']);
          return '- ${doc.id}: ${_currencyFormat.format(amount)}, trạng thái $status, ngày ${createdAt != null ? _dateFormat.format(createdAt) : 'không rõ'}';
        })
        .join('\n');

    return '''
Dữ liệu hệ thống:
- Bệnh nhân: ${patient.name}
- Tổng tiền: ${_currencyFormat.format(total)}
- Chi tiết:
$lines
''';
  }

  Future<String> _getPatientInsurance(String nameOrQuestion) async {
    final patient = await _findPatientByName(nameOrQuestion);
    if (patient == null) {
      return 'Dữ liệu hệ thống: Không tìm thấy bệnh nhân phù hợp để tra cứu bảo hiểm.';
    }

    final insuranceDoc = await _firestore
        .collection('health_insurances')
        .doc(patient.id)
        .get();
    final insuranceData = insuranceDoc.data() ?? {};
    final number = _firstNonEmpty([
      insuranceData['insuranceNumber'],
      patient.data['healthInsuranceNumber'],
    ]);

    if (number.isEmpty) {
      return 'Dữ liệu hệ thống: Bệnh nhân ${patient.name} chưa có số bảo hiểm y tế.';
    }

    final status = _firstNonEmpty([
      insuranceData['status'],
      patient.data['healthInsuranceStatus'],
    ], fallback: 'unverified');

    return '''
Dữ liệu hệ thống:
- Bệnh nhân: ${patient.name}
- Số bảo hiểm: $number
- Trạng thái: ${_insuranceStatusLabel(status)}
''';
  }

  Future<String> _getGeneralHospitalContext(String question) async {
    final departments = await _firestore
        .collection('Departments')
        .limit(12)
        .get();
    final deptNames = departments.docs
        .map((d) => _departmentName(d.data()))
        .where((v) => v.isNotEmpty)
        .join(', ');
    return 'Dữ liệu hệ thống:\n- Các khoa hiện có: $deptNames';
  }

  // ─────────────────────────────────────────────
  // Tìm kiếm entity — nhận trực tiếp tên thay vì
  // toàn bộ câu hỏi (chính xác hơn)
  // ─────────────────────────────────────────────

  Future<_DoctorInfo?> _findDoctorByName(String nameOrQuestion) async {
    final docs = await _firestore.collection('Doctors').limit(80).get();
    final normalized = _normalize(nameOrQuestion);
    _DoctorInfo? fallback;

    for (final doc in docs.docs) {
      final doctor = await _doctorFromDoc(doc);
      final normalizedName = _normalize(doctor.name);
      if (fallback == null && normalized.contains(_lastName(normalizedName))) {
        fallback = doctor;
      }
      if (normalizedName.isNotEmpty && normalized.contains(normalizedName)) {
        return doctor;
      }
    }
    return fallback;
  }

  Future<_PatientInfo?> _findPatientByName(String nameOrQuestion) async {
    final normalizedQ = _normalize(nameOrQuestion);

    for (final collection in ['patients', 'users']) {
      final docs = await _firestore.collection(collection).limit(100).get();
      for (final doc in docs.docs) {
        final data = doc.data();
        final name = _firstNonEmpty([
          data['fullName'],
          data['name'],
          data['username'],
        ]);
        final normalizedName = _normalize(name);
        if (normalizedName.isNotEmpty &&
            (normalizedQ.contains(normalizedName) ||
                normalizedQ.contains(_lastName(normalizedName)))) {
          return _PatientInfo(id: doc.id, name: name, data: data);
        }
      }
    }
    return null;
  }

  Future<_DepartmentInfo?> _findDepartmentByName(String nameOrQuestion) async {
    final docs = await _firestore.collection('Departments').limit(60).get();
    final normalizedQ = _normalize(nameOrQuestion);

    for (final doc in docs.docs) {
      final data = doc.data();
      final name = _departmentName(data);
      final aliases = _departmentAliases(name);
      if (aliases.any(normalizedQ.contains)) {
        return _DepartmentInfo(id: doc.id, name: name);
      }
    }
    return null;
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  Future<_DoctorInfo> _doctorFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    return _doctorFromMap(doc.id, doc.data());
  }

  Future<_DoctorInfo?> _doctorById(String doctorId) async {
    if (doctorId.isEmpty) return null;
    final doc = await _firestore.collection('Doctors').doc(doctorId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return _doctorFromMap(doc.id, data);
  }

  Future<_DoctorInfo> _doctorFromMap(
    String id,
    Map<String, dynamic> data,
  ) async {
    var name = _firstNonEmpty([
      data['name'],
      data['fullName'],
      data['doctorName'],
    ]);
    if (name.isEmpty && _text(data['userId']).isNotEmpty) {
      final user = await _getUserById(_text(data['userId']));
      name = _firstNonEmpty([
        user?['fullName'],
        user?['name'],
        user?['username'],
      ]);
    }
    return _DoctorInfo(
      id: id,
      name: name.isEmpty ? 'Bác sĩ $id' : name,
      specialization: _firstNonEmpty([
        data['specialization'],
        data['departmentName'],
        data['departmentId'],
      ]),
      departmentName: _firstNonEmpty([
        data['departmentName'],
        data['departmentId'],
      ]),
      consultationFee: _doubleValue(data['consultationFee']),
      yearsOfExperience: _intValue(data['yearsOfExperience']),
      isActive: data['isActive'] != false,
    );
  }

  Future<Map<String, dynamic>?> _getUserById(String id) async {
    final lower = await _firestore.collection('users').doc(id).get();
    if (lower.exists) return lower.data();
    final upper = await _firestore.collection('users').doc(id).get();
    if (upper.exists) return upper.data();
    return null;
  }

  String _appointmentLine(String id, Map<String, dynamic> data) {
    final date = _toDateTime(data['appointmentDate'] ?? data['date']);
    final patient = _firstNonEmpty([data['patientName'], data['patientId']]);
    final doctor = _firstNonEmpty([data['doctorName'], data['doctorId']]);
    final department = _firstNonEmpty([
      data['departmentName'],
      data['departmentId'],
    ]);
    final status = _text(data['status'], fallback: 'không rõ');
    return '$id: ${date != null ? _dateFormat.format(date) : 'không rõ ngày'}, bệnh nhân $patient, bác sĩ $doctor, khoa $department, trạng thái $status';
  }

  String _doctorLine(_DoctorInfo doctor) {
    final details = <String>[
      if (doctor.departmentName.isNotEmpty) 'khoa ${doctor.departmentName}',
      if (doctor.yearsOfExperience > 0) '${doctor.yearsOfExperience} năm KN',
      if (doctor.consultationFee > 0)
        'phí ${_currencyFormat.format(doctor.consultationFee)}',
      doctor.isActive ? 'đang hoạt động' : 'tạm ngưng',
    ];
    return '- ${doctor.name} (${doctor.id})${details.isNotEmpty ? ': ${details.join(', ')}' : ''}';
  }

  static String _departmentName(Map<String, dynamic> data) =>
      _firstNonEmpty([data['departmentName'], data['name'], data['title']]);

  static Set<String> _departmentAliases(String name) {
    final normalized = _normalize(
      name,
    ).replaceFirst(RegExp(r'^khoa\s+'), '').trim();
    final aliases = <String>{};
    if (normalized.isNotEmpty) {
      aliases.add(normalized);
      aliases.addAll(
        normalized.split(' ').where((w) => w.length > 2 && w != 'khoa'),
      );
    }
    return aliases;
  }

  static String _insuranceStatusLabel(String status) {
    switch (_normalize(status)) {
      case 'verified':
        return 'Hợp lệ/đã xác minh';
      case 'pending':
        return 'Đang chờ xác minh';
      case 'rejected':
        return 'Không hợp lệ';
      default:
        return 'Chưa xác minh';
    }
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static DateTime _targetDateFromQuestion(String question) {
    final normalized = _normalize(question);
    final now = DateTime.now();
    final explicitDate = _explicitDateFromQuestion(normalized, now);
    if (explicitDate != null) return explicitDate;

    if (normalized.contains('ngay kia')) {
      return now.add(const Duration(days: 2));
    }
    if (normalized.contains('ngay mai') || normalized.contains('mai')) {
      return now.add(const Duration(days: 1));
    }
    return now;
  }

  static int? _weekdayFromQuestion(String normalized) {
    if (normalized.contains('chu nhat') ||
        normalized.contains('cn') ||
        normalized.contains('sunday')) {
      return DateTime.sunday;
    }
    if (normalized.contains('thu 2') ||
        normalized.contains('thu hai') ||
        normalized.contains('monday')) {
      return DateTime.monday;
    }
    if (normalized.contains('thu 3') ||
        normalized.contains('thu ba') ||
        normalized.contains('tuesday')) {
      return DateTime.tuesday;
    }
    if (normalized.contains('thu 4') ||
        normalized.contains('thu tu') ||
        normalized.contains('wednesday')) {
      return DateTime.wednesday;
    }
    if (normalized.contains('thu 5') ||
        normalized.contains('thu nam') ||
        normalized.contains('thursday')) {
      return DateTime.thursday;
    }
    if (normalized.contains('thu 6') ||
        normalized.contains('thu sau') ||
        normalized.contains('friday')) {
      return DateTime.friday;
    }
    if (normalized.contains('thu 7') ||
        normalized.contains('thu bay') ||
        normalized.contains('saturday')) {
      return DateTime.saturday;
    }
    return null;
  }

  static String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Thứ 2';
      case DateTime.tuesday:
        return 'Thứ 3';
      case DateTime.wednesday:
        return 'Thứ 4';
      case DateTime.thursday:
        return 'Thứ 5';
      case DateTime.friday:
        return 'Thứ 6';
      case DateTime.saturday:
        return 'Thứ 7';
      case DateTime.sunday:
        return 'Chủ nhật';
      default:
        return 'Không rõ thứ';
    }
  }

  static bool _isScheduleOpen(Map<String, dynamic> data) {
    return data['isActive'] != false && data['isAvailable'] != false;
  }

  static bool _isDoctorScheduleQuestion(String question) {
    final normalized = _normalize(question);
    final hasDoctor =
        normalized.contains('bac si') || normalized.contains('bs ');
    final hasScheduleWord =
        normalized.contains('lich') ||
        normalized.contains('truc') ||
        normalized.contains('lam') ||
        normalized.contains('ca');
    final hasDateSignal =
        normalized.contains('hom nay') ||
        normalized.contains('ngay mai') ||
        normalized.contains('ngay kia') ||
        _weekdayFromQuestion(normalized) != null ||
        _explicitDateFromQuestion(normalized, DateTime.now()) != null;
    return hasDoctor && hasScheduleWord && hasDateSignal;
  }

  static DateTime? _explicitDateFromQuestion(String normalized, DateTime now) {
    final match = RegExp(
      r'(?:ngay\s*)?(\d{1,2})\s*[\/\-]\s*(\d{1,2})(?:\s*[\/\-]\s*(\d{2,4}))?',
    ).firstMatch(normalized);
    if (match == null) return null;

    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    var year = int.tryParse(match.group(3) ?? '') ?? now.year;
    if (year < 100) year += 2000;
    if (day == null || month == null) return null;

    try {
      final date = DateTime(year, month, day);
      if (date.year != year || date.month != month || date.day != day) {
        return null;
      }
      return date;
    } catch (_) {
      return null;
    }
  }

  static String _text(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _doubleValue(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _firstNonEmpty(List<dynamic> values, {String fallback = ''}) {
    for (final value in values) {
      final text = _text(value);
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  static String _lastName(String normalizedName) {
    final parts = normalizedName.split(' ').where((p) => p.isNotEmpty).toList();
    return parts.isEmpty ? normalizedName : parts.last;
  }

  static String _normalize(String value) {
    const from =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const to =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    var result = value.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

// ─────────────────────────────────────────────
// Data classes
// ─────────────────────────────────────────────

class _DoctorInfo {
  const _DoctorInfo({
    required this.id,
    required this.name,
    required this.specialization,
    required this.departmentName,
    required this.consultationFee,
    required this.yearsOfExperience,
    required this.isActive,
  });
  final String id, name, specialization, departmentName;
  final double consultationFee;
  final int yearsOfExperience;
  final bool isActive;
}

class _PatientInfo {
  const _PatientInfo({
    required this.id,
    required this.name,
    required this.data,
  });
  final String id, name;
  final Map<String, dynamic> data;
}

class _DepartmentInfo {
  const _DepartmentInfo({required this.id, required this.name});
  final String id, name;
}
