class Event {
  final String id;
  final String title;
  final String? tagline;
  final String? description;
  final String? bannerUrl;
  final String? category;
  final DateTime startDate;
  final DateTime? endDate;
  final String organizerName;
  final String? contactPerson;
  final String? registrationFormUrl;
  final String accessCode;
  final String status;
  final String? documentationUrl;
  final String? certificateUrl;
  final String createdBy;
  final String? rejectionReason;

  Event({
    required this.id,
    required this.title,
    this.tagline,
    this.description,
    this.bannerUrl,
    this.category,
    required this.startDate,
    this.endDate,
    required this.organizerName,
    this.contactPerson,
    this.registrationFormUrl,
    required this.accessCode,
    required this.status,
    this.documentationUrl,
    this.certificateUrl,
    required this.createdBy,
    this.rejectionReason,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      tagline: json['tagline'],
      description: json['description'],
      bannerUrl: json['banner_url'],
      category: json['category'],
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      organizerName: json['organizer_name'],
      contactPerson: json['contact_person'],
      registrationFormUrl: json['registration_form_url'],
      accessCode: json['access_code'],
      status: json['status'],
      documentationUrl: json['documentation_url'],
      certificateUrl: json['certificate_url'],
      createdBy: json['created_by'],
      rejectionReason: json['rejection_reason'],
    );
  }
  Event copyWith({
    String? title,
    String? tagline,
    String? description,
    String? bannerUrl,
    String? organizerName,
    String? contactPerson,
  }) {
    return Event(
      id: id,
      title: title ?? this.title,
      tagline: tagline ?? this.tagline,
      description: description ?? this.description,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      category: category,
      startDate: startDate,
      endDate: endDate,
      organizerName: organizerName ?? this.organizerName,
      contactPerson: contactPerson ?? this.contactPerson,
      registrationFormUrl: registrationFormUrl,
      accessCode: accessCode,
      status: status,
      documentationUrl: documentationUrl,
      certificateUrl: certificateUrl,
      createdBy: createdBy,
      rejectionReason: rejectionReason,
    );
  }
}