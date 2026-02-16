class RoleRequestModel {
  final String roleRequested;

  RoleRequestModel({required this.roleRequested});

  factory RoleRequestModel.fromJson(Map<String, dynamic> json) {
    return RoleRequestModel(roleRequested: json['roleRequested']);
  }

  Map<String, dynamic> toJson() {
    return {'roleRequested': roleRequested};
  }
}
