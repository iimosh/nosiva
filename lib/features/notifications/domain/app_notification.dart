import 'package:freezed_annotation/freezed_annotation.dart';

import '../../listings/domain/listing_enums.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

@freezed
class AppNotification with _$AppNotification {
  const AppNotification._();

  const factory AppNotification({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String type,
    required String title,
    String? body,
    @JsonKey(name: 'data') Map<String, dynamic>? data,
    @Default(false) bool read,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  NotificationType get typeEnum => NotificationType.fromValue(type);
}
