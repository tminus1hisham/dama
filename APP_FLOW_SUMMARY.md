# DAMA Kenya Mobile App - End-to-End Flow Summary

## 1. App Launch & Initialization

### What Happens When User Opens the App:

```
App Starts
    ↓
main.dart Executes
    ├─ Initialize Flutter Binding
    ├─ Check & Load Firebase (if not Web)
    ├─ Register Core Dependencies (GetX DI):
    │  ├─ Controllers (Auth, Training, Payment, etc.)
    │  ├─ Services (API, Socket, Storage)
    │  └─ Providers (Theme, Chat, Sessions)
    ├─ Setup Theme Provider (dark/light mode)
    └─ Launch MyApp widget
        ↓
    app.dart Checks Initial Route
        ├─ Check Stored Access Token
        │  ├─ If Valid & User Data Present → Route to Dashboard (HOME)
        │  └─ If Invalid/Missing → Route to Login
        ├─ Check Initial Deep Link (LinkedIn OAuth)
        │  └─ If LinkedIn Callback → Handle OAuth
        └─ GetMaterialApp Renders with Selected Route
```

**Key Point:** App determines if user is already logged in by checking `secure_storage` for valid access token and user data.

---

## 2. Authentication Flow

### Scenario: New User or User Logs In

```
LOGIN SCREEN
    ↓
User Enters Email & Password
    ↓
Click LOGIN Button
    ├─ AuthController.login() executes
    ├─ Check Server Connectivity First
    ├─ Create LoginModel with:
    │  ├─ Email
    │  ├─ Password
    │  └─ FCM Token (for push notifications)
    ├─ AuthService.login() → POST /auth/login
    └─ Backend Response:
        ├─ If requiresOtp = true
        │  ├─ Store temp token & userId in secure storage
        │  └─ Navigate to OTP Screen
        │
        ├─ If requiresOtp = false & has token
        │  ├─ AuthService.storeTokens() saves:
        │  │  ├─ access_token (JWT) → Secure Storage
        │  │  ├─ refresh_token → Secure Storage
        │  │  ├─ user_data (firstName, lastName, etc.) → Storage
        │  │  ├─ memberId, membershipId → Storage
        │  │  ├─ roles_json → Storage
        │  │  └─ Other profile data
        │  ├─ AuthController.updateAuthState()
        │  ├─ AuthController.isLoggedIn = true
        │  └─ Navigate to Dashboard (HOME)
        │
        └─ If requiresOtp with invalid response
            └─ Show Error Message
```

### OTP Verification:

```
OTP SCREEN
    ↓
User Receives OTP via SMS
    ↓
User Enters 4-6 Digit Code
    ├─ Click VERIFY
    ├─ AuthController calls AuthService.verifyOtp()
    ├─ POST /auth/verify-otp with:
    │  ├─ Token (from login response)
    │  └─ OTP Code
    ├─ Backend Returns:
    │  ├─ Final access_token
    │  └─ Full user_data
    ├─ AuthService.storeTokens() saves everything
    └─ Navigate to Dashboard
```

### Alternative: LinkedIn OAuth:

```
LOGIN SCREEN → Click "Login with LinkedIn"
    ↓
Opens WebView with LinkedIn Auth URL
    ↓
User Logs In via LinkedIn
    ↓
LinkedIn Redirects to:
  com.dama.mobile://linkedin?code=XXXXX&state=XXXXX
    ↓
Deep Link Service Catches Redirect
    ↓
LinkedinController Exchanges Code for LinkedIn Profile
    ↓
Backend Session Created
    ├─ User profile auto-populated from LinkedIn
    ├─ Tokens stored
    └─ Dashboard accessed
```

### Token Refresh Mechanism (Automatic):

