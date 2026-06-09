# Bệnh viện LPHV - Hospital Booking App

Ứng dụng Flutter đặt lịch khám bệnh cho bệnh nhân và hỗ trợ bác sĩ xử lý hàng đợi, lịch khám, hồ sơ y tế, kê đơn, hóa đơn và thanh toán.

## Công nghệ sử dụng

- Flutter, Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging và local notifications
- BLoC / Cubit cho quản lý state
- payOS thông qua backend Web Admin
- Gemini API cho chatbot hỗ trợ hỏi đáp

## Phiên bản Flutter/Dart

- Dart SDK yêu cầu trong `pubspec.yaml`: `^3.11.1`
- Flutter: dùng kênh `stable`, phiên bản tương thích Dart 3.11.x

Kiểm tra môi trường local:

```bash
flutter doctor
flutter --version
dart --version
```

## Package chính

Các dependency chính được khai báo trong `pubspec.yaml`:

- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`
- `flutter_bloc`, `bloc`, `equatable`, `get_it`, `dartz`
- `shared_preferences`
- `intl`, `flutter_localizations`, `timezone`
- `image_picker`
- `http`, `url_launcher`
- `fl_chart`, `qr_flutter`, `table_calendar`, `share_plus`
- `flutter_local_notifications`
- `google_generative_ai`
- `dvhcvn`

Cài dependency:

```bash
flutter pub get
```

## Cài đặt và chạy project

1. Cài Flutter SDK, Dart SDK, Android Studio và Android Emulator.
2. Clone project từ GitHub.
3. Mở terminal tại thư mục project Flutter:

```bash
cd BTL_Lap_Trinh_Mobiles
```

4. Cài package:

```bash
flutter pub get
```

5. Kiểm tra Firebase config:

- Android cần có file `android/app/google-services.json`.
- Firebase project cần bật Authentication, Firestore Database, Storage và Cloud Messaging nếu dùng thông báo.
- App đang gọi `Firebase.initializeApp()` bằng cấu hình native của từng platform.

6. Chạy app:

```bash
flutter run
```

## Chạy thanh toán payOS

Chạy ngrok theo câu lệnh: ngrok http 5071
Ngrok sẽ hiện URL dạng https://xxxxx.ngrok-free.dev (Ví dụ :https://prelaw-rental-pug.ngrok-free.dev)
copy https://xxxxx.ngrok-free.dev (đường dẫn này tuy vào máy mà sẽ hơi khác nhau)

chạy flutter run --dart-define=PAYMENT_API_BASE_URL=https://xxxxx.ngrok-free.dev
thay thế đường dẫn https://xxxxx.ngrok-free.dev theo máy
## Cấu hình AI chatbot

Chatbot dùng Gemini API. 

Hiện app đọc key trong `lib/constants.dart`. Thay thế geminiApiKey bằng "AQ.Ab8RN6JOQqgYg2BBgyqoLwqR54oVxtDdnoHMwEXc7_2YgG7Otg"

## Tài khoản test

------------------------------------------------------------------
| Tài khoản                     | Mật khẩu     | Loại            |
|-------------------------------|--------------|-----------------|
| `phivu6605@gmail.com`         | 123456a      | Bệnh nhân       |
| `tranthib@gmail.com`          | 123456a      | Bác sĩ          |   
| `vothienlinh2@gmail.com`      | 123456a      | Amin (web)      |
| `nguyenquocviet9a8@gmail.com` | Viet2005     | nhân viên (web) |
------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------------------------------------
| Service           | Chức năng                                                                                                                              |
| ------------------| ---------------------------------------------------------------------------------------------------------------------------------------|
| `webhook-service` | Nhận webhook từ Facebook, xác thực request và publish event vào Kafka topic `raw_events`.                                              |
| `core-service`    | Consume `raw_events`, phát hiện spam, phân loại intent/sentiment, quyết định reply hoặc moderation, lưu comment vào SQL Server.        |
| `api-service`     | Consume `reply_commands`, `moderation_commands`, `send_retry`; gọi Facebook Graph API; lưu idempotency; publish lỗi vào `send_failed`. |
| `retry-service`   | Consume `send_failed`, retry theo exponential backoff, publish lại vào `send_retry`, hoặc đưa vào `dead_letter` khi quá số lần retry.  |
--------------------------------------------------------------------------------------------------------------------------------------------------------------

Điều kiện để bác sĩ đăng nhập app:

- `users/{uid}.role = "doctor"`
- `users/{uid}.status = "active"`
- `Doctors/{doctorId}.userId = uid`
- `Doctors/{doctorId}.isActive = true`
- `Doctors/{doctorId}.verificationStatus = "verified"`

## Firestore collections chính

App đang đọc/ghi các collection chính:

- `users`: thông tin dùng chung cho bệnh nhân và bác sĩ
- `Doctors`: thông tin chuyên môn của bác sĩ
- `Departments`: chuyên khoa, phòng thuộc chuyên khoa
- `DoctorSchedules`: lịch làm việc của bác sĩ do Web Admin tạo
- `Appointments`: lịch hẹn khám, có `scheduleId`, `doctorId`, `patientId`, `departmentId`, `shiftId`, `appointmentDate`, `queueNumber`, `roomNumber`
- `Patients` hoặc `patients`: hồ sơ mở rộng nếu dữ liệu cũ còn dùng
- `health_insurances`: thông tin bảo hiểm y tế
- `Invoices`, `Payments`: hóa đơn và thanh toán
- `MedicalRecords`, `Prescriptions`, `LabOrders`, `Medicines`: kết quả khám, đơn thuốc, xét nghiệm và kho thuốc
- `Notifications`, `notification_templates`: thông báo

## Cấu hình Firebase cho giảng viên

Project dùng Firebase nên khi nộp/chạy cần có cấu hình Firebase hợp lệ.

File cấu hình hiện có trong repo:

- Android: `android/app/google-services.json`\

Nếu không upload file cấu hình Firebase, người chạy cần tự cấu hình:

1. Tạo project trên Firebase Console.
2. Bật Authentication, chọn Email/Password.
3. Bật Cloud Firestore.
4. Bật Firebase Storage nếu dùng upload ảnh đại diện.
5. Bật Cloud Messaging nếu test thông báo đẩy.
6. Thêm Android app với package name đúng theo project.
7. Tải `google-services.json` và đặt vào `android/app/google-services.json`.
8. Nếu chạy iOS, thêm iOS app trong Firebase, tải `GoogleService-Info.plist` và đặt vào `ios/Runner/GoogleService-Info.plist`.
9. Publish Firestore Rules từ file `firestore.rules`.
10. Publish Storage Rules từ file `storage.rules`.

Các document mẫu tối thiểu cần có để app hoạt động:

```js
// users/{uid}
{
  uid: "patient_uid",
  email: "patient@example.com",
  fullName: "Nguyen Van A",
  phone: "0900000000",
  cccd: "079000000001",
  avatarUrl: null,
  gender: "male",
  dateOfBirth: "2000-01-01",
  role: "patient",
  status: "active",
  emailVerified: true,
  createdAt: Timestamp,
  updatedAt: Timestamp
}

