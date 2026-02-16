class ChangePasswordModel {
  final String oldPassword;
  final String newPassword;

  ChangePasswordModel({required this.oldPassword, required this.newPassword});

  factory ChangePasswordModel.fromJson(Map<String, dynamic> json) {
    return ChangePasswordModel(
      oldPassword: json['currentPassword'],
      newPassword: json['newPassword'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'currentPassword': oldPassword, 'newPassword': newPassword};
  }
}
