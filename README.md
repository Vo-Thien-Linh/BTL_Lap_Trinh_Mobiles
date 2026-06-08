# Bệnh viện LPHV - Hospital Booking App

![Flutter](https://img.shields.io/badge/Flutter-Stable-blue)
![Dart](https://img.shields.io/badge/Dart-3.11.x-0175C2)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20Storage-orange)
![State](https://img.shields.io/badge/State-BLoC%20%2F%20Cubit-purple)
![Payment](https://img.shields.io/badge/Payment-payOS%20via%20Backend-green)
![Platform](https://img.shields.io/badge/Platform-Android-lightgrey)
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

App Flutter không giữ secret key payOS. App gọi backend Web Admin để tạo link thanh toán.

Backend cần chạy ở port `5071`:

```bash
dotnet run --urls http://0.0.0.0:5071
```

Khi chạy bằng Android Emulator, app mặc định gọi backend qua:

```text
http://10.0.2.2:5071
```

Nếu chạy trên điện thoại thật hoặc cần callback/webhook public, dùng ngrok:

```bash
ngrok http 5071
flutter run --dart-define=PAYMENT_API_BASE_URL=https://your-ngrok-url.ngrok-free.app
```

Nếu ngrok đổi URL, cần chạy lại app với URL mới.

## Cấu hình AI chatbot

Chatbot dùng Gemini API. Không nên commit API key thật lên GitHub.

Hiện app đọc key trong `lib/constants.dart`. Trước khi public/nộp GitHub, nên đổi key thật về placeholder hoặc chuyển sang cấu hình an toàn hơn như `--dart-define`, backend proxy hoặc file cấu hình không commit.

## Tài khoản test

Source không cấu hình sẵn tài khoản test cố định.

- Bệnh nhân: tạo tài khoản trực tiếp từ màn đăng ký của app.
- Bác sĩ: tài khoản nội bộ do Web Admin tạo bằng Firebase Auth, sau đó tạo `users/{uid}` và `Doctors/{doctorId}` tương ứng.

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

## Lưu ý nghiệp vụ

- Mobile không tự sinh lịch làm việc bác sĩ. App chỉ đọc `DoctorSchedules` có `isActive = true`.
- Khi bệnh nhân đặt lịch, app phải ghi `scheduleId` để liên kết lịch hẹn với ca làm việc cụ thể.
- `queueNumber` và `availableSlots` cần xử lý bằng transaction để tránh trùng số thứ tự và vượt slot.
- Bệnh nhân được yêu cầu hủy lịch trước giờ khám ít nhất 24 giờ. App chỉ tạo yêu cầu hủy, Web Admin duyệt hủy.
- Khi bác sĩ khám xong, lịch hẹn chuyển sang trạng thái đã khám/completed, không cần nhân viên xác nhận lại.
- Thanh toán trên app chỉ dùng chuyển khoản/payOS. Tiền mặt hoặc duyệt thủ công, nếu có, thuộc Web Admin.
- Backend/Web Admin phải thống nhất schema với app, đặc biệt các collection `Appointments`, `Payments`, `Invoices`, `DoctorSchedules`, `MedicalRecords`, `Prescriptions`.

## Kiểm tra trước khi push

Chạy phân tích code:

```bash
flutter analyze
```

Nếu chỉ muốn kiểm tra lỗi nghiêm trọng và bỏ qua warning/info:

```bash
flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings
```

Không commit các secret key như Gemini API key, payOS client id, checksum key hoặc secret key lên GitHub.
