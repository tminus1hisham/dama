class CertificateModel {
  final String id;
  final String certificateNumber;
  final String trainingId;
  final String trainingTitle;
  final String userId;
  final String userName;
  final String issuerName;
  final DateTime issueDate;
  final DateTime completionDate;
  final int trainingHours;
  final String instructorName;
  final String qrCode;
  final String status;

  CertificateModel({
    required this.id,
    required this.certificateNumber,
    required this.trainingId,
    required this.trainingTitle,
    required this.userId,
    required this.userName,
    required this.issuerName,
    required this.issueDate,
    required this.completionDate,
    required this.trainingHours,
    required this.instructorName,
    required this.qrCode,
    required this.status,
  });

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    // Extract metadata if it exists
    final metadata = json['metadata'] as Map<String, dynamic>? ?? {};

    // Extract userId - it could be a string or an object
    String userIdValue = '';
    String userNameValue = '';

    if (json['userId'] is String) {
      userIdValue = json['userId'];
    } else if (json['userId'] is Map<String, dynamic>) {
      final userData = json['userId'] as Map<String, dynamic>;
      userIdValue = userData['_id'] ?? '';

      // Build userName from firstName and lastName if available
      final firstName = userData['firstName'] ?? '';
      final lastName = userData['lastName'] ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        userNameValue = '$firstName $lastName'.trim();
      }
    }

    // If userName is still empty, try metadata or json directly
    if (userNameValue.isEmpty) {
      userNameValue = metadata['userName'] ?? json['userName'] ?? '';
    }

    // If still empty, try to get from user data in metadata
    if (userNameValue.isEmpty && metadata['user'] is Map<String, dynamic>) {
      final userData = metadata['user'] as Map<String, dynamic>;
      final firstName = userData['firstName'] ?? '';
      final lastName = userData['lastName'] ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        userNameValue = '$firstName $lastName'.trim();
      }
    }

    // Extract trainingId - it could be a string or an object
    String trainingIdValue = '';
    if (json['trainingId'] is String) {
      trainingIdValue = json['trainingId'];
    } else if (json['trainingId'] is Map<String, dynamic>) {
      trainingIdValue = json['trainingId']['_id'] ?? '';
    }

    return CertificateModel(
      id: json['_id'] ?? json['id'] ?? '',
      certificateNumber: json['certificateNumber'] ?? '',
      trainingId: trainingIdValue,
      trainingTitle: metadata['trainingTitle'] ?? json['trainingTitle'] ?? '',
      userId: userIdValue,
      userName: userNameValue,
      issuerName: json['issuerName'] ?? 'DAMA KENYA',
      issueDate: DateTime.tryParse(json['issueDate'] ?? '') ?? DateTime.now(),
      completionDate:
          DateTime.tryParse(json['completionDate'] ?? '') ?? DateTime.now(),
      trainingHours: json['trainingHours'] ?? 0,
      instructorName: metadata['trainerName'] ?? json['instructorName'] ?? '',
      qrCode: json['qrCode'] ?? json['qrCodeData'] ?? '',
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'certificateNumber': certificateNumber,
      'trainingId': trainingId,
      'trainingTitle': trainingTitle,
      'userId': userId,
      'userName': userName,
      'issuerName': issuerName,
      'issueDate': issueDate.toIso8601String(),
      'completionDate': completionDate.toIso8601String(),
      'trainingHours': trainingHours,
      'instructorName': instructorName,
      'qrCode': qrCode,
      'status': status,
    };
  }
}

class CertificateGenerationRequest {
  final String trainingId;
  final String userId;

  CertificateGenerationRequest({
    required this.trainingId,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {'trainingId': trainingId, 'userId': userId};
  }
}

class CertificateConfig {
  final String template;
  final String issuerName;
  final int minimumAttendance;
  final List<String> criteria;

  CertificateConfig({
    required this.template,
    required this.issuerName,
    required this.minimumAttendance,
    required this.criteria,
  });

  factory CertificateConfig.fromJson(Map<String, dynamic> json) {
    return CertificateConfig(
      template: json['template'] ?? 'default',
      issuerName: json['issuerName'] ?? 'DAMA KENYA',
      minimumAttendance: json['minimumAttendance'] ?? 80,
      criteria: List<String>.from(json['criteria'] ?? []),
    );
  }
}
