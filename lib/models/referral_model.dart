import 'dart:convert';
import 'package:flutter/material.dart';

class ReferralModel {
  final String? id;
  final String? referralCode;
  final int? totalReferrals;
  final int? successfulReferrals;
  final List<ReferralDetail>? referrals;
  final String? referralLink;

  ReferralModel({
    this.id,
    this.referralCode,
    this.totalReferrals,
    this.successfulReferrals,
    this.referrals,
    this.referralLink,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referralCode': referralCode,
      'totalReferrals': totalReferrals,
      'successfulReferrals': successfulReferrals,
      'referrals': referrals?.map((e) => e.toJson()).toList(),
      'referralLink': referralLink,
    };
  }

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    // Get counts from pagination object (primary source)
    int total = 0;
    int successful = 0;

    if (json['pagination'] != null && json['pagination'] is Map) {
      final paginationData = json['pagination'] as Map<String, dynamic>;
      total = (paginationData['total'] as num?)?.toInt() ?? 0;
    }

    // Fallback to root-level fields if pagination doesn't have total
    if (total == 0) {
      total = (json['totalReferrals'] as num?)?.toInt() ?? 0;
    }

    // Get successful count (might come from filtering data where registeredUser != null)
    successful = (json['successfulReferrals'] as num?)?.toInt() ?? 0;

    // Parse referrals from 'data' field (this is where the API puts the items)
    List<ReferralDetail> parsedReferrals = [];
    try {
      if (json['data'] != null && json['data'] is List) {
        parsedReferrals =
            (json['data'] as List).map((e) {
              final itemMap = e as Map<String, dynamic>;
              return ReferralDetail.fromJson(itemMap);
            }).toList();
        debugPrint(
          '[ReferralModel.fromJson] ✅ Parsed ${parsedReferrals.length} referrals from "data" field',
        );
      } else {
        debugPrint(
          '[ReferralModel.fromJson] ⚠️ No "data" field found in API response',
        );
      }
    } catch (e) {
      debugPrint(
        '[ReferralModel.fromJson] ❌ Error parsing referrals from data field: $e',
      );
    }

    debugPrint(
      '[ReferralModel.fromJson] Final: total=$total, successful=$successful, referralsList.length=${parsedReferrals.length}',
    );

    return ReferralModel(
      id: json['_id'] as String?,
      referralCode: json['referralCode'] as String?,
      totalReferrals: total,
      successfulReferrals: successful,
      referrals: parsedReferrals,
      referralLink: json['referralLink'] as String?,
    );
  }

  String toRawJson() => json.encode(toJson());

  factory ReferralModel.fromRawJson(String str) =>
      ReferralModel.fromJson(json.decode(str));
}

class ReferralDetail {
  final String? id;
  final String? referredUserId;
  final String? referredUserName;
  final String? referredUserEmail;
  final String? status; // pending, completed
  final DateTime? createdAt;

  ReferralDetail({
    this.id,
    this.referredUserId,
    this.referredUserName,
    this.referredUserEmail,
    this.status,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referredUserId': referredUserId,
      'referredUserName': referredUserName,
      'referredUserEmail': referredUserEmail,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory ReferralDetail.fromJson(Map<String, dynamic> json) {
    // Map API fields to ReferralDetail fields
    String? userId;
    String? userName;

    // Try to extract user info from registeredUser object if it exists
    if (json['registeredUser'] != null && json['registeredUser'] is Map) {
      final regUser = json['registeredUser'] as Map<String, dynamic>;
      userId = regUser['_id'] as String?;
      final firstName = regUser['firstName'] as String?;
      final lastName = regUser['lastName'] as String?;
      userName =
          [firstName, lastName].where((e) => e != null).join(' ').isEmpty
              ? null
              : [firstName, lastName].where((e) => e != null).join(' ');
    }

    return ReferralDetail(
      id: json['_id'] as String?, // Use _id from API
      referredUserId: userId, // From registeredUser._id
      referredUserName: userName, // Built from registeredUser name fields
      referredUserEmail: json['email'] as String?, // Use email directly
      status: json['status'] as String?, // Use status directly
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : null,
    );
  }
}