```
User Makes Any API Request
    ↓
Check Token Status
    │
    ├─ If Token Valid
    │  └─ Add to request header: "Authorization: Bearer {token}"
    │
    └─ If Token Invalid (API returns 401)
        ├─ Attempt Refresh:
        │  ├─ POST /auth/refresh with refresh_token
        │  ├─ Get New Access Token
        │  └─ Update Headers
        ├─ Retry Original Request
        │
        └─ If Refresh Fails
            ├─ Clear All Tokens
            ├─ Show "Session Expired" Dialog
            └─ Force Logout → Navigate to Login
```

---

## 3. Main Dashboard & Navigation

### After Successful Login:

```
DASHBOARD (Main Hub)
    │
    ├─ Top Section:
    │  ├─ User Avatar with Glow Animation
    │  ├─ Welcome Message with Name
    │  ├─ Search Bar (Global Search)
    │  └─ Notification Bell Icon
    │
    ├─ Tabbed Navigation (MotionTabBar):
    │  ├─ HOME (Feed)
    │  ├─ BLOGS (with Categories)
    │  ├─ NEWS
    │  ├─ EVENTS
    │  └─ RESOURCES
    │
    ├─ Drawer Menu (Side Navigation):
    │  ├─ Profile Card with Stats
    │  ├─ Profile Screen
    │  ├─ My Trainings
    │  ├─ Membership Plans
    │  ├─ Transactions
    │  ├─ Notifications
    │  ├─ Settings
    │  ├─ About DAMA
    │  └─ Logout
    │
    └─ Floating Action Button:
        └─ Chat (Real-time messaging)
```

---

## 4. Content Browsing (Blogs, News, Events)

### Blogs with Categories:

```
USER TAPS "BLOGS" TAB
    ↓
BlogController.fetchCategories()
    ├─ GET /blogs → Get category list
    ├─ Display: [All Blogs, Uncategorized, Tech, Business, etc.]
    └─ Setup Infinite Scroll Paging
    ↓
USER SELECTS CATEGORY (e.g., "Tech")
    ├─ BlogController._fetchBlogsPage(pageKey: 1)
    ├─ GET /blogs?category=Tech&page=1&limit=10
    ├─ Display Blog Cards:
    │  ├─ Blog Image
    │  ├─ Title (16px)
    │  ├─ Author Name
    │  ├─ Date & Time
    │  ├─ Preview Text (excerpt, max 80 words)
    │  └─ Like/Comment Counts
    ├─ Show Shimmer Skeleton While Loading
    └─ Enable Infinite Scroll (auto-load next page)
    ↓
USER SWIPES/SCROLLS TO END
    ├─ Trigger next page load (page 2)
    ├─ Append new blog cards
    └─ Continue scrolling...
    ↓
USER TAPS ON BLOG CARD
    └─ Navigate to SelectedBlogScreen with blog data
        ↓
        BLOG DETAIL SCREEN
            ├─ Display Full Image
            ├─ Blog Title
            ├─ Author Info (Avatar + Name + Date)
            ├─ Blog Content (HTML rendered as 16px text)
            │  ├─ H1 headings: 24px
            │  ├─ H2 subheadings: 20px
            │  ├─ H3 sub-subheadings: 18px
            │  ├─ Paragraphs: 16px
            │  ├─ Bold text: 16px (bold)
            │  ├─ Italic text: 16px (italic)
            │  └─ Line height: 1.4
            ├─ Interactive Actions:
            │  ├─ Like Button (toggle heart icon)
            │  ├─ Comment Button (bottom sheet modal)
            │  └─ Share Button (external apps)
            ├─ Comments Section (shows existing comments)
            ├─ Sources & References (if included)
            └─ Related Blogs (recommendations)
```

### Similar Flow for News & Events:

**NEWS:** Same as blogs but:
- All news from "DAMA KENYA" publisher
- No categories
- PDF export option
- Subscribe to get more articles

**EVENTS:**
- Event image, date, location, speakers
- Attendee list
- Registration button
- Calendar integration (add to phone calendar)
- Event payment integration

