## Trang Chủ (Home Screen) - Hướng Dẫn Chi Tiết

### 📋 Chức Năng Chính

Trang chủ của ứng dụng quản lý lịch khám bệnh cung cấp:

1. **Greeting Header** - Lời chào thân thiện dựa trên giờ trong ngày
2. **Quick Actions** - 4 nút thao tác nhanh:
   - 📅 Đặt lịch mới
   - 📜 Xem lịch sử khám
   - 👤 Hồ sơ cá nhân
   - ⚙️ Cài đặt
3. **Upcoming Appointments** - Danh sách lịch khám sắp tới với:
   - Tên bác sĩ
   - Chuyên khoa
   - Ngày/ giờ khám
   - Trạng thái (Sắp tới, Hoàn thành, Hủy)

### 🏗️ Cấu Trúc Clean Architecture

```
lib/features/home/
├── data/
│   ├── datasources/
│   │   └── home_local_datasource.dart    # Lấy dữ liệu (mock)
│   ├── models/
│   │   └── appointment_model.dart        # Model dữ liệu
│   └── repositories/
│       └── home_repository_impl.dart     # Implement repository
├── domain/
│   ├── entities/
│   │   └── appointment_entity.dart       # Entity kinh doanh
│   ├── repositories/
│   │   └── home_repository.dart          # Abstract repository
│   └── usecases/
│       └── get_appointments_usecase.dart # Business logic
└── presentation/
    ├── bloc/
    │   ├── home_bloc.dart                # BLoC state management
    │   ├── home_event.dart               # Events
    │   └── home_state.dart               # States
    ├── pages/
    │   └── home_screen.dart (trong screens/)
    └── widgets/
        ├── appointment_card.dart          # Card hiển thị lịch
        ├── home_greeting_header.dart      # Header greeting
        └── quick_action_button.dart       # Button thao tác nhanh
```

### 📁 Tệp Đã Tạo

#### Data Layer
- `lib/features/home/data/models/appointment_model.dart` - Model cho Appointment
- `lib/features/home/data/datasources/home_local_datasource.dart` - Mock data source
- `lib/features/home/data/repositories/home_repository_impl.dart` - Repository impl

#### Domain Layer
- `lib/features/home/domain/entities/appointment_entity.dart` - Entity
- `lib/features/home/domain/repositories/home_repository.dart` - Abstract repo
- `lib/features/home/domain/usecases/get_appointments_usecase.dart` - Use case

#### Presentation Layer
- `lib/features/home/presentation/bloc/home_bloc.dart` - BLoC
- `lib/features/home/presentation/bloc/home_event.dart` - Events
- `lib/features/home/presentation/bloc/home_state.dart` - States
- `lib/features/home/presentation/widgets/appointment_card.dart` - Appointment widget
- `lib/features/home/presentation/widgets/quick_action_button.dart` - Quick action widget
- `lib/features/home/presentation/widgets/home_greeting_header.dart` - Header widget
- `lib/features/home/screens/home_screen.dart` - Home screen (updated)

#### Infrastructure
- `lib/config/service_locator.dart` - Dependency Injection setup

### 🔧 Cách Sử Dụng

#### 1. Thêm Dependencies (đã cập nhật pubspec.yaml)
```yaml
dependencies:
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  intl: ^0.19.0
  get_it: ^7.6.0
```

Chạy: `flutter pub get`

#### 2. Khởi tạo BLoC trong main.dart (đã cập nhật)
HomeBloc được khởi tạo tự động qua service_locator với GetIt

#### 3. Sử dụng trong HomeScreen
- BLoC tự động fetch appointments khi initState
- Hiển thị loading/error/loaded states
- Refresh khi kéo xuống

### 🎨 Giao Diện Design

**Màu Sắc:**
- Primary Blue: `#8ECDF8` - Các nút & icons
- Primary Dark: `#5FB4F2` - Các nút chính
- Background: `#F7FCFF` - Nền mặc định
- Secondary: `#EAF7FF` - Nền thứ cấp
- Success: `#27AE60` - Trạng thái hoàn thành
- Error: `#E74C3C` - Trạng thái hủy

**Components:**
- Gradient background (top to bottom)
- Rounded corners (16dp) trên cards
- Shadow soft (blur 12, offset 4)
- Icons rounded style

### 🚀 Nâng Cấp Tiếp Theo

1. **Kết nối API thực:**
   - Thay `HomeLocalDatasourceImpl` bằng remote datasource
   - Sử dụng Dio để gọi API

2. **Thêm chức năng:**
   - Tap appointment card → đi tới chi tiết
   - Tap quick action buttons → navigate tới features tương ứng
   - Thêm pagination/infinite scroll nếu có nhiều lịch

3. **State Management nâng cao:**
   - Sử dụng BLoC cho mỗi quick action
   - Caching data với Hive

4. **Testing:**
   - Unit tests cho usecases
   - Widget tests cho presentation
   - BLoC tests

### 📝 Mock Data

Hiện tại, mock data được cấu hình trong `home_local_datasource.dart` với:
- 3 lịch khám mẫu
- Trạng thái: "upcoming" (2) và "completed" (1)
- Ngày/giờ và thông tin bác sĩ mẫu

Để thay đổi mock data, chỉnh sửa `mockAppointments` trong file datasource.

### ✅ Checklist Hoàn Thành

- ✅ Tạo cấu trúc Clean Architecture cho Home
- ✅ Tạo BLoC for state management
- ✅ Tạo custom widgets (appointment card, quick actions, header)
- ✅ Hiển thị mock data appointments
- ✅ Tích hợp refresh indicator
- ✅ Handle loading/error/loaded states
- ✅ Setup dependency injection (GetIt)
- ✅ Database routing & BloC provider setup
