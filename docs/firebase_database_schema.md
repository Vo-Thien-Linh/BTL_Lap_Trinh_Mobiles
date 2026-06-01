# Firebase Database Schema

This schema is shared by the mobile app and the web/admin app.

## Core Rule

Use `users/{uid}` as the single account/profile collection for every login account.

- Patients are users with `role = "patient"`.
- Doctors are users with `role = "doctor"` and an extra professional profile in `Doctors`.
- Do not create or use `Users` or `patients` collections for new data.

## `users/{uid}`

Common account and identity fields for patients, doctors, and admins.

```js
{
  uid: string,
  email: string,
  fullName: string,
  phone: string,
  cccd: string,
  avatarUrl: string | null,
  gender: "male" | "female" | "other" | null,
  dateOfBirth: string | null, // yyyy-MM-dd
  role: "patient" | "doctor" | "admin",
  status: "active" | "inactive" | "blocked",
  emailVerified: boolean,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

Optional patient/profile extension fields currently supported by the mobile app:

```js
{
  healthInsuranceNumber: string | null,
  insuranceNumber: string | null,
  healthInsuranceStatus: "pending" | "verified" | "rejected" | "unverified" | null,
  healthInsuranceUpdatedAt: Timestamp | null,
  healthInsuranceVerifiedAt: Timestamp | null,
  bloodType: string | null,
  address: string | null,
  emergencyPhone: string | null,
  allergies: string[] | null,
  chronicConditions: string[] | null,
  weight: number | null,
  height: number | null,
  membership: string | null
}
```

## `Doctors/{doctorId}`

Professional profile for a doctor account.

```js
{
  userId: string, // references users/{uid}
  departmentId: string, // references Departments/{departmentId}
  specialization: string,
  licenseNumber: string,
  degree: string,
  yearsOfExperience: number,
  consultationFee: number,
  biography: string,
  isActive: boolean,
  verificationStatus: "pending" | "verified" | "rejected",
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

Doctor display data such as name, phone, avatar, gender, date of birth, email, and CCCD must be read from `users/{userId}`.

## `Departments/{departmentId}`

Department data. `rooms` is used by web/admin to manage examination rooms for the department.

```js
{
  departmentName: string,
  description: string,
  location: string,
  phone: string,
  rooms: string[],
  doctorCount: number,
  isActive: boolean,
  imageUrl: string | null, // optional; mobile auto-generates a visual when empty
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

Example:

```js
{
  departmentName: "Tim mach",
  description: "Khoa kham va dieu tri benh ly tim mach.",
  location: "Tang 2 - Khu A",
  phone: "02439990001",
  rooms: ["A201", "A202", "A203"],
  doctorCount: 8,
  isActive: true,
  imageUrl: null,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp()
}
```

Mobile does not require web/admin to upload a department image. If `imageUrl`
is empty, the app deterministically generates an icon and color set from
`departmentId + departmentName`, so newly created departments still have a
stable visual in the home, search, and booking screens.

## `DoctorSchedules/{scheduleId}`

Specific working schedule for a doctor. Appointments should store `scheduleId` to link back to this document.

```js
{
  doctorId: string, // references Doctors/{doctorId}
  userId: string, // optional denormalized users/{uid} for admin queries
  departmentId: string, // references Departments/{departmentId}
  shiftId: string, // references Shifts/{shiftId}
  scheduleDate: Timestamp,
  roomId: string | null,
  roomNumber: string | null,
  maxSlots: number,
  availableSlots: number,
  isActive: boolean,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

Mobile must only show schedules where `isActive = true`. It must not generate doctor schedules by itself.

## `health_insurances/{uid}`

Detailed health insurance data for a patient.

```js
{
  userId: string, // references users/{uid}
  emailAtSubmit: string | null,
  insuranceNumber: string,
  status: "pending" | "verified" | "rejected" | "unverified",
  verifiedAt: Timestamp | null,
  verifiedBy: string | null,
  rejectReason: string | null,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

Keep `users/{uid}.healthInsuranceNumber` as a quick display/cache field, but use `health_insurances/{uid}` for verification workflow details.

## `Appointments/{appointmentId}`

Appointment data. IDs point back to the normalized profile collections.

```js
{
  patientId: string, // references users/{uid}
  patientName: string,
  patientDOB: string | null,
  patientGender: string | null,
  insuranceNumber: string | null,
  doctorId: string, // references Doctors/{doctorId}
  doctorName: string,
  departmentId: string,
  appointmentDate: Timestamp,
  scheduleId: string | null, // references DoctorSchedules/{scheduleId}
  shiftId: string,
  queueNumber: number,
  roomNumber: string,
  symptoms: string | null,
  status: string,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

`patientName`, `patientDOB`, `patientGender`, `insuranceNumber`, and `doctorName` are snapshots at booking time.

Recommended appointment statuses:

- `pending`: created, awaiting payment/finalization in mobile.
- `confirmed`: booked successfully and waiting for examination.
- `calling`: doctor is calling the patient.
- `ongoing`: examination is in progress.
- `completed`: examination finished.
- `cancel_requested`: patient requested cancellation; admin approval is required.
- `cancelled`: cancellation approved.
- `no_show`: patient did not show up.

Patients may only request cancellation at least 24 hours before the appointment start time. Mobile sets `status = "cancel_requested"` and stores `cancelRequestedBy` / `cancelRequestedAt`; web/admin approves by changing the appointment to `cancelled` and should then return the slot to `DoctorSchedules.availableSlots`.

Doctors can mark a patient as absent from the queue by setting `status = "no_show"` and storing `noShowBy = "doctor"`, `noShowByUserId`, and `noShowAt`. This does not return `DoctorSchedules.availableSlots` automatically because the examination slot has already been held.

Appointment creation must run in a transaction:

1. Read `DoctorSchedules/{scheduleId}`.
2. Reject if the schedule does not exist, `isActive != true`, or `availableSlots <= 0`.
3. Reject if `doctorId`, `departmentId`, or `shiftId` does not match the selected schedule.
4. Create the appointment with a unique queue slot key, recommended document id: `${scheduleId}_${queueNumber}`.
5. Decrease `DoctorSchedules/{scheduleId}.availableSlots` by 1.

This prevents two patients from taking the same queue number in the same doctor schedule.

If web/admin changes room or shift after appointments exist, it must either block the change or update all related `Appointments` that have the same `scheduleId`.

## Web/Admin Doctor Creation Flow

When the web app creates a doctor:

1. Create a Firebase Auth account with email and password.
2. Use the Auth `uid` to create `users/{uid}` with `role = "doctor"`.
3. Create a document in `Doctors/{doctorId}` with `userId = uid`.
4. Use a batch/transaction or a trusted backend function so `users` and `Doctors` cannot become inconsistent.

Example payload:

```js
// users/{uid}
{
  uid,
  email: "doctor@example.com",
  fullName: "BS. Nguyen Van A",
  phone: "0901234567",
  cccd: "079095123456",
  avatarUrl: null,
  gender: "male",
  dateOfBirth: "1988-01-20",
  role: "doctor",
  status: "active",
  emailVerified: false,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp()
}

// Doctors/{doctorId}
{
  userId: uid,
  departmentId: "dept_cardio",
  specialization: "Tim mach",
  licenseNumber: "CCHN-123456",
  degree: "ThS.BS",
  yearsOfExperience: 10,
  consultationFee: 300000,
  biography: "Bac si chuyen khoa tim mach.",
  isActive: true,
  verificationStatus: "verified",
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp()
}
```

## Required Indexes

Recommended Firestore queries:

- `Doctors`: `departmentId == ...`, `isActive == true`
- `Doctors`: `userId == ...`
- `Appointments`: `patientId == ...`, `appointmentDate desc`
- `Appointments`: `doctorId == ...`, `appointmentDate asc`
- `Appointments`: `doctorId == ...`, `appointmentDate == ...`, `shiftId == ...`
- `health_insurances`: `status == ...`, `updatedAt desc`
