# Firebase Firestore Security Rules Configuration

## Problem
Getting error: `[cloud_firestore/permission-denied] Missing or insufficient permissions`

This means your Firestore security rules are not allowing authenticated users to read/write data.

## Solution

### 1. Go to Firebase Console
1. Open [Firebase Console](https://console.firebase.google.com)
2. Select your project "LankaLink"
3. Go to **Firestore Database** > **Rules**

### 2. Replace with These Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Allow authenticated users to read/write survey_responses collection
    match /survey_responses/{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Allow authenticated users to manage their own user documents
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

### 3. Publish the Rules
- Click **Publish** button
- Wait for the rules to be deployed (usually takes a few seconds)

### 4. Test Your App
- Run the app again
- Try to load family data
- It should work now if you are signed in

## Note
Make sure users are properly authenticated before trying to access the data. The app now checks if a user is logged in before making Firestore requests.

## Security Consideration
The current rules allow any authenticated user to read/write all data. For production, you should add more restrictive rules based on user roles or data ownership.

Example (more restrictive):
```javascript
match /survey_responses/{houseNumber} {
  allow read, write: if request.auth != null && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'surveyor';
}
```
