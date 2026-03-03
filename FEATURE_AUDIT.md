# Feature Audit Report - DAMA App Issues & Status

## 1. NOTIFICATION SETTINGS ❌ NOT WORKING

### Issue
The notification preferences screen exists but is **completely non-functional**.

**File:** [lib/views/drawer_screen/notification_preferences.dart](lib/views/drawer_screen/notification_preferences.dart)

**Problems:**
- Line 40 has a **TODO comment**: `// TODO: Call API to save preferences`
- `_savePreferences()` method only shows a SnackBar confirmation
- **No actual API call** to save preferences to backend
- **No local storage** of preferences
- **No data persistence** - preferences reset on app restart
- Toggle values are stored only in `StatefulWidget` state (lost on navigation)

**What Should Happen:**
1. User toggles notification preferences (Email, Events, Resources, Marketing)
2. Changes are saved to **local storage** or **API**
3. Backend respects these preferences before sending notifications
4. Preferences persist across app sessions

**What Actually Happens:**
1. User sees toggles
2. Clicks "Save Preferences"
3. SnackBar appears saying "Notification preferences saved"
4. **Nothing happens** - no API call, no storage, preferences are lost

### Fix Required
```dart
// In notification_preferences.dart - _savePreferences() method

void _savePreferences() async {
  // 1. Save to local storage
  await StorageService.storeData({
    'emailNotifications': emailNotifications,
    'eventReminders': eventReminders,
    'newResources': newResources,
    'marketing': marketing,
  });
  
  // 2. Call API to sync with backend
  try {
    await ApiService().updateNotificationPreferences({
      'emailNotifications': emailNotifications,
      'eventReminders': eventReminders,
      'newResources': newResources,
      'marketing': marketing,
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification preferences saved'),
        duration: Duration(seconds: 2),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error saving preferences: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  Navigator.pop(context);
}
```

### Impact
- Users cannot customize notification settings
- App may send unwanted notifications (all types active)
- No user preference respect

---

## 2. EVENT REGISTRATION FLOW ❌ INCOMPLETE

### Issue
Event detail screens exist but are **missing registration/enrollment logic**.

**Files Involved:** 
- [lib/views/selected_screens/selected_event_screen.dart](lib/views/selected_screens/selected_event_screen.dart)
- [lib/controller/user_event_controller.dart](lib/controller/user_event_controller.dart)

**Problems:**

#### In `UserEventsController`
- **Only fetches** user's already-registered events
- **No register/enroll method**
- **No unregister method**
- Cannot check if user is already registered for a specific event
- `eventsList` updates but no way to add to it

```dart
// Current (incomplete)
class UserEventsController extends GetxController {
  var eventsList = <UserEventModel>[].obs;
  var isLoading = false.obs;
  final ApiService _eventService = ApiService();

  Future<void> fetchUserEvents() async {
    // Only fetches, no registration logic
  }
}
```

#### In `SelectedEventScreen`
- Shows event details beautifully
- **No "Register" button flow**
- Has payment modal for paid events
- But nowhere to actually register/enroll
- Cannot verify if user is already registered

### What Should Happen
1. User views event details
2. If NOT registered: Shows "Register Event" button
3. User clicks register → Trigger `registerEvent()` in controller
4. Controller calls `ApiService.registerForEvent(eventId, userId)`
5. On success: Button changes to "Unregister" or "View My Registration"
6. On failure: Show error modal

### What Actually Happens  
- Payment flow works (M-Pesa integration)
- But no registration flow exists
- User can pay but cannot complete registration

### Fix Required

