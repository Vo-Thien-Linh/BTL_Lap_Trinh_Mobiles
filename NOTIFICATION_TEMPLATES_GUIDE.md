# 🏥 Hướng Dẫn Quản Lý Mẫu Thông Báo Theo Khoa

## 📋 Tổng Quan

Mẫu thông báo cho phép lưu trữ nội dung chuẩn bị và hướng dẫn theo loại khoa khám, giúp tự động hóa việc gửi thông báo với thông tin đúng cho từng bệnh nhân.

---

## 🏢 Các Khoa & Mẫu Chuẩn Bị

### 1. **Khoa Nội Soi (Endoscopy)**

**Template ID**: `template_endoscopy_prep`

**Nội dung**:
```
Tiêu đề: "Hướng dẫn chuẩn bị khám nội soi"

Nội dung chính:
"Vui lòng tuân thủ các hướng dẫn sau để đảm bảo khám hiệu quả:

1. NHỊN ĂN:
   - Nhịn ăn tối thiểu 6 giờ trước khi khám
   - Chỉ được uống nước lọc từ 2 giờ trước khi khám

2. HỘC THUỐC:
   - Thông báo cho bác sĩ nếu bạn đang dùng aspirin hoặc thuốc chống đông
   - Có thể cần ngừng 3-5 ngày trước khám

3. ĐỒNG HỒ & ĐỒ THI:
   - Cụ thể kiểm tra huyết áp và nồng độ đường
   - Sẽ làm xét nghiệm máu nhanh nếu cần

4. MANG THEO:
   - CCCD/Hộ chiếu (bắt buộc)
   - Bảo hiểm y tế (nếu có)
   - Danh sách thuốc đang dùng
   - Kết quả khám trước đó (nếu có)

5. MẶC ĐỒ:
   - Mặc quần áo rộng, dễ cởi mở
   - Không mặc trang sức
   - Không trang điểm"

Chỉ dẫn Chi Tiết:
- "Nhịn ăn tối thiểu 6 giờ"
- "Uống nước lọc từ 2 giờ trước"
- "Ngừng aspirin 3-5 ngày"
- "Mang CCCD"
- "Mặc quần áo rộng"
- "Thông báo về sắc phục dung nạp"
```

**Firestore Document**:
```json
{
  "id": "template_endoscopy_prep",
  "departmentId": "endoscopy",
  "departmentName": "Khoa Nội Soi",
  "templateType": "preparation",
  "title": "Hướng dẫn chuẩn bị khám nội soi",
  "message": "Vui lòng tuân thủ...",
  "instructions": [
    "Nhịn ăn tối thiểu 6 giờ",
    "Uống nước lọc từ 2 giờ trước",
    "Ngừng aspirin 3-5 ngày",
    "Mang CCCD",
    "Mặc quần áo rộng",
    "Thông báo về tình trạng sức khỏe"
  ],
  "isActive": true,
  "createdAt": "2026-05-08T10:00:00Z",
  "updatedAt": "2026-05-08T10:00:00Z"
}
```

---

### 2. **Khoa Xét Nghiệm Máu (Laboratory)**

**Template ID**: `template_lab_prep`

```json
{
  "id": "template_lab_prep",
  "departmentId": "laboratory",
  "departmentName": "Khoa Xét Nghiệm",
  "templateType": "preparation",
  "title": "Hướng dẫn chuẩn bị xét nghiệm máu",
  "message": "Để xét nghiệm chính xác, vui lòng thực hiện:",
  "instructions": [
    "Nhịn ăn 8-12 giờ (có thể uống nước)",
    "Tránh uống cà phê, trà chè",
    "Không uống rượu 24 giờ trước",
    "Tránh gắng sức nặng 24 giờ",
    "Mang CCCD/BHYT",
    "Đến sớm 10 phút"
  ],
  "isActive": true
}
```

---

### 3. **Khoa Tim Mạch (Cardiology)**

**Template ID**: `template_cardio_prep`

```json
{
  "id": "template_cardio_prep",
  "departmentId": "cardiology",
  "departmentName": "Khoa Tim Mạch",
  "templateType": "preparation",
  "title": "Hướng dẫn chuẩn bị khám tim mạch",
  "message": "Chuẩn bị cho buổi khám tim mạch:",
  "instructions": [
    "Mang theo tất cả thuốc đang uống",
    "Chuẩn bị danh sách triệu chứng",
    "Không tập thể dục nặng 24 giờ",
    "Nếu có máy đo huyết áp, mang theo",
    "Mặc quần áo không dệt thừng kim loại",
    "Mang kết quả ECG cũ (nếu có)",
    "Đến đúng giờ"
  ],
  "isActive": true
}
```