---

## 5. Training & Certification Flow

### Browse Trainings:

```
USER NAVIGATES TO TRAININGS
    ↓
TrainingController.fetchTrainings()
├─ GET /training → Get list of all courses
└─ Display Training Cards:
    ├─ Course Image
    ├─ Title
    ├─ Description
    ├─ Duration
    ├─ Price (if paid)
    └─ Enroll/Continue Button
    ↓
USER TAPS TRAINING CARD
    └─ Navigate to TrainingDashboard
        ↓
        TRAINING DETAIL SCREEN
        ├─ Course Overview
        │  ├─ Full Description
        │  ├─ Trainer Info
        │  ├─ Learning Objectives
        │  ├─ Course Structure
        │  └─ Estimated Duration
        ├─ Progress Tracking (0-100%)
        │  ├─ Visual Progress Bar
        │  ├─ Completed Sessions Count
        │  └─ Remaining Sessions
        ├─ Sessions List (grouped by module)
        │  ├─ Session 1: [Status Icon] Topic Name
        │  ├─ Session 2: [In Progress] Topic Name
        │  ├─ Session 3: [Not Started] Topic Name
        │  └─ Session N: Topic Name
        ├─ Certificate Section
        │  ├─ If 100% Complete:
        │  │  ├─ Show "Certificate Available" Banner
        │  │  ├─ Download PDF Button
        │  │  └─ Share Certificate Option
        │  └─ If Incomplete:
        │      └─ Show "Complete all sessions to earn certificate"
        ├─ Action Buttons:
        │  ├─ "Continue Learning" (if in progress)
        │  ├─ "Enroll" (if not enrolled)
        │  └─ "View Certificate" (if completed)
        └─ Related Trainings (recommendations)
        
        When User Clicks Session:
            ├─ Fetch Session Content
            ├─ Display Session Details
            ├─ Mark Session as Viewed
            ├─ Update Progress
            └─ Enable Certificate Generation (if eligible)
```

### Certificate Generation:

```
USER COMPLETES 100% OF TRAINING
    ↓
TrainingDashboard Checks Eligibility:
    ├─ training.status == 'completed' OR
    ├─ progress >= 100% OR
    └─ certificate already issued
    ↓
USER TAPS "View Certificate"
    ├─ CertificateController.generateCertificate(trainingId)
    ├─ POST /certificates/generate
    ├─ Backend Creates PDF with:
    │  ├─ User Name
    │  ├─ Training Title
    │  ├─ Completion Date
    │  ├─ Certificate Number
    │  ├─ DAMA Logo & Signature
    │  └─ QR Code (optional)
    ├─ Generate Download URL
    ├─ Open in PDF Viewer
    └─ Allow Share/Download
```

---

## 6. Payment & M-Pesa Integration

### Resource/Membership Purchase:

```
USER WANTS TO PURCHASE RESOURCE OR UPGRADE MEMBERSHIP
    ↓
USER TAPS "PURCHASE" BUTTON
    ├─ Show Phone Number Modal
    └─ Allow country selection (default +254 Kenya)
    ↓
USER ENTERS PHONE NUMBER & CONFIRMS
    ├─ Validate Phone Format (9 digits + country code)
    └─ Proceed to Payment
    ↓
PaymentController.pay()
    ├─ Create PaymentModel with:
    │  ├─ object_id (resource/plan ID)
    │  ├─ model (Resource, Plan, etc.)
    │  ├─ amountToPay (in KES)
    │  └─ phoneNumber (formatted)
    ├─ POST /transactions/pay (to backend)
    ├─ Backend Initiates M-Pesa STK Push
    └─ Return Transaction Reference
    ↓
M-PESA PROMPT APPEARS ON USER'S PHONE
    ├─ User's Safaricom phone receives STK prompt
    └─ User enters M-Pesa PIN to confirm
    ↓
BACKEND RECEIVES M-PESA CALLBACK
    ├─ Check Payment Status
    ├─ Mark transaction as SUCCESS/FAILED
    ├─ Send FCM Notification to App
    └─ Update User's Resource/Membership Access
    ↓
APP CHECKS TRANSACTION STATUS
    ├─ User sees "Payment Successful" Snackbar
    ├─ Resource/Membership Access Granted
    ├─ Refresh User Profile Data
    └─ Update Payment History
```