**Step 1:** Update `UserEventsController`
```dart
class UserEventsController extends GetxController {
  var eventsList = <UserEventModel>[].obs;
  var isLoading = false.obs;
  var registeredEventIds = <String>[].obs; // Track registered events
  
  final ApiService _eventService = ApiService();

  Future<void> fetchUserEvents() async {
    isLoading.value = true;
    try {
      List<UserEventModel> fetchedEvents = await _eventService.getUserEvents();
      eventsList.assignAll(fetchedEvents);
      registeredEventIds.assignAll(
        fetchedEvents.map((e) => e.id).toList()
      );
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch events");
    } finally {
      isLoading.value = false;
    }
  }

  // NEW: Register for event
  Future<bool> registerForEvent(String eventId) async {
    try {
      final response = await _eventService.registerForEvent(eventId);
      if (response != null && response['success'] == true) {
        registeredEventIds.add(eventId);
        Get.snackbar("Success", "Registered for event!");
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar("Error", "Failed to register: $e");
      return false;
    }
  }

  // NEW: Unregister from event
  Future<bool> unregisterFromEvent(String eventId) async {
    try {
      final response = await _eventService.unregisterFromEvent(eventId);
      if (response != null && response['success'] == true) {
        registeredEventIds.remove(eventId);
        Get.snackbar("Success", "Unregistered from event");
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar("Error", "Failed to unregister: $e");
      return false;
    }
  }

  // Helper to check if registered
  bool isRegisteredFor(String eventId) {
    return registeredEventIds.contains(eventId);
  }
}
```

**Step 2:** Add API methods in `ApiService`
```dart
Future<dynamic> registerForEvent(String eventId) async {
  try {
    final response = await http.post(
      Uri.parse('$BASE_URL/events/$eventId/register'),
      headers: _headers,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    return null;
  } catch (e) {
    throw Exception('Error registering for event: $e');
  }
}

Future<dynamic> unregisterFromEvent(String eventId) async {
  try {
    final response = await http.delete(
      Uri.parse('$BASE_URL/events/$eventId/register'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  } catch (e) {
    throw Exception('Error unregistering from event: $e');
  }
}
```

**Step 3:** Update UI in `SelectedEventScreen`
```dart
// Add Obx widget to wrap registration button
Obx(() {
  final isRegistered = _userEventsController.isRegisteredFor(widget.eventID);
  
  return CustomButton(
    text: isRegistered ? 'Unregister' : 'Register Event',
    onTap: () async {
      if (isRegistered) {
        await _userEventsController.unregisterFromEvent(widget.eventID);
      } else {
        // For paid events, show payment modal
        // For free events, register directly
        if (widget.isPaid) {
          _showPhoneNumberModal(isDark);
        } else {
          await _userEventsController.registerForEvent(widget.eventID);
        }
      }
    },
  );
}),
```

### Impact
- Users cannot register for events (major feature)
- Event attendance tracking broken
- Event statistics inaccurate

---

## 3. MEMBERSHIP EXPIRY BUTTON ❓ PARTIALLY IMPLEMENTED

### Issue
Membership has 1-year free trial system, but **button doesn't change when it expires**.

**Files Involved:**
- [lib/controller/plans_controller.dart](lib/controller/plans_controller.dart)
- [lib/views/drawer_screen/plans_screen.dart](lib/views/drawer_screen/plans_screen.dart)
- [FREE_MEMBERSHIP_IMPLEMENTATION.md](FREE_MEMBERSHIP_IMPLEMENTATION.md)

**Current Implementation:**
✅ Free trial is tracked (`freeUntil` in local storage)
✅ Days remaining can be calculated
✅ Expiry date is stored
❌ **Button logic doesn't check expiry**
❌ **No "Renew" button when expired**
❌ **UI doesn't reflect expired status**

### The Problem

In `plans_screen.dart`, button logic is:
```dart
final isCurrentPlan = _plansController.hasActivePlan.value &&
    _plansController.currentUserPlan.value.toLowerCase() ==
        plan.membership.toLowerCase();

if (isCurrentPlan)
  // Show "Active" button
else if (isCorporate)
  // Show "Upgrade" button  
else
  // Show "Not Available" button

// ❌ MISSING: Check if free trial expired!
```

### What Should Happen
1. Professional plan is user's current plan
2. If **not expired**: Show "Active" button with countdown
3. If **expired**: Show "Renew Membership" button (KES 12,000/year)
4. UI should display: "Expired on [date] - Renew Now"

### What Actually Happens
1. Professional plan shows "Active" forever
2. **Even after expiry**, shows "Active" button
3. No indication subscription has expired
4. User unaware they need to renew

### Fix Required

