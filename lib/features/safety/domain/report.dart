import '../../profile/domain/profile.dart';

enum ReportReason {
  spam('spam'),
  scam('scam'),
  inappropriate('inappropriate'),
  harassment('harassment'),
  counterfeit('counterfeit'),
  other('other');

  const ReportReason(this.value);
  final String value;

  static ReportReason fromValue(String v) =>
      values.firstWhere((e) => e.value == v, orElse: () => other);
}

class Report {
  const Report({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    this.details,
    this.createdAt,
    this.reporter,
  });

  final String id;
  final String reporterId;
  final String targetType;
  final String targetId;
  final ReportReason reason;
  final String status;
  final String? details;
  final DateTime? createdAt;
  final Profile? reporter;

  bool get isListing => targetType == 'listing';

  factory Report.fromJson(Map<String, dynamic> json) {
    final reporter = json['reporter'];
    final created = json['created_at'];
    return Report(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      targetType: json['target_type'] as String,
      targetId: json['target_id'] as String,
      reason: ReportReason.fromValue(json['reason'] as String),
      status: json['status'] as String,
      details: json['details'] as String?,
      createdAt: created is String ? DateTime.tryParse(created) : null,
      reporter: reporter is Map<String, dynamic> ? Profile.fromJson(reporter) : null,
    );
  }
}
