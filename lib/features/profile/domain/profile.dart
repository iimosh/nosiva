import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

/// A Nosiva user profile (1:1 with `auth.users` via the `profiles` table).
@freezed
class Profile with _$Profile {
  const Profile._();

  const factory Profile({
    required String id,
    required String username,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    String? bio,
    String? location,
    @Default(<String>[]) @JsonKey(name: 'vibe_tags') List<String> vibeTags,
    @Default(0) @JsonKey(name: 'follower_count') int followerCount,
    @Default(0) @JsonKey(name: 'following_count') int followingCount,
    @Default(0.0) @JsonKey(name: 'rating_avg') double ratingAvg,
    @Default(0) @JsonKey(name: 'rating_count') int ratingCount,
    @Default(false) @JsonKey(name: 'onboarded') bool onboarded,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);

  String get handle => '@$username';
  String get nameOrHandle => displayName?.isNotEmpty == true ? displayName! : handle;
}