---

### 4. **Khoa Nha Khoa (Dentistry)**

**Template ID**: `template_dental_prep`

```json
{
  "id": "template_dental_prep",
  "departmentId": "dentistry",
  "departmentName": "Khoa Nha Khoa",
  "templateType": "preparation",
  "title": "Hướng dẫn chuẩn bị khám nha khoa",
  "message": "Chuẩn bị cho khám nha khoa:",
  "instructions": [
    "Vệ sinh răng miệng sạch sẽ trước khám",
    "Uống nước và uống caffeine bình thường",
    "Không ăn gì 30 phút trước khám",
    "Thông báo nếu có sợ kim tiêm",
    "Mang CCCD",
    "Cho biết nếu dị ứng pennicillin",
    "Mang kết quả X-quang nha khoa cũ (nếu có)"
  ],
  "isActive": true
}
```

---

### 5. **Khoa Phụ Khoa (Obstetrics & Gynecology)**

**Template ID**: `template_obgyn_prep`

```json
{
  "id": "template_obgyn_prep",
  "departmentId": "obstetrics_gynecology",
  "departmentName": "Khoa Phụ Khoa",
  "templateType": "preparation",
  "title": "Hướng dẫn chuẩn bị khám phụ khoa",
  "message": "Chuẩn bị cho khám phụ khoa:",
  "instructions": [
    "Vệ sinh vùng kín sạch sẽ",
    "Nên khám trong 7-10 ngày sau chu kỳ kinh",
    "Không quan hệ tình dục 48 giờ trước",
    "Không douche 48 giờ trước",
    "Mang CCCD/BHYT",
    "Mang danh sách contraception (nếu có)",
    "Thông báo lịch kinh nguyệt gần nhất"
  ],
  "isActive": true
}
```

---

### 6. **Khoa Siêu Âm (Ultrasound)**

**Template ID**: `template_ultrasound_prep`

```json
{
  "id": "template_ultrasound_prep",
  "departmentId": "ultrasound",
  "departmentName": "Khoa Siêu Âm",
  "templateType": "preparation",
  "title": "Hướng dẫn chuẩn bị siêu âm",
  "message": "Chuẩn bị cho buổi siêu âm:",
  "instructions": [
    "Siêu âm gan/lách/thận: Nhịn ăn 4 giờ",
    "Siêu âm thai kỳ đầu: Uống đầy đủ nước, không tiểu tiện",
    "Siêu âm tuyến vú: Không nên trong 7 ngày trước kinh",
    "Mặc quần áo dễ cởi mở",
    "Không mang đồ trang sức kim loại",
    "Mang CCCD",
    "Đến sớm 15 phút"
  ],
  "isActive": true
}
```

---

## 📝 Hướng Dẫn Nhắc Tái Khám

### Post-Examination Reminders

```json
{
  "id": "reminder_dental_6months",
  "departmentId": "dentistry",
  "departmentName": "Khoa Nha Khoa",
  "templateType": "followUpReminder",
  "title": "Đã đến lúc khám nha khoa định kỳ",
  "message": "Bạn đã 6 tháng không khám nha khoa. Khám định kỳ giúp phát hiện sớm các vấn đề về răng.",
  "reminderIntervalDays": 180,
  "isActive": true
}
```

**Các bộ nhắc tái khám tiêu chuẩn**:
- Nha khoa: 6 tháng
- Mắt: 1 năm
- Tim mạch (nguy cơ cao): 3 tháng
- Khám tổng quát: 1 năm

---

## 💊 Mẫu Nhắc Uống Thuốc

### Medication Reminders

```dart
// Từ đơn thuốc, tạo schedule:
{
  "prescriptionId": "rx_12345",
  "userId": "patient_123",
  "medications": [
    {
      "name": "Aspirin 100mg",
      "dosage": "1 viên",
      "frequency": "1 lần/ngày",
      "timing": ["08:00"],  // 8 giờ sáng
      "duration": "30 ngày"
    },
    {
      "name": "Omeprazole 20mg",
      "dosage": "1 viên",
      "frequency": "2 lần/ngày",
      "timing": ["07:00", "19:00"],  // Sáng & tối
      "duration": "14 ngày"
    }
  ]
}
```