**Step 1:** Update `PlansController` to track expiry status
```dart
class PlansController extends GetxController {
  // ... existing code ...
  
  var membershipExpired = false.obs;
  var daysUntilExpiry = 0.obs;
  var membershipExpiryDate = Rxn<DateTime>();
  
  Future<void> checkMembershipStatus() async {
    try {
      String? membershipExp = await StorageService.getData('membershipExp');
      String? freeUntil = await StorageService.getData('freeUntil');
      
      if (membershipExp != null || freeUntil != null) {
        final expiryDate = DateTime.parse(membershipExp ?? freeUntil);
        final now = DateTime.now();
        
        membershipExpiryDate.value = expiryDate;
        membershipExpired.value = now.isAfter(expiryDate);
        daysUntilExpiry.value = expiryDate.difference(now).inDays;
        
        print('[PlansController] Membership expires in ${daysUntilExpiry.value} days');
      }
    } catch (e) {
      debugPrint('Error checking membership status: $e');
    }
  }
}
```

**Step 2:** Update button logic in `plans_screen.dart`
```dart
Widget _buildPlanCard(BuildContext context, PlanModel plan, bool isDarkMode) {
  final isCurrentPlan = /* existing logic */;
  final isExpired = _plansController.membershipExpired.value && isCurrentPlan;
  
  return Column(
    children: [
      if (isCurrentPlan && isExpired)
        // EXPIRED BANNER
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Membership expired',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        
      // BUTTONS
      if (isCurrentPlan)
        if (isExpired)
          // Expired: Show Renew button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            onPressed: () => _showPaymentModal(context, plan, isDarkMode),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded, size: 16),
                SizedBox(width: 6),
                Text('Renew Membership'),
              ],
            ),
          )
        else
          // Active: Show Active with countdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Active (${_plansController.daysUntilExpiry.value} days)',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Expires: ${DateFormat('MMM d, yyyy').format(_plansController.membershipExpiryDate.value!)}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: kGrey),
              ),
            ],
          ),
    ],
  );
}
```

**Step 3:** Call status check in `initState` and `build`
```dart
@override
void initState() {
  super.initState();
  _plansController = Get.find<PlansController>();
  _plansController.fetchPlans();
  _plansController.checkMembershipStatus(); // ADD THIS
  _fetchPhoneNumber();
}

// Also add periodic check (e.g., every time screen is visible)
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _plansController.checkMembershipStatus(); // Refresh when returning to app
  }
}
```

### Impact
- Users don't renew expired memberships
- Feature access not revoked after expiry
- Membership revenue loss
- Inconsistent access control

---

## Summary Table

| Feature | Status | Severity | Impact |
|---------|--------|----------|--------|
| Notification Settings | ❌ Not Working | **HIGH** | Users can't customize notifications |
| Event Registration | ❌ Incomplete | **CRITICAL** | Cannot register for events (core feature) |
| Membership Expiry Button | ❓ Partial | **MEDIUM** | Users unaware of expiry, revenue loss |

---

## Recommendations

### Priority 1: EVENT REGISTRATION (CRITICAL)
- This is a core feature that completely blocks event participation
- User can view events but cannot register
- Implement in next sprint

### Priority 2: MEMBERSHIP EXPIRY (HIGH)
- Affects paid renewal flow
- Impacts business revenue model
- Implement with notification system fix

### Priority 3: NOTIFICATION SETTINGS (MEDIUM)
- Current implementation just shows false feedback to users
- Either complete the implementation or remove the settings screen
- If keeping, implement both local storage and API sync

---

## Testing Checklist

After fixes:

- [ ] Notification Settings
  - [ ] Save toggles and verify in local storage
  - [ ] API receives correct payload
  - [ ] Preferences persist after app restart
  - [ ] Test on dark/light mode

- [ ] Event Registration
  - [ ] Register for free event works
  - [ ] Register for paid event triggers payment
  - [ ] Button changes to "Unregister" after registration
  - [ ] Registered event appears in UserEventsController
  - [ ] Unregister works and button reverts

- [ ] Membership Expiry
  - [ ] Show countdown for active membership
  - [ ] Show expired banner when past expiry date
  - [ ] "Renew" button appears when expired
  - [ ] Renewal payment flow works
  - [ ] Status updates after renewal

