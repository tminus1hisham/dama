# DAMA Kenya Mobile App - API Documentation

## Overview

- **Base URL:** `https://api.damakenya.org/v1`
- **Chat Server:** `https://chats.damakenya.org` (WebSocket)
- **Chat API:** `http://167.71.68.0:5000/v1`
- **Authentication:** Bearer Token (JWT)

All authenticated endpoints require the following header:
```
Authorization: Bearer <access_token>
```

---

## Table of Contents

1. [Authentication](#authentication)
2. [User Management](#user-management)
3. [Blogs](#blogs)
4. [News](#news)
5. [Events](#events)
6. [Resources](#resources)
7. [Chat](#chat)
8. [Transactions & Payments](#transactions--payments)
9. [Plans & Membership](#plans--membership)
10. [Notifications](#notifications)
11. [Trainings](#trainings)
12. [Roles](#roles)
13. [Search](#search)
14. [Alerts](#alerts)
15. [Verification](#verification)

---

## Authentication

### Login
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `POST` | `/user/login` | ❌ |

**Request Body:**
```json
{
  "email": "string",
  "password": "string",
  "fcmToken": "string"
}
```

**Response (200):**
```json
{
  "token": "string",
  "user": {
    "_id": "string",
    "firstName": "string",
    "middleName": "string",
    "lastName": "string",
    "email": "string",
    "phone_number": "string",
    "profile_picture": "string",
    "title": "string",
    "company": "string",
    "brief": "string",
    "roles": ["string"],
    "memberId": "string",
    "hasMembership": "boolean",
    "membershipExp": "string",
    "membershipId": "string",
    "resources": [],
    "events": [],
    "articles_assigned_count": "number",
    "articles_seen_count": "number"
  }
}
```

---

### LinkedIn OAuth Login
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/user/linkedin` | ❌ |

Opens LinkedIn OAuth flow in WebView. Returns callback with token.

---

### Register
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `POST` | `/user/register` | ❌ |

**Request Body:**
```json
{
  "firstName": "string",
  "middleName": "string",
  "lastName": "string",
  "email": "string",
  "password": "string",
  "phone_number": "string"
}
```

**Response (201):**
```json
{
  "user": {
    "_id": "string",
    "phone_number": "string"
  }
}
```

---

### Verify OTP (2FA)
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `POST` | `/user/login/2fa/verify` | ✅ |

**Request Body:**
```json
{
  "otp": "string",
  "userId": "string"
}
```

---

### Forgot Password (Request Reset)
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `POST` | `/user/forgot-password` | ❌ |

**Request Body:**
```json
{
  "email": "string"
}
```

**Response (200):**
```json
{
  "userId": "string",
  "message": "string"
}
```

---

### Reset Password with OTP
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `POST` | `/user/reset-password-otp` | ✅ |

**Request Body:**
```json
{
  "otp": "string",
  "newPassword": "string",
  "userId": "string"
}
```

---

### Change Password
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `POST` | `/user/change/password` | ✅ |

**Request Body:**
```json
{
  "oldPassword": "string",
  "newPassword": "string"
}
```

---

## User Management

### Get User Profile
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/user/profile/{userId}` | ✅ |

**Response (200):**
```json
{
  "user": {
    "_id": "string",
    "firstName": "string",
    "middleName": "string",
    "lastName": "string",
    "email": "string",
    "phone_number": "string",
    "profile_picture": "string",
    "title": "string",
    "company": "string",
    "brief": "string",
    "nationality": "string",
    "county": "string",
    "roles": ["string"]
  }
}
```

---

### Update User Profile
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `PATCH` | `/user/update` | ✅ |

**Request Body:**
```json
{
  "firstName": "string",
  "middleName": "string",
  "lastName": "string",
  "nationality": "string",
  "county": "string",
  "phone_number": "string",
  "profile_picture": "string",
  "title": "string",
  "company": "string",
  "brief": "string"
}
```

---

### Get Article Count
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `POST` | `/user/articleCount` | ✅ |

**Response (200):**
```json
{
  "articles_assigned_count": "number",
  "articles_seen_count": "number"
}
```

---

### Request Account Deletion
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `POST` | `/user/delete/account/request` | ✅ |

---

## Blogs

### Get All Blogs (Paginated)
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/blogs/get/all` | ✅ |

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `page` | number | ✅ | Page number (starts at 1) |
| `limit` | number | ✅ | Items per page |
| `category` | string | ❌ | Filter by category (lowercase) |

**Response (200):**
```json
{
  "success": true,
  "blogPosts": [
    {
      "_id": "string",
      "title": "string",
      "author": {
        "_id": "string",
        "firstName": "string",
        "lastName": "string",
        "profile_picture": "string",
        "roles": ["string"]
      },
      "status": "string",
      "description": "string",
      "comments": [],
      "likes": [],
      "image_url": "string",
      "created_at": "ISO8601",
      "updated_at": "ISO8601"
    }
  ]
}
```

---

### Get Blog by ID
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/blogs/get/post/{blogId}` | ✅ |

**Response (200):**
```json
{
  "blogPost": { ... }
}
```

---

### Get Blog Categories
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/blogs/categories` | ✅ |

**Response (200):**
```json
{
  "success": true,
  "categories": {
    "TECHNOLOGY": "technology",
    "HEALTH": "health",
    "FOOD": "food",
    "BUSINESS": "business",
    "POLITICS": "politics",
    "SCIENCE": "science",
    "SPORTS": "sports",
    "ENTERTAINMENT": "entertainment",
    "EDUCATION": "education",
    "TRAVEL": "travel"
  }
}
```

---

### Add Comment to Blog
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `POST` | `/blogs/comment/{blogId}` | ✅ |

**Request Body:**
```json
{
  "comment": "string"
}
```

---

### Like Blog
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `POST` | `/blogs/like/{blogId}` | ✅ |

---

## News

### Get All News (Paginated)
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/news/get/all` | ✅ |

**Query Parameters:**
| Parameter | Type | Required |
|-----------|------|----------|
| `page` | number | ✅ |
| `limit` | number | ✅ |

**Response (200):**
```json
{
  "newsPosts": [
    {
      "_id": "string",
      "title": "string",
      "author": {
        "_id": "string",
        "firstName": "string",
        "lastName": "string",
        "profile_picture": "string"
      },
      "description": "string",
      "comments": [],
      "likes": [],
      "isFeatured": "boolean",
      "image_url": "string",
      "created_at": "ISO8601"
    }
  ]
}
```

---

### Get News by ID
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/news/get/{newsId}` | ✅ |

**Response (200):**
```json
{
  "newsPost": { ... }
}
```

---

### Add Comment to News
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `POST` | `/news/comment/{newsId}` | ✅ |

**Request Body:**
```json
{
  "comment": "string"
}
```

---

### Like News
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `POST` | `/news/like/{newsId}` | ✅ |

---

## Events

### Get All Events
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/events/all` | ✅ |

**Response (200):**
```json
{
  "events": [
    {
      "_id": "string",
      "event_creator": {
        "firstName": "string",
        "lastName": "string"
      },
      "event_title": "string",
      "description": "string",
      "speakers": [
        {
          "name": "string",
          "image": "string"
        }
      ],
      "attendees": [
        {
          "name": "string",
          "profilePicture": "string"
        }
      ],
      "location": "string",
      "event_date": "ISO8601",
      "price": "number",
      "event_image_url": "string",
      "created_at": "ISO8601"
    }
  ]
}
```

---

### Get User's Events
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/user/events/all` | ✅ |

Returns events the user is registered for.

---

## Resources

### Get All Resources
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/resources/get/all` | ✅ |

**Response (200):**
```json
{
  "resources": [
    {
      "_id": "string",
      "title": "string",
      "description": "string",
      "file_url": "string",
      "ratings": [],
      "created_at": "ISO8601"
    }
  ]
}
```

---

### Get User's Resources
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/user/resources/all` | ✅ |

---

### Rate Resource
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `POST` | `/resources/rate/{resourceId}` | ✅ |

**Request Body:**
```json
{
  "rating": "number (1-5)"
}
```

---

## Chat

> **Note:** Chat API uses a different base URL: `http://167.71.68.0:5000/v1`

### Get User Conversations
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/chat/conversations/{userId}` | ✅ |

---

### Start/Get Conversation
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/chat/conversation/{user1Id}/{user2Id}` | ✅ |

**Response (200):**
```json
{
  "conversation": {
    "_id": "string"
  }
}
```

---

### Get Messages
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/chat/messages/{conversationId}` | ✅ |

**Response (200):**
```json
{
  "messages": [
    {
      "_id": "string",
      "sender": "string",
      "content": "string",
      "created_at": "ISO8601"
    }
  ]
}
```

---

### WebSocket Events (Socket.IO)

**Server:** `https://chats.damakenya.org`

**Connection:**
```javascript
socket.connect({
  transports: ['websocket'],
  query: { token: '<access_token>' }
});
```

| Event | Direction | Payload |
|-------|-----------|---------|
| `joinConversation` | Emit | `conversationId: string` |
| `leaveConversation` | Emit | `conversationId: string` |
| `sendMessage` | Emit | `{ conversationId, sender, content }` |
| `receiveMessage` | Listen | Message object |

---

## Transactions & Payments

### Get User Transactions
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/transactions/get/single/user` | ✅ |

**Response (200):**
```json
{
  "transactions": [
    {
      "_id": "string",
      "user": "string",
      "amount": "number",
      "status": "string",
      "type": "string",
      "created_at": "ISO8601"
    }
  ]
}
```

---

### Make Payment (M-Pesa STK Push)
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `POST` | `/transactions/pay` | ✅ |

**Request Body:**
```json
{
  "amount": "number",
  "phone_number": "string",
  "planId": "string"
}
```

---

## Plans & Membership

### Get All Plans
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/plans/all` | ✅ |

**Response (200):**
```json
{
  "plans": [
    {
      "_id": "string",
      "membership": "string",
      "type": "string",
      "price": "number",
      "included": ["string"],
      "created_at": "ISO8601",
      "updated_at": "ISO8601"
    }
  ]
}
```

---

## Notifications

### Get User Notifications
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/notifications/get/user/notifications` | ✅ |

**Response (200):**
```json
{
  "notifications": [
    {
      "_id": "string",
      "title": "string",
      "body": "string",
      "type": "string",
      "read": "boolean",
      "created_at": "ISO8601"
    }
  ]
}
```

---

## Trainings

### Get All Trainings
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/trainings/all` | ✅ |

**Response (200):**
```json
{
  "trainings": [
    {
      "_id": "string",
      "title": "string",
      "description": "string",
      "trainer": "string",
      "date": "ISO8601",
      "location": "string",
      "price": "number"
    }
  ]
}
```

---

### Register for Training
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `POST` | `/trainings/register/{trainingId}` | ✅ |

**Response (200):**
```json
{
  "success": true,
  "message": "Successfully registered for training"
}
```

---

### Get User Trainings
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/user/trainings` | ✅ |

**Response (200):**
```json
{
  "trainings": [
    {
      "_id": "string",
      "title": "string",
      "description": "string",
      "trainer": "string",
      "date": "ISO8601",
      "location": "string",
      "price": "number"
    }
  ]
}
```

---

### Get User Training Details
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/trainings/user/trainings/{trainingId}` | ✅ |

**Response (200):**
```json
{
  "_id": "string",
  "title": "string",
  "description": "string",
  "trainer": "string",
  "date": "ISO8601",
  "location": "string",
  "price": "number",
  "registration_status": "string",
  "progress": "number"
}
```

---

## Roles

### Get All Roles
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/roles/all` | ✅ |

---

### Request Role Change
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `POST` | `/roles/request/role/change` | ✅ |

**Request Body:**
```json
{
  "role": "string",
  "reason": "string"
}
```

---

## Search

### Global Search
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/search` | ✅ |

**Query Parameters:**
| Parameter | Type | Required |
|-----------|------|----------|
| `q` | string | ✅ |

**Response (200):**
```json
{
  "blogs": [],
  "news": [],
  "events": [],
  "resources": [],
  "users": []
}
```

---

## Alerts

### Get Active Alerts
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `GET` | `/alerts/active` | ✅ |

**Response (200):**
```json
{
  "alerts": [
    {
      "_id": "string",
      "title": "string",
      "message": "string",
      "type": "string",
      "created_at": "ISO8601"
    }
  ]
}
```

---

## Verification

### Verify QR Code
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `POST` | `/transactions/verify/qr` | ✅ |

**Request Body:**
```json
{
  "qrData": {
    "memberId": "string",
    "eventId": "string"
  }
}
```

---

### Verify by Phone Number
| Method | Endpoint | Auth Required |
|--------|----------|---------------|
| `POST` | `/transactions/verify/by/phone` | ✅ |

**Request Body:**
```json
{
  "phone_number": "string",
  "eventId": "string"
}
```

---

## Error Handling

All endpoints return standard error responses:

### 401 / 403 - Unauthorized
```json
{
  "message": "Unauthorized request"
}
```
*Triggers automatic logout dialog in app*

### 4xx / 5xx - Error Response
```json
{
  "message": "Error description"
}
```

---

## Models Reference

| Model | File |
|-------|------|
| `LoginModel` | `lib/models/login_model.dart` |
| `RegisterModel` | `lib/models/register_model.dart` |
| `UserProfileModel` | `lib/models/user_model.dart` |
| `BlogPostModel` | `lib/models/blogs_model.dart` |
| `NewsModel` | `lib/models/news_model.dart` |
| `EventModel` | `lib/models/event_model.dart` |
| `ResourceModel` | `lib/models/resources_model.dart` |
| `PlanModel` | `lib/models/plans_model.dart` |
| `TransactionModel` | `lib/models/transaction_model.dart` |
| `NotificationModel` | `lib/models/notification_model.dart` |
| `TrainingModel` | `lib/models/training_model.dart` |
| `CommentModel` | `lib/models/comment_model.dart` |
| `MessageModel` | `lib/models/message_model.dart` |
| `PaymentModel` | `lib/models/payment_model.dart` |
| `AlertModel` | `lib/models/alert_model.dart` |

---

## Service Files

| Service | File | Description |
|---------|------|-------------|
| `ApiService` | `lib/services/api_service.dart` | Main REST API calls |
| `AuthService` | `lib/services/auth_service.dart` | Authentication & user management |
| `SocketService` | `lib/services/socket_service.dart` | WebSocket chat service |
| `StorageService` | `lib/services/local_storage_service.dart` | Local storage management |

---

*Last updated: January 30, 2026*