**Notification**:
```
Tiêu đề: "Đã đến giờ uống thuốc"
Nội dung: "Hãy uống 1 viên Aspirin 100mg"
Icon: 💊
```

---

## 🗄️ Database Schema (Firestore)

### Collection: `notification_templates`

```firestore
/notification_templates/{templateId}
  ├─ id (string) - Template ID
  ├─ departmentId (string) - Khoa khám
  ├─ departmentName (string) - Tên khoa
  ├─ templateType (string) - preparation | reminder | postExamination
  ├─ title (string) - Tiêu đề
  ├─ message (string) - Nội dung chính
  ├─ instructions (array) - Danh sách hướng dẫn
  ├─ isActive (boolean) - Kích hoạt/Vô hiệu
  ├─ reminderIntervalDays (number, optional) - Khoảng thời gian (tái khám)
  ├─ createdAt (timestamp) - Ngày tạo
  ├─ updatedAt (timestamp) - Ngày cập nhật
  └─ createdBy (string, optional) - Admin ID

// Index cho tìm kiếm nhanh
Index: departmentId + templateType
```

---

## 🔄 Luồng Gửi Thông Báo Chuẩn Bị

```
1. Bệnh nhân đặt lịch khám
   ↓
2. System xác định departmentId
   ↓
3. Query Firestore: 
   WHERE templateType = 'preparation' AND departmentId = xxx
   ↓
4. Tạo thông báo từ template:
   - Title = template.title
   - Message = template.message
   - Instructions = template.instructions[]
   ↓
5. Gửi 24h trước lịch khám:
   - FCM (Cloud notification)
   - Local notification (offline backup)
   ↓
6. Người dùng nhận & tap → show chi tiết
```

---

## 🚀 Triển Khai Mẫu

### Bước 1: Tạo Mẫu (Admin Panel)

```dart
// Pseudo code
Future<void> createTemplate(NotificationTemplateModel template) async {
  await firestore
    .collection('notification_templates')
    .add(template.toJson());
}
```

### Bước 2: Gửi Thông Báo

```dart
Future<void> sendPreparationNotification(String departmentId, String userId) {
  // 1. Lấy template
  final template = await getTemplate(departmentId, 'preparation');
  
  // 2. Tạo notification
  final notification = NotificationEntity(
    id: generateId(),
    userId: userId,
    type: NotificationType.appointmentReminder24h,
    title: template.title,
    body: template.instructions.join('\n• '),
    createdAt: DateTime.now(),
    deepLink: '/appointment-detail?...',
  );
  
  // 3. Gửi
  await notificationService.sendFCMNotification(userId, notification);
}
```

---

## 📊 Quản Lý & Cập Nhật Mẫu

### Thêm Mẫu Mới

```firestore
POST /notification_templates

Body:
{
  "departmentId": "new_department",
  "departmentName": "Khoa Mới",
  "templateType": "preparation",
  "title": "Hướng dẫn chuẩn bị",
  "message": "...",
  "instructions": [...]
}
```

### Cập Nhật Mẫu Hiện Tại

```firestore
PUT /notification_templates/{templateId}

Body:
{
  "message": "Nội dung cập nhật...",
  "instructions": [...]
}
```

### Vô Hiệu Hóa Mẫu

```firestore
PATCH /notification_templates/{templateId}

Body:
{
  "isActive": false
}
```

---

## ✅ Checklist Thiết Lập

- [ ] Tạo 6 mẫu chuẩn bị cho các khoa chính
- [ ] Tạo 6 mẫu nhắc tái khám
- [ ] Tạo luồng tự động gửi thông báo khi đặt lịch
- [ ] Kiểm tra scheduling đúng 24h trước
- [ ] Kiểm tra deep link hoạt động
- [ ] Test offline (local notifications)
- [ ] Admin panel để quản lý templates

---

## 📚 Ví Dụ Thực Tế

### Sơn 25 tuổi đặt lịch khám nội soi lúc 14:30 hôm 7/5

```
Timeline:
14:30 - Đặt lịch thành công
14:31 - Gửi thông báo xác nhận (FCM + Local)
14/5 09:00 - Gửi thông báo chuẩn bị từ template
15/5 09:00 - Gửi nhắc 24h
15/5 21:00 - Gửi nhắc 2h
16/5 08:00 - Gửi nhắc cuối (2h)
16/5 09:30 - Gửi thông báo "Khám xong"
```

---