**Transaction History View:**
- Shows all past payments
- Status per transaction (Pending, Success, Failed)
- Amount, Date, Description
- Receipt Download Option

---

## 7. Real-Time Chat System

### Chat Initialization:

```
USER TAPS CHAT ICON (Floating Action Button)
    ↓
CHAT USERS SCREEN (List of Conversations)
    ├─ FetchUserConversations()
    ├─ GET /conversations → Get all active conversations
    ├─ Display Conversation Cards:
    │  ├─ Other User Avatar
    │  ├─ Name
    │  ├─ Last Message Preview
    │  ├─ Timestamp (e.g., "2 hours ago")
    │  └─ Unread Badge (red dot)
    └─ Floating Action Button:
        └─ "Start New Conversation" → Select another user
    ↓
USER TAPS ON CONVERSATION
    ├─ Navigate to ChatScreen
    └─ ChatController.initialize(conversationId, token)
        ├─ SocketService.connect(token)
        │  ├─ Establish WebSocket connection to:
        │  │  http://167.71.68.0:5000
        │  └─ Auth via JWT token in query params
        ├─ Socket.emit('joinConversation', conversationId)
        ├─ Load Previous Messages
        │  └─ GET /messages/{conversationId}
        └─ Listen for Incoming Messages
            └─ socket.on('receiveMessage', handler)
            ↓
            CHAT SCREEN DISPLAYS
            ├─ Conversation Header:
            │  ├─ Other User Avatar
            │  ├─ User Name
            │  └─ Online Status (if available)
            ├─ Message List (Grouped by Date)
            │  ├─ Current User Messages (Right, Blue)
            │  ├─ Other User Messages (Left, Grey)
            │  ├─ Timestamps
            │  └─ Last Message Auto-scroll
            ├─ Message Input Field
            │  ├─ Text Input
            │  ├─ Send Button
            │  └─ Typing Indicator (if user is typing)
            └─ Message Sending Flow:
                ├─ User Types Message
                ├─ Click Send Button
                ├─ Create Optimistic Message (show immediately)
                ├─ Socket.emit('sendMessage', data)
                ├─ Backend Receives & Broadcasts
                ├─ Recipient Gets Real-Time Update
                ├─ Message Timestamp Added
                └─ Remove Optimistic, Show Real Message
```

**Key Features:**
- Persistence: Messages stored in backend database
- Real-time: WebSocket ensures live delivery
- Reconnection: Auto-reconnect if connection drops
- Unread Count: Badge updates for new messages

---

## 8. Notifications System

### Push Notifications:

```
APP RECEIVES FCM PAYLOAD FROM FIREBASE
    ↓
FirebaseApi.initNotifications()
    ├─ Handle Foreground (App Open):
    │  └─ Show Local Notification Popup
    ├─ Handle Background (App Minimized):
    │  └─ Show System Notification
    └─ Handle Terminated (App Not Running):
        └─ Launch App on Tap → Navigate to Relevant Screen
    ↓
NOTIFICATION SOURCES:
    ├─ Transaction Status (Payment Complete/Failed)
    ├─ New Message Alert (Chat)
    ├─ Training Updates (New Session Added)
    ├─ Event Announcements (Event Starting Soon)
    ├─ System Alerts (Membership Expiring)
    └─ Admin Broadcast Messages
    ↓
USER TAPS NOTIFICATION
    ├─ Extract Deep Link Data
    ├─ Navigate to Relevant Screen:
    │  ├─ Chat → Chat Screen
    │  ├─ Payment → Transactions Screen
    │  ├─ Training → Training Dashboard
    │  ├─ Event → Event Details
    │  └─ etc.
    └─ Show Related Content
```

