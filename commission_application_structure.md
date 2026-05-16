# Commission Application Structure

LNU Students Only | Flutter + Firebase

## 1. Authentication Module

- Register using LNU email only
- Login
- Forgot password
- Logout

Authentication Rules:

- Only emails ending with `@lnu.edu.ph` can register
- Non-LNU emails are automatically rejected
- Optional email verification before account activation

Firebase:

- Firebase Authentication

## 2. User Profile Module

- Profile picture
- Full name
- Student ID
- College
- Department
- Year level
- Username
- Bio/About
- Skills/categories
- Portfolio gallery
- Availability status

## 3. Profile Services Module

- Users can post services on their profile
- Services are only visible when another user visits/stalks their profile

Service details:

- Service title
- Description
- Category
- Estimated price
- Sample image
- Availability

## 4. Public Post Module

- Users can create public posts
- Posts appear in the home feed

Users can only:

- Heart/react to posts
- View posts
- Share posts

Users CANNOT:

- Comment on posts

Post Types:

- Artwork showcase
- Commission open post
- Service promotion
- Progress update
- Announcement

Post Contents:

- Caption/description
- Images/videos
- Date posted
- Heart count
- View count
- Share count

## 5. Commission Module

- Send commission request
- Accept/reject commission
- Track commission progress
- Deadline management

Commission Status:

- Pending
- Accepted
- In Progress
- Completed
- Cancelled

## 6. Real-Time Chat Module

- One-to-one messaging
- Real-time updates
- Typing indicator
- Seen status
- Image/file attachment
- Conversation history
- Chat notifications

Firebase:

- Cloud Firestore
- Firebase Cloud Messaging (FCM)

## 7. Notification Module

- New message alerts
- Heart reactions
- Shared posts
- Commission updates
- Service inquiries

## 8. Reports and Moderation Module

- Report users
- Report posts
- Report harassment/scam
- Report inappropriate content
- Admin moderation actions

## 9. Admin Module

- Manage users
- Moderate posts
- Moderate reports
- Ban/suspend users
- Verify student accounts
- View analytics

## 10. Firebase Collections

- users
- profiles
- profile_services
- posts
- post_reactions
- post_views
- post_shares
- commissions
- chats
- messages
- notifications
- reports

## 11. Main Application Screens

Authentication:

- Splash Screen
- Login Screen
- Register Screen
- Forgot Password Screen
- Email Verification Screen

User:

- Home Feed Screen
- Create Post Screen
- User Profile Screen
- Services Screen
- Chat Screen
- Notifications Screen
- Commission Requests Screen

Admin:

- Admin Dashboard
- User Management Screen
- Reports Management Screen
- Analytics Screen

## 12. Suggested Flutter Packages

- firebase_core
- firebase_auth
- cloud_firestore
- firebase_storage
- firebase_messaging
- image_picker
- provider / riverpod / bloc
- go_router

## 13. System Architecture

Flutter Application

↓

Firebase Authentication

↓

Cloud Firestore

↓

Firebase Storage

↓

Firebase Cloud Messaging

## 14. Project Scope Limitation

- Only LNU students can access the system
- Registration requires `@lnu.edu.ph` email
- No online payment integration
- No comment system on public posts
- Transactions happen through user agreement and real-time chat

## 15. Color Palette

- White = `#FFFFFF`
- Navy = `#000088`
- Ink Black = `#000011`
- School Bus Yellow = `#FFC300`
- Gold = `#FFD60A`
- Cinnabar = `#FF3838`
- Regal Navy = `#003566`
- RadioActive Grass = `#00E200`