// users/{doctorUid}
{
  uid: "doctor_uid",
  email: "doctor@example.com",
  fullName: "BS. Tran Thi B",
  phone: "0911111111",
  cccd: "079000000002",
  avatarUrl: null,
  gender: "female",
  dateOfBirth: "1985-01-01",
  role: "doctor",
  status: "active",
  emailVerified: false,
  createdAt: Timestamp,
  updatedAt: Timestamp
}

// Departments/{departmentId}
{
  departmentName: "Tai Mũi Họng",
  description: "Khám và điều trị bệnh tai mũi họng.",
  location: "Tầng 2 - Khu A",
  phone: "02439990001",
  rooms: ["A201", "A202"],
  doctorCount: 1,
  isActive: true,
  imageUrl: null,
  createdAt: Timestamp,
  updatedAt: Timestamp
}

// Doctors/{doctorId}
{
  userId: "doctor_uid",
  departmentId: "departmentId",
  specialization: "Tai Mũi Họng",
  licenseNumber: "CCHN-123456",
  degree: "ThS.BS",
  yearsOfExperience: 10,
  consultationFee: 200000,
  biography: "Bác sĩ chuyên khoa tai mũi họng.",
  isActive: true,
  verificationStatus: "verified",
  createdAt: Timestamp,
  updatedAt: Timestamp
}

// Shifts/{shiftId}
{
  name: "Ca sáng",
  startTime: "07:30",
  endTime: "11:30",
  maxSlots: 20,
  isActive: true
}

// DoctorSchedules/{scheduleId}
{
  doctorId: "doctorId",
  userId: "doctor_uid",
  departmentId: "departmentId",
  shiftId: "shiftId",
  scheduleDate: Timestamp,
  roomId: "A201",
  roomNumber: "A201",
  maxSlots: 20,
  availableSlots: 20,
  isActive: true,
  createdAt: Timestamp,
  updatedAt: Timestamp
}

// Medicines/{medicineId}
{
  medicineCode: "TH0001",
  name: "Paracetamol",
  group: "Giảm đau",
  strength: "500",
  unit: "viên",
  unitPrice: 10000,
  quantity: 1000,
  lowStockThreshold: 100,
  isActive: true,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

## Lưu ý nghiệp vụ

- Mobile không tự sinh lịch làm việc bác sĩ. App chỉ đọc `DoctorSchedules` có `isActive = true`.
- Khi bệnh nhân đặt lịch, app phải ghi `scheduleId` để liên kết lịch hẹn với ca làm việc cụ thể.
- `queueNumber` và `availableSlots` cần xử lý bằng transaction để tránh trùng số thứ tự và vượt slot.
- Bệnh nhân được yêu cầu hủy lịch trước giờ khám ít nhất 24 giờ. App chỉ tạo yêu cầu hủy, Web Admin duyệt hủy.
- Khi bác sĩ khám xong, lịch hẹn chuyển sang trạng thái đã khám/completed, không cần nhân viên xác nhận lại.
- Thanh toán trên app chỉ dùng chuyển khoản/payOS. Tiền mặt hoặc duyệt thủ công, nếu có, thuộc Web Admin.
- Backend/Web Admin phải thống nhất schema với app, đặc biệt các collection `Appointments`, `Payments`, `Invoices`, `DoctorSchedules`, `MedicalRecords`, `Prescriptions`.