---

## 9. User Profile & Settings

### Profile Management:

```
USER TAPS DRAWER → "PROFILE"
    ↓
PROFILE SCREEN
    ├─ Display Current Profile Data:
    │  ├─ Avatar (Editable)
    │  ├─ First Name, Last Name
    │  ├─ Email (Read-only)
    │  ├─ Phone Number
    │  ├─ Title/Profession
    │  ├─ Company
    │  ├─ Bio/Brief
    │  └─ Nationality, County
    ├─ Edit Fields:
    │  └─ Click on any field → Edit Mode
    ├─ Save Changes:
    │  ├─ PUT /user/profile with updated data
    │  ├─ Update localStorage
    │  └─ Update AuthController.user
    ├─ Upload Profile Picture:
    │  ├─ Image Picker → Select from gallery/camera
    │  ├─ Upload to Backend
    │  └─ Update profile_picture in storage
    └─ Change Password:
        ├─ Enter Old Password
        ├─ Enter New Password
        ├─ POST /user/change-password
        └─ Show Success/Error
```

### Settings:

```
USER TAPS DRAWER → "SETTINGS"
    ↓
SETTINGS SCREEN
    ├─ Theme Toggle:
    │  ├─ Dark Mode (On/Off)
    │  ├─ Use System Theme (On/Off)
    │  ├─ Update ThemeProvider state
    │  └─ Save preference to SharedPreferences
    ├─ Notification Preferences:
    │  ├─ Enable/Disable Push Notifications
    │  ├─ Sound, Vibration, Badge
    │  └─ Send preferences to backend
    ├─ Membership Info:
    │  ├─ Current Plan
    │  ├─ Expiration Date
    │  ├─ Upgrade Option
    │  └─ Renew Option
    ├─ About & Legal:
    │  ├─ App Version
    │  ├─ Terms of Service
    │  ├─ Privacy Policy
    │  └─ Contact Support
    └─ Logout:
        ├─ Clear All Tokens
        ├─ Clear User Data
        ├─ Disconnect WebSocket
        ├─ Close All Dialogs
        └─ Navigate to Login Screen
```

---

## 10. Membership & Plans

### Browse Membership Plans:

```
USER TAPS DRAWER → "MEMBERSHIP PLANS"
    ↓
PLANS SCREEN
    ├─ PlansController.fetchPlans()
    ├─ GET /plans → Get all available membership tiers
    ├─ Display Plan Cards:
    │  ├─ Plan Name (Basic, Premium, Elite)
    │  ├─ Price (Monthly/Annual)
    │  ├─ Features List (Checkmarks)
    │  ├─ Benefits:
    │  │  ├─ Unlimited Articles
    │  │  ├─ Advanced Training
    │  │  ├─ Exclusive Events
    │  │  ├─ Priority Support
    │  │  └─ Certificate Downloads
    │  ├─ Current Plan Badge (if subscribed)
    │  └─ Action Button:
    │      ├─ "Upgrade" (if lower tier)
    │      ├─ "Current Plan" (if active)
    │      └─ "Downgrade" (if higher tier)
    └─ Certificate Download:
        ├─ Show Membership Certificate (PDF)
        ├─ Download Option
        └─ Share Option
    ↓
USER CLICKS "UPGRADE"
    ├─ Navigate to Payment Modal
    ├─ Show Plan Details & Amount
    ├─ Show M-Pesa Image
    ├─ Request Phone Number
    ├─ PaymentController.pay()
    ├─ Initiate M-Pesa STK
    ├─ Wait for Confirmation
    └─ Update User Membership Status
        ├─ Set hasMemembership = true
        ├─ Set membershipId = plan._id
        ├─ Set membershipExp = expiration date
        └─ Show Confirmation & Certificate Option
```

