# Firestore schema summary

This document summarizes the Firestore collections that the system uses or references.
It mixes:
- collections visible in your Firebase console
- collections referenced in Flutter code
- subcollections used under `users`

## 1. Main collections

### `Doctors`
Current Firebase document example from your screenshot:
- `biography`
- `consultationFee`
- `createdAt`
- `degree`
- `departmentId`
- `doctorCode`
- `isActive`
- `licenseNumber`
- `specialization`
- `updatedAt`
- `userId`
- `verificationStatus`
- `yearsOfExperience`

Recommended meaning:
- `doctorCode`: unique doctor code, used for lookup and display
- `userId`: links to `users/{uid}`
- `departmentId`: links to `Departments/{id}`
- `degree`: doctor title/degree
- `specialization`: specialty
- `licenseNumber`: medical license number
- `biography`: profile description
- `consultationFee`: consultation price
- `yearsOfExperience`: experience years
- `verificationStatus`: `pending` / `verified` / `rejected`
- `isActive`: active/inactive flag
- `createdAt`, `updatedAt`: timestamps

Important code mismatch:
- Flutter code still expects some fallback fields like `name`, `fullName`, `departmentName`.
- In Firebase, the real source of doctor identity should be `userId -> users/{uid}`.

### `Departments`
Fields used by code:
- `departmentName`
- `description`
- `location`
- `phone`
- `rooms`
- `doctorCount`
- `isActive`
- `imageUrl`

Recommended meaning:
- department master data for clinic/ward/specialty grouping

### `Appointments`
Fields used by code and Firestore models:
- `patientId`
- `patientDOB`
- `patientGender`
- `patientName`
- `doctorId`
- `doctorName`
- `departmentId`
- `departmentName`
- `appointmentDate`
- `scheduleId`
- `shiftId`
- `timeSlot`
- `queueNumber`
- `roomNumber`
- `consultationFee`
- `insuranceNumber`
- `symptoms`
- `diagnosis`
- `physicalExam`
- `treatment`
- `notes`
- `prescription`
- `labResults`
- `vitals`
- `status`
- `paymentMethod`
- `createdAt`
- `updatedAt`
- `appointmentNumber` is also used in lower-level appointment code

Recommended meaning:
- full appointment record, including booking, queue, and consultation results

### `Invoices`
Fields used by code:
- `appointmentId`
- `patientId`
- `expenseType`
- `serviceContent`
- `doctorName`
- `departmentName`
- `totalAmount`
- `discountAmount`
- `amount`
- `status`
- `createdAt`
- `paymentDate`

Recommended meaning:
- billing record linked to one appointment

### `Payments`
Fields used by code:
- `invoiceId`
- `appointmentId`
- `patientId`
- `amount`
- `status`
- `method`
- `createdAt`
- `paymentDate`

Recommended meaning:
- payment transaction history

### `DoctorSchedules`
Fields used by code:
- `doctorId`
- `departmentId`
- `shiftId`
- `scheduleDate`
- `roomId`
- `roomNumber`
- `maxSlots`
- `availableSlots`
- `isActive`

Recommended meaning:
- doctor schedule by day and shift

### `Shifts`
Fields used by code:
- `name`
- `startTime`
- `endTime`
- `maxSlots`

Recommended meaning:
- shift master data such as morning/afternoon/evening

### `Notifications`
Fields used by code:
- `id`
- `userId`
- `patientId`
- `doctorId`
- `recipientRole`
- `type`
- `category`
- `title`
- `body`
- `content` (legacy compatibility)
- `data`
- `createdAt`
- `timestamp` (legacy compatibility)
- `scheduledAt`
- `isRead`
- `deepLink`
- `sendPush`
- `sendEmail`
- `email`
- `deliveryStatus`
- `deliveredAt`
- `updatedAt`
- `readAt`
- `cancelledAt`

Recommended meaning:
- notification inbox and delivery state

### `notification_templates`
Fields used by code:
- `id`
- `departmentId`
- `departmentName`
- `templateType`
- `title`
- `message`
- `instructions`
- `isActive`
- `updatedAt`

Recommended meaning:
- reusable notification templates by department

### `health_insurances`
Fields used by code:
- `userId`
- `emailAtSubmit`
- `insuranceNumber`
- `status`
- `createdAt`
- `updatedAt`
- `verifiedAt`
- `verifiedBy`
- `rejectReason`

Recommended meaning:
- insurance verification record per user

### `users`
Fields used by code:
- `uid`
- `username`
- `email`
- `phone`
- `fullName`
- `cccd`
- `role`
- `status`
- `emailVerified`
- `createdAt`
- `updatedAt`
- `dateOfBirth`
- `gender`
- `healthInsuranceNumber`
- `bloodType`
- `address`
- `emergencyPhone`
- `avatarUrl`
- `allergies`
- `chronicConditions`
- `weight`
- `height`
- `membership`
- `phoneVerified`
- `insuranceNumber`
- `healthInsuranceStatus`
- `healthInsuranceUpdatedAt`
- `healthInsuranceVerifiedAt`

Recommended meaning:
- primary user profile table for patients, doctors, and admins

### `patients`
Used in code only as a helper lookup collection.

What the code currently assumes:
- a patient document must at least expose a readable name field
- the lookup logic checks `fullName`, `name`, and `username`

Recommended schema if you keep this collection:
- `id`
- `fullName`
- `name`
- `username`
- `phone`
- `gender`
- `dateOfBirth`
- `address`
- `avatarUrl`
- `healthInsuranceNumber`
- `allergies`
- `chronicConditions`

Note:
- the app already treats `users` as the primary person store, so `patients` looks like a secondary/legacy collection.

### `Counters`
Visible in Firebase console, but not referenced in the Flutter code.

Likely purpose:
- auto-numbering / sequence counters

Recommended schema:
- `key`
- `value`
- `prefix`
- `updatedAt`

If you want to keep it strict, confirm the exact fields directly in the console.

## 2. Subcollections

### `users/{uid}/FamilyMembers`
Used by the profile page.

Likely fields:
- `id`
- `fullName`
- `relationship`
- `gender`
- `dateOfBirth`
- `phone`
- `address`
- `healthInsuranceNumber`
- `notes`

### `users/{uid}/fcmTokens`
Used for push notification tokens.

Fields used by code:
- `token`
- `userId`
- `role`
- `email`
- `platformUpdatedAt`
- `active`

## 3. Extra code-only reference

### `ServiceRequests`
Referenced by doctor queue UI, but not shown in your screenshot.

Expected purpose:
- service request queue for doctors

No dedicated model is defined in code, so the exact schema still needs confirmation from the console.

## 4. Practical notes

- Firestore is NoSQL, but for system design you can treat each collection like a table.
- Field names are case-sensitive in Firestore.
- Your current database mixes `Doctors`, `Appointments`, `Notifications` with lowercase collections like `users` and `health_insurances`, so keep the exact casing consistent.
- The most important relationship in this system is:
  - `Doctors.userId -> users.uid`
  - `Doctors.departmentId -> Departments.id`
  - `Appointments.doctorId -> Doctors.id`
  - `Appointments.patientId -> users.uid`

