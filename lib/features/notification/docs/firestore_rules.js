rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() {
      return request.auth != null;
    }

    function isRecipient() {
      return signedIn() && (
        resource.data.userId == request.auth.uid ||
        resource.data.patientId == request.auth.uid ||
        resource.data.doctorId == request.auth.uid
      );
    }

    match /Notifications/{notificationId} {
      allow read: if isRecipient();
      allow create: if signedIn();
      allow update: if isRecipient()
        && request.resource.data.diff(resource.data).changedKeys()
          .hasOnly(['isRead', 'readAt', 'updatedAt']);
      allow delete: if isRecipient();
    }

    match /Users/{userId}/fcmTokens/{token} {
      allow read, write: if signedIn() && request.auth.uid == userId;
    }

    match /users/{userId}/fcmTokens/{token} {
      allow read, write: if signedIn() && request.auth.uid == userId;
    }

    match /notification_templates/{templateId} {
      allow read: if signedIn();
      allow write: if false;
    }
  }
}