---

## 11. Global Search

### Search Implementation:

```
USER TAPS SEARCH BAR
    ↓
GlobalSearchController.search(query)
    ├─ Query can be:
    │  ├─ Blog titles
    │  ├─ News articles
    │  ├─ Event titles
    │  ├─ Training courses
    │  ├─ User profiles
    │  └─ Resources
    ├─ GET /search?q={query} (if implemented)
    ├─ Local Filter (if stored data):
    │  ├─ Filter blogs by title/content
    │  ├─ Filter news by title
    │  └─ Filter events by title
    ├─ Display Results in Groups:
    │  ├─ Blogs (4 results max)
    │  ├─ News (4 results max)
    │  ├─ Events (4 results max)
    │  └─ Training (4 results max)
    └─ User Taps Result:
        ├─ Navigate to Detail Screen
        └─ Show Full Content
```

---

## 12. Data Persistence & Offline

### Local Storage Strategy:

```
APP STORES LOCALLY (SharedPreferences):
    ├─ Non-Sensitive Data:
    │  ├─ Theme preference (isDark, useSystemTheme)
    │  ├─ User basics (name, email, title)
    │  ├─ Cached content (blogs, news, events)
    │  ├─ Transaction history
    │  └─ Notification preferences
    │
    └─ Sensitive Data (SecureStorage):
        ├─ access_token (JWT)
        ├─ refresh_token
        ├─ user_id
        ├─ memberId
        ├─ membershipId
        └─ Any PII

OFFLINE HANDLING:
    ├─ App Checks Network:
    │  ├─ If Online:
    │  │  └─ Fetch from API, update local cache
    │  ├─ If Offline:
    │  │  └─ Use cached data from storage
    │  └─ Show "Offline" Indicator
    ├─ Queue Actions for Later:
    │  ├─ Store pending messages
    │  ├─ Store pending ratings
    │  └─ Sync when online
    └─ Network Error Modal:
        └─ Show Error + Retry Button
```

---

## 13. App Architecture Summary

### Dependency Injection Flow:

```
main.dart registers all dependencies via GetX:
    ├─ Controllers (44 total):
    │  ├─ auth_controller → Handles login/auth state
    │  ├─ blog_controller → Blog content management
    │  ├─ chat_controller → Chat logic
    │  ├─ payment_controller → Payment processing
    │  └─ [40 more controllers]
    ├─ Services (9 total):
    │  ├─ api_service → REST API wrapper (2,578 lines)
    │  ├─ auth_service → Token/JWT management
    │  ├─ socket_service → WebSocket real-time
    │  ├─ firebase_messaging_service → Push notifications
    │  └─ [5 more services]
    └─ Providers (3 total):
        ├─ ThemeProvider → Dark/light mode
        ├─ ChatProvider → Chat state
        └─ SessionsProvider → Training sessions

APP WIDGET INITIALIZATION:
    ├─ MultiProvider (for theme, chat, sessions)
    ├─ GetMaterialApp (for routing + DI)
    ├─ Routes Defined (216 routes in routes.dart)
    └─ Initial Route Determined:
        ├─ Check token → Dashboard or Login
        └─ Check deep link → Handle LinkedIn callback
```

---

## 14. Request/Response Lifecycle

### Standard API Request Flow:

