# Firebase Schema — Pulse

**Project:** Pulse
**Classification:** Safe — rules tighten access (unauthenticated blocked); no field renames or removals.
**Last updated:** 2026-05-24

---

## Collections

### `users` — path: `users/{uid}`

**Purpose:** Stores one document per authenticated user. Created on first sign-in. Document ID equals the Firebase Auth UID.

**Owner:** Firebase Auth UID (`uid`)

| Field | Firestore Type | Required | Description |
|---|---|---|---|
| `uid` | string | required | Firebase Auth UID; mirrors document ID |
| `displayName` | string | required | Human-readable name shown in UI |
| `username` | string | required | Unique handle (e.g. @alice) |
| `bio` | string | optional | Short bio; may be empty string |
| `avatarUrl` | string | optional | HTTPS URL to avatar stored in Firebase Storage |
| `followerCount` | number | required | Cached follower count; default 0 |
| `followingCount` | number | required | Cached following count; default 0 |
| `postCount` | number | required | Cached post count; default 0 |
| `createdAt` | timestamp | required | Server timestamp set on first document creation |

**Access Patterns:**

| Who | Operation | Condition |
|---|---|---|
| Authenticated user | Read own profile | `request.auth.uid == uid` |
| Authenticated user | Read any user profile | `request.auth != null` |
| Authenticated user | Create own document | `request.auth.uid == resource-id` (first sign-in) |
| Owner | Update own profile fields | Only `displayName`, `bio`, `avatarUrl`, `postCount` |
| Any authenticated user | Update `followerCount` / `followingCount` | Atomic increment/decrement during follow/unfollow transactions |
| Owner | Delete own document | `request.auth.uid == uid` (account deletion) |

---

### `posts` — path: `posts/{postId}`

**Purpose:** Stores individual posts authored by users. Document ID is a server-generated unique ID.

**Owner:** `userId` field (Firebase Auth UID of the author)

| Field | Firestore Type | Required | Description |
|---|---|---|---|
| `userId` | string | required | Firebase Auth UID of the post author |
| `displayName` | string | required | Author's display name captured at post time |
| `avatarUrl` | string | optional | Author's avatar URL captured at post time; null if no avatar |
| `text` | string | required | Post body text |
| `imageUrl` | string | optional | Download URL for the post image in Firebase Storage; null if no image |
| `createdAt` | timestamp | required | Server timestamp set on creation |

**Access Patterns:**

| Who | Operation | Condition |
|---|---|---|
| Authenticated user | Read any post | `request.auth != null` |
| Authenticated user | Create own post | `request.auth.uid == request.resource.data.userId` |
| Author | Delete own post | `request.auth.uid == resource.data.userId` |

**Query Patterns:**

| Query | Index Required |
|---|---|
| No filter, order by `createdAt DESC` — global feed | No (single-field) |
| Filter `userId == X`, order by `createdAt DESC` — user post list | **Yes** (composite) |

---

### `follows` — path: `follows/{followId}`

**Purpose:** Tracks follow relationships between users. Document ID is `{followerId}_{followeeId}` — a composite key that ensures uniqueness and enables O(1) existence checks.

**Owner:** `followerId` field (Firebase Auth UID of the follower)

| Field | Firestore Type | Required | Description |
|---|---|---|---|
| `followerId` | string | required | Firebase Auth UID of the user doing the following |
| `followeeId` | string | required | Firebase Auth UID of the user being followed |
| `createdAt` | timestamp | required | Server timestamp set when the follow was created |

**Access Patterns:**

| Who | Operation | Condition |
|---|---|---|
| Any authenticated user | Read any follow document | `request.auth != null` (e.g. check if following before showing button) |
| Owner | Create own follow document | `request.resource.data.followerId == request.auth.uid` |
| Owner | Delete own follow document | `resource.data.followerId == request.auth.uid` |

**Query Patterns:**

| Query | Where | OrderBy | Purpose |
|---|---|---|---|
| Get followed users | `followerId == currentUid` | `createdAt ASC` | Fetch followeeId list for feed construction |
| Check if following | doc ID `{currentUid}_{targetUid}` | N/A | O(1) existence check |

---

### Firebase Storage — Post Images

**Path:** `posts/{userId}/{postId}/image`

**Purpose:** Stores one image per post, uploaded by the post author at post time.

**Access Patterns:**

| Who | Operation | Condition |
|---|---|---|
| Any authenticated user | Read image | `request.auth != null` |
| Owner | Write/delete image | `request.auth.uid == userId` |

---

## Composite Indexes

| Collection | Fields | Notes |
|---|---|---|
| `posts` | `userId ASC`, `createdAt DESC` | User-specific post list query |
| `follows` | `followerId ASC`, `createdAt ASC` | Fetch list of followed UIDs for feed construction |

See `firestore.indexes.json` for the machine-readable definition.

---

## Firebase Services Required

| Service | Status | Purpose |
|---|---|---|
| Firebase Authentication | ⚠️ BOARD ACTION REQUIRED — must enable in console | Email/Password and Google Sign-In providers |
| Cloud Firestore | Active | Primary database; rules in `schema/firestore.rules` |
| Firebase Storage | Active | Avatar image storage; rules in `schema/storage.rules` |

---

## Firestore Rules Audit — FEAT-001 Authentication

**Audit date:** 2026-05-24
**Classification:** Safe — additive auth gates only.

All Firestore rules require `request.auth != null`. Unauthenticated clients are denied by default for any path not explicitly matched. The rules implement least-privilege for the FEAT-001 access patterns:

| Operation | Actor | Document | Rule |
|---|---|---|---|
| Write user profile on signup | Authenticated user (just created) | `users/{uid}` | `allow create` when `request.auth.uid == uid` |
| Read user profile on login | Authenticated user | `users/{uid}` | `allow read` when `request.auth != null` |

No changes to `firestore.rules` were required — the pre-existing rules already satisfy both acceptance criteria.

### iOS / macOS OAuth Config Verification

| Platform | File | `GIDClientID` | `REVERSED_CLIENT_ID` URL scheme |
|---|---|---|---|
| iOS | `ios/Runner/Info.plist` | ✅ present | ✅ present |
| iOS | `ios/Runner/GoogleService-Info.plist` | ✅ `CLIENT_ID` present, `IS_SIGNIN_ENABLED: true` | ✅ `REVERSED_CLIENT_ID` present |
| macOS | `macos/Runner/Info.plist` | ✅ added (was missing) | ✅ added (was missing) |
| macOS | `macos/Runner/GoogleService-Info.plist` | ✅ `CLIENT_ID` present, `IS_SIGNIN_ENABLED: true` | ✅ `REVERSED_CLIENT_ID` present |

`firebase_options.dart` includes `iosClientId` for both iOS and macOS platform configs. ✅
