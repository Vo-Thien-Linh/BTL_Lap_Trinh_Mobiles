part of 'notification_bloc.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationSuccess extends NotificationState {
  final String message;
  const NotificationSuccess({required this.message});
  @override
  List<Object?> get props => [message];
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError({required this.message});
  @override
  List<Object?> get props => [message];
}

class NotificationsLoaded extends NotificationState {
  final List<NotificationEntity> notifications;
  const NotificationsLoaded({required this.notifications});
  @override
  List<Object?> get props => [notifications];
}

class TemplatesLoaded extends NotificationState {
  final List<NotificationTemplateEntity> templates;
  const TemplatesLoaded({required this.templates});
  @override
  List<Object?> get props => [templates];
}