```
CONTROLLER/VIEW CALLS SERVICE METHOD
    ↓
SERVICE METHOD EXECUTES:
    ├─ Get Access Token from Secure Storage
    ├─ Create HTTP Headers:
    │  ├─ Content-Type: application/json
    │  ├─ Authorization: Bearer {accessToken}
    │  └─ Other specific headers
    ├─ Make HTTP Request (GET/POST/PUT/DELETE)
    │  └─ To: https://api.damakenya.org/v1/{endpoint}
    ├─ Handle Response:
    │  ├─ 2xx Success:
    │  │  ├─ Parse JSON Response
    │  │  ├─ Convert to Dart Model (fromJson)
    │  │  └─ Return to Caller
    │  ├─ 401 Unauthorized:
    │  │  ├─ Attempt Token Refresh
    │  │  ├─ If Refresh Success → Retry Request
    │  │  └─ If Refresh Fails → Force Logout
    │  ├─ 4xx Client Error:
    │  │  └─ Throw Exception with message
    │  └─ 5xx Server Error:
    │      └─ Show Network Error Modal
    └─ Return Result to Caller
    ↓
CALLER HANDLES RESPONSE:
    ├─ Update Observable Variables (.obs)
    ├─ Trigger UI Rebuild (Obx widget observes change)
    ├─ Show Success/Error Snackbar
    └─ Update Navigation if needed
```

---

## 15. Reactive UI Updates

### GetX Observable Pattern:

```
CONTROLLER DEFINES:
    var blogs = <BlogModel>[].obs;
    var isLoading = false.obs;
    
    Future<void> fetchBlogs() async {
        isLoading.value = true;  // Trigger UI update
        blogs.value = await api.getBlogs();
        isLoading.value = false; // Trigger UI update
    }

VIEW LISTENS:
    Obx(() {
        if (controller.isLoading.value) {
            return ShimmerSkeleton();  // Shows while loading
        }
        return ListView(
            children: controller.blogs.map((blog) {
                return BlogCard(blog: blog);
            }).toList(),
        );
    })
    
FLOW:
    User Taps Blog Tab
        ↓
    fetchBlogs() sets isLoading.value = true
        ↓
    Obx detects change → Rebuild shows ShimmerSkeleton
        ↓
    API call completes
        ↓
    blogs.value = new data, isLoading.value = false
        ↓
    Obx detects changes → Rebuild shows BlogCards
        ↓
    User sees animated transition
```

---

## 16. Complete User Journey Example

### Day in the Life - User Perspective:

```
8:00 AM - USER OPENS APP
    ├─ App Loads, Checks Token
    ├─ Token Valid → Dashboard Opens
    └─ User sees personalized feed

8:05 AM - USER BROWSES BLOGS
    ├─ Taps "Blogs" Tab
    ├─ Sees "Tech" category
    ├─ Taps category → Infinite scroll blogs
    ├─ Taps blog → Reads 16px body text
    ├─ Likes blog → Updates like count real-time
    └─ Comments on blog → Appears in comments section

8:20 AM - USER CHECKS TRAINING PROGRESS
    ├─ Drawer → "My Trainings"
    ├─ Views enrolled courses with progress
    ├─ Taps course → Training dashboard
    ├─ Views progress (75% complete)
    ├─ Completes last session
    └─ Progress = 100% → Certificate Available!

8:30 AM - USER DOWNLOADS CERTIFICATE
    ├─ Taps "View Certificate"
    ├─ PDF Opens
    ├─ Taps Share → Shares to social media
    └─ Feels accomplished!

8:45 AM - USER CHECKS MESSAGES
    ├─ Taps Chat Icon
    ├─ See 3 unread messages from training facilitator
    ├─ Taps conversation → Chat screen
    ├─ Real-time WebSocket delivers messages instantly
    ├─ Types response → Sends via socket
    ├─ Facilitator receives instantly (if online)
    └─ Chat emoji/typing indicators (if implemented)

9:00 AM - USER WANTS PREMIUM
    ├─ Drawer → "Membership Plans"
    ├─ Views Premium plan ($99/month)
    ├─ Clicks "Upgrade"
    ├─ Enters phone number
    ├─ M-Pesa STK prompt appears
    ├─ Enters PIN on phone
    ├─ Payment confirmed instantly
    ├─ Membership activated
    └─ Downloads membership certificate

10:00 AM - USER GETS PUSH NOTIFICATION
    ├─ Firebase sends: "New Training: Advanced Flutter"
    ├─ Notification appears in system tray
    ├─ User taps → App opens to training details
    ├─ Enrolls in course
    └─ Sees "New course added to your trainings"

Throughout Day:
    ├─ Theme auto-switches (system theme)
    ├─ Dark mode at night, Light mode during day
    ├─ Offline? Uses cached blogs/news
    ├─ Internet back? Auto-syncs any pending actions
    ├─ Backend updates user activity
    └─ All data persists securely
```

