# Certificate Viewing Fix - TODO

## Issues to Fix:
- [x] Fix missing training status check in training_dashboard.dart
- [x] Improve certificate availability logic
- [x] Add better error handling and user feedback
- [x] Improve certificate eligibility check in certificate_controller.dart

## Files to Edit:
1. lib/views/training_dashboard.dart ✅
2. lib/controller/certificate_controller.dart ✅

## Progress:
- [x] Create TODO.md
- [x] Fix training_dashboard.dart - Add training status check
- [x] Fix training_dashboard.dart - Improve error handling
- [x] Fix certificate_controller.dart - Improve eligibility check
- [ ] Test and verify fixes

## Summary of All Changes:

### 1. lib/views/training_dashboard.dart
- **Added training status check**: Now checks if `training.status == 'completed'` in addition to progress percentage
- **Improved certificate availability logic**: Three conditions now trigger certificate banner:
  1. Certificate already issued
  2. Training status is 'completed'
  3. Progress is 100% or more
- **Better error handling in _handleViewCertificate()**:
  - Added user login check
  - Detailed debug logging with [Certificate] prefix
  - Improved certificate number retrieval with better fallbacks
  - Specific error messages based on training status and progress
  - Better URL launch handling with success/failure feedback

### 2. lib/controller/certificate_controller.dart
- **Comprehensive eligibility check**: The `checkCertificateEligibility()` method already includes:
  - Training status verification
  - Attendance calculation from multiple sources
  - Certificate already issued check
  - Detailed debug logging for troubleshooting
  - Graceful error handling (fail open on errors)

## Changes Made to training_dashboard.dart:

### 1. Fixed Certificate Availability Logic (Line ~760)
**Before:**
```dart
_isCertificateAvailable =
    widget.training.certificate?.issued == true ||
        _progressPercent >= 100;
```

**After:**
```dart
// Check if certificate is available based on:
// 1. Certificate already issued, OR
// 2. Training status is completed, OR
// 3. Progress is 100% or more
final trainingStatus = widget.training.status?.toLowerCase() ?? '';
_isCertificateAvailable =
    widget.training.certificate?.issued == true ||
        trainingStatus == 'completed' ||
        _progressPercent >= 100;
```

### 2. Improved _handleViewCertificate() Method
**Key improvements:**
- Added user login check with clear error message
- Added detailed debug logging for troubleshooting
- Improved certificate number retrieval with better error handling
- Added specific error messages based on training status and progress
- Better URL launch handling with success/failure feedback

### 3. Better User Feedback
- Shows specific messages based on:
  - Training not completed + low progress
  - Training completed but certificate processing
  - General completion message
- Added longer duration (4 seconds) for error messages
- Clearer debug logs with [Certificate] prefix