---

## 17. Behind-the-Scenes Data Flow

### How Data Moves Through System:

```
BACKEND API
    ↓ (HTTPS JSON)
API SERVICE (2,578 lines)
    ├─ HTTP wrapper for all endpoints
    ├─ Token management
    ├─ Error handling
    └─ Response parsing
    ↓
CONTROLLERS (44 controllers)
    ├─ Call API service methods
    ├─ Update observable variables
    └─ Handle business logic
    ↓
PROVIDERS (Theme, Chat, Sessions)
    ├─ Global state management
    └─ Notify listeners of changes
    ↓
VIEWS/SCREENS (47 screens)
    ├─ Listen to controller observables (Obx)
    ├─ Listen to providers (Consumer)
    └─ Rebuild when data changes
    ↓
WIDGETS (47 reusable components)
    ├─ Receive data via parameters
    ├─ Display data
    └─ Trigger user interactions
    ↓
LOCAL STORAGE
    ├─ Persist token (SecureStorage)
    ├─ Cache user data (SharedPreferences)
    ├─ Theme preferences (SharedPreferences)
    └─ Chat history (if implemented)
    ↓
NOTIFICATIONS
    ├─ FCM receives push from backend
    ├─ Local notification shows popup
    └─ Tap opens relevant screen
    ↓
WEBSOCKET (Chat)
    ├─ Real-time bidirectional connection
    ├─ Messages sent/received instantly
    └─ Queue updates if disconnected
```

---

## 18. Key Takeaways

### How Everything Connects:

1. **Entry Point:** `main.dart` initializes all dependencies (GetX DI)

2. **Authentication:** Token-based JWT with automatic refresh on 401

3. **Navigation:** GetX named routes + deep linking support

4. **State:** GetX observables (.obs) + Provider for global state

5. **API Integration:** ApiService singleton (~2,578 lines) handles all HTTP

6. **Real-Time:** WebSocket for instant chat messaging

7. **Notifications:** FCM for push + local notifications + deep linking

8. **Storage:** SecureStorage for tokens, SharedPreferences for user data

9. **UI Pattern:** 
   - Views (screens) → Controllers (logic) → Services (API)
   - Obx widgets observe controller observables
   - Consumer widgets for provider state

10. **Content:** HTML rendering for blogs/news, plain text for resources

11. **Payments:** M-Pesa STK Push for KES transactions

12. **Theme:** Dark/light mode with system preference support

13. **Offline:** Cached data used when offline, sync when online

14. **Error Handling:** Unified error modals for unauthorized + network errors

---

## Summary Table

| Component | Count | Purpose |
|-----------|-------|---------|
| Controllers | 44 | Manage state & business logic |
| Models | 34 | Data structures (JSON serializable) |
| Views | 47 | UI screens |
| Widgets | 47 | Reusable components |
| Services | 9 | API, Auth, Chat, Storage, Firebase, DeepLinks |
| Providers | 3 | Global state (Theme, Chat, Sessions) |
| Routes | 216 | Named navigation destinations |
| Dependencies | 40+ | Flutter packages for UI, state, network, etc. |
| API Endpoints | 50+ | RESTful backend API calls |
| WebSocket | 1 | Real-time chat (Socket.IO) |

---

**This is the complete DAMA Kenya app flow - from app launch to user interactions to backend integration!**

