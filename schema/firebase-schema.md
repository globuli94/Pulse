# Firebase Schema — Pulse

**Project:** Pulse
**Classification:** BREAKING — removes stored counter fields (`postCount`, `followerCount`, `followingCount` on `users`; `likeCount` on `posts`). Counts are now derived dynamically via Firestore count queries. See SOCAA-586 audit below.
**Last updated:** 2026-06-01

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
| `createdAt` | timestamp | required | Server timestamp set on first document creation |

> ⚠️ **Breaking change (SOCAA-586):** `followerCount`, `followingCount`, and `postCount` fields have been removed. Counts are now derived dynamically: use `follows.where('followeeId', '==', uid).count()` for follower count, `follows.where('followerId', '==', uid).count()` for following count, and `posts.where('userId', '==', uid).count()` for post count.

**Access Patterns:**

| Who | Operation | Condition |
|---|---|---|
| Authenticated user | Read own profile | `request.auth.uid == uid` |
| Authenticated user | Read any user profile | `request.auth != null` |
| Authenticated user | Create own document | `request.auth.uid == resource-id` (first sign-in) |
| Owner | Update own profile fields | Only `displayName`, `bio`, `avatarUrl`, `username` |
| Owner | Delete own document | `request.auth.uid == uid` (account deletion) |

**Query Patterns:**

| Collection | `.where()` fields | `.orderBy()` fields | Limit | Purpose | Composite Index Required |
|---|---|---|---|---|---|
| `users` | `displayName >= q`, `displayName <= q + '\uf8ff'` | `displayName ASC` | 20 | Prefix search by displayName for user search | **No** — range filter and orderBy are on the same field; single-field index on `displayName` is sufficient |

---

### `posts` — path: `posts/{postId}`

**Purpose:** Stores individual posts authored by users. Document ID is a server-generated unique ID.

**Owner:** `userId` field (Firebase Auth UID of the author)

| Field | Firestore Type | Required | Description |
|---|---|---|---|
| `userId` | string | required | Firebase Auth UID of the post author |
| `text` | string | required | Post body text |
| `imageUrl` | string | optional | Download URL for the post image in Firebase Storage; null if no image |
| `createdAt` | timestamp | required | Server timestamp set on creation |

> ⚠️ **Breaking change (SOCAA-586):** `likeCount` field has been removed. Like count is now derived dynamically via `likes.where('postId', '==', postId).count()`.

> ⚠️ **Breaking change (SOCAA-593):** `displayName` and `avatarUrl` fields have been removed from post documents. Author display info is resolved at read time from `users/{userId}` — join on `userId` to display the author's current name and avatar.

**Access Patterns:**

| Who | Operation | Condition |
|---|---|---|
| Authenticated user | Read any post | `request.auth != null` |
| Authenticated user | Create own post | `request.auth.uid == request.resource.data.userId` |
| Author | Delete own post | `request.auth.uid == resource.data.userId` |

**Query Patterns:**

| Query | `.where()` | `.orderBy()` | Index Required | Purpose |
|---|---|---|---|---|
| No filter, order by `createdAt DESC` | — | `createdAt DESC` | No (single-field) | Global feed |
| Filter by author | `userId == uid` | `createdAt DESC` | **Yes** (composite: `userId ASC`, `createdAt DESC`) | User post list / profile grid |
| Dynamic post count for user | `userId == uid` | — | No (single-field auto-index) | `posts.where('userId', '==', uid).count()` replaces `postCount` |

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

| Query | Where | OrderBy | Index Required | Purpose |
|---|---|---|---|---|
| Get followed users | `followerId == currentUid` | `createdAt ASC` | Yes (composite, existing) | Fetch followeeId list for feed construction |
| Get followers list | `followedId == uid` | — | No | Resolve follower list for profile screen |
| Get following list | `followerId == uid` | — | No | Resolve following list for profile screen |
| Check if following | doc ID `{currentUid}_{targetUid}` | N/A | No | O(1) existence check |
| Dynamic follower count | `followeeId == uid` | — | No (single-field auto-index) | `follows.where('followeeId', '==', uid).count()` replaces `followerCount` |
| Dynamic following count | `followerId == uid` | — | No (single-field auto-index) | `follows.where('followerId', '==', uid).count()` replaces `followingCount` |

---

### `likes` — path: `likes/{likeId}`

**Purpose:** Tracks which users have liked which posts. Document ID is `{userId}_{postId}` — a composite key ensuring uniqueness and enabling O(1) existence checks without a compound query.

**Owner:** `userId` field (Firebase Auth UID of the user who liked the post)

| Field | Firestore Type | Required | Description |
|---|---|---|---|
| `postId` | string | required | ID of the post being liked |
| `userId` | string | required | Firebase Auth UID of the user who liked the post |
| `createdAt` | timestamp | required | Server timestamp set when the like was created |

**Access Patterns:**

| Who | Operation | Condition |
|---|---|---|
| Any authenticated user | Read a like document | `request.auth != null` (e.g. check if current user liked a post) |
| Owner | Create own like | `request.resource.data.userId == request.auth.uid` — set() with composite key |
| Owner | Delete own like (unlike) | `resource.data.userId == request.auth.uid` — delete() with composite key |

**Query Patterns:**

| Query | `.where()` | `.orderBy()` | Index Required | Purpose |
|---|---|---|---|---|
| Check if liked | doc ID `{userId}_{postId}` | — | No | O(1) existence check |
| Dynamic like count for post | `postId == postId` | — | No (single-field auto-index) | `likes.where('postId', '==', postId).count()` replaces `likeCount` |

---

### `comments` — path: `comments/{commentId}`

**Purpose:** Stores one comment per document. Comments belong to a post and are authored by a user. Document ID is a server-generated unique ID.

**Owner:** `authorId` field (Firebase Auth UID of the comment author)

| Field | Firestore Type | Required | Description |
|---|---|---|---|
| `id` | string | required | Equals the document ID; stored redundantly for client convenience |
| `postId` | string | required | ID of the post this comment belongs to |
| `authorId` | string | required | Firebase Auth UID of the comment author |
| `text` | string | required | Comment body text |
| `createdAt` | timestamp | required | Server timestamp set on creation |

> **Note:** Comment count is derived dynamically via `comments.where('postId', '==', postId).count().get()`. No `commentCount` field is stored on `posts`.

**Access Patterns:**

| Who | Operation | Condition |
|---|---|---|
| Any authenticated user | Read comments for a post | `request.auth != null` |
| Authenticated user | Create own comment | `request.resource.data.authorId == request.auth.uid` |
| Author | Delete own comment | `resource.data.authorId == request.auth.uid` |
| Authenticated user | Write comment notification | `notifications/{notificationId}` — covered by existing `notifications` create rule |

**Query Patterns:**

| Collection | `.where()` | `.orderBy()` | Index Required | Purpose |
|---|---|---|---|---|
| `comments` | `postId == postId` | `createdAt ASC` | **Yes** (composite: `postId ASC`, `createdAt ASC`) | Fetch all comments for a post, oldest first |
| `comments` | `postId == postId` | — (count only) | No additional index needed | Dynamic comment count for feed card |

---

### `notifications` — path: `notifications/{notificationId}`

**Purpose:** Stores in-app notifications delivered to users when another user likes their post or follows them. Document ID is a server-generated unique ID.

**Owner:** `userId` field (Firebase Auth UID of the recipient)

| Field | Firestore Type | Required | Description |
|---|---|---|---|
| `id` | string | required | Equals the document ID; stored redundantly for client convenience |
| `userId` | string | required | Firebase Auth UID of the recipient (post owner or followed user) |
| `type` | string | required | Event type: `'like'`, `'follow'`, or `'comment'` |
| `actorId` | string | required | Firebase Auth UID of the user who triggered the event; used by the UI to join `users/{actorId}` at read time to fetch the actor's current `avatarUrl` |
| `actorDisplayName` | string | required | Display name of the actor captured at event time |
| `postId` | string | optional | ID of the liked post; only present when `type == 'like'`; null for follow notifications |
| `isRead` | boolean | required | `false` on creation; set to `true` by the recipient when they view the notification |
| `createdAt` | timestamp | required | Server timestamp set on creation |

**Access Patterns:**

| Who | Operation | Condition |
|---|---|---|
| Any authenticated user (actor) | Create notification for another user | `request.auth != null` |
| Recipient | Read own notifications | `request.auth.uid == resource.data.userId` |
| Recipient | Update `isRead` only | `request.auth.uid == resource.data.userId` and only `isRead` field changes |
| Anyone | Delete notification | Denied — no delete rule |

**Query Patterns:**

| Collection | `.where()` | `.orderBy()` | Index Required | Purpose |
|---|---|---|---|---|
| `notifications` | `userId == currentUser.uid` | `createdAt DESC` | **Yes** (composite: `userId ASC`, `createdAt DESC`) | Fetch all notifications for the current user, newest first |
| `notifications` | `userId == currentUser.uid`, `isRead == false` | — | **Yes** (composite: `userId ASC`, `isRead ASC`) | Count or fetch unread notifications for badge |

---

### `conversations` — path: `conversations/{conversationId}`

**Purpose:** Stores one document per direct-message conversation between two users. Document ID is a server-generated unique ID.

**Owner:** Both participants (identified by `participantIds` array)

| Field | Firestore Type | Required | Description |
|---|---|---|---|
| `participantIds` | array (string) | required | UIDs of the two participants |
| `lastMessageText` | string | required | Preview text of the most recent message |
| `lastMessageAt` | timestamp | required | Timestamp of the most recent message; used for ordering the conversation list |
| `unreadCounts` | map (string → number) | required | Maps each participant UID to their unread message count |

**Access Patterns:**

| Who | Operation | Condition |
|---|---|---|
| Participant | Read conversation | `request.auth.uid in resource.data.participantIds` |
| Authenticated user | Create conversation | `request.auth.uid in request.resource.data.participantIds` |
| Participant | Update conversation (lastMessage, unreadCounts) | `request.auth.uid in resource.data.participantIds` |

**Query Patterns:**

| Collection | `.where()` | `.orderBy()` | Index Required | Notes |
|---|---|---|---|---|
| `conversations` | `participantIds arrayContains userId` | `lastMessageAt DESC` | **Yes** (composite) | Fetch all conversations for a user, most recent first |

---

### `conversations/{conversationId}/messages` — path: `conversations/{conversationId}/messages/{messageId}`

**Purpose:** Stores individual messages within a conversation. Document ID is a server-generated unique ID.

**Owner:** `senderId` field (Firebase Auth UID of the sender)

| Field | Firestore Type | Required | Description |
|---|---|---|---|
| `senderId` | string | required | Firebase Auth UID of the message sender |
| `text` | string | required | Message text content |
| `createdAt` | timestamp | required | Timestamp when the message was sent; used for ordering messages ASC |

**Access Patterns:**

| Who | Operation | Condition |
|---|---|---|
| Participant of parent conversation | Read messages | Caller UID is in parent `conversations/{id}.participantIds` |
| Participant of parent conversation | Send message | Caller UID is in parent `conversations/{id}.participantIds` and `senderId == request.auth.uid` |

**Query Patterns:**

| Collection | `.where()` | `.orderBy()` | Index Required | Notes |
|---|---|---|---|---|
| `conversations/{id}/messages` | — | `createdAt ASC` | **No** (single-field) | Chronological message list within a conversation |

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
| `posts` | `userId ASC`, `createdAt DESC` | User-specific post list (feed + profile grid) |
| `follows` | `followerId ASC`, `createdAt ASC` | Fetch list of followed UIDs for feed construction |
| `conversations` | `participantIds ARRAY_CONTAINS`, `lastMessageAt DESC` | Conversation list for a given user, most recent first |
| `notifications` | `userId ASC`, `createdAt DESC` | All notifications for a user, newest first |
| `notifications` | `userId ASC`, `isRead ASC` | Unread notifications count / badge query |
| `comments` | `postId ASC`, `createdAt ASC` | Fetch all comments for a post, oldest first |
| `users` | — | No composite index needed for displayName prefix query (range filter and orderBy on same field; single-field index sufficient) |

**Note:** The profile posts query `.where('userId', '==', uid).orderBy('createdAt', 'desc')` uses the `posts (userId ASC, createdAt DESC)` index above. The followers/following queries (`.where('followedId', '==', uid)` and `.where('followerId', '==', uid)` without `orderBy` on a second field) require no composite index.

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

---

## Firestore Rules Audit — SOCAA-503 User Search

**Audit date:** 2026-05-25
**Classification:** Safe — additive query pattern only; no field renames or removals.

### Collection-Level Query Coverage

The existing rule `allow read: if request.auth != null;` on `match /users/{uid}` covers **both** single-document reads and collection-level queries in Firestore. A collection query is permitted if and only if the security rules would allow reading every document in the result set. Because any authenticated user is allowed to read any `users` document, the displayName prefix range query is fully covered by the existing rule.

**No changes to `schema/firestore.rules` are required.**

### Composite Index Determination

The displayName prefix query pattern is:
```
.where('displayName', '>=', q)
.where('displayName', '<=', q + '\uf8ff')
.orderBy('displayName')
.limit(20)
```

Firestore requires a composite index only when a range filter is combined with an `orderBy` on a **different** field. Here the range filter and `orderBy` target the same field (`displayName`), so Firestore's auto-generated single-field index on `displayName` is sufficient.

**No entry added to `firestore.indexes.json`.**

| Deliverable | Status |
|---|---|
| `firebase-schema.md` — displayName prefix query pattern row added to `users` section | ✅ Done |
| `firestore.indexes.json` — composite index not required; confirmed and documented | ✅ Done |
| `firestore.rules` — collection-level query confirmed covered by existing `allow read` rule | ✅ No change needed |

---

## Firestore Rules Audit — SOCAA-507 Profile Expansion

**Audit date:** 2026-05-26
**Classification:** Safe — additive documentation only; no field renames, removals, or new collections.

### Field Name Clarification

The SOCAA-507 ticket references `authorId` as the posts field. The actual Firestore field name is `userId` (see `posts` schema above and the existing composite index). The Flutter profile posts query must use `.where('userId', '==', uid)` to match the existing index.

### Composite Index Determination

The profile posts query is `.where('userId', '==', uid).orderBy('createdAt', 'desc')`. A composite index on (`userId ASC`, `createdAt DESC`) is required because equality filter and `orderBy` target different fields.

**This index already exists in `firestore.indexes.json`** (added for FEAT-006 feed). No new entry is needed.

### Rules Coverage

| Access Pattern | Collection | Rule in Effect |
|---|---|---|
| Read any user's posts (profile grid) | `posts` | `allow read: if request.auth != null` ✅ |
| Read followers (`followedId == uid`) | `follows` | `allow read: if request.auth != null` ✅ |
| Read following (`followerId == uid`) | `follows` | `allow read: if request.auth != null` ✅ |
| Read any user profile (display name + avatar) | `users` | `allow read: if request.auth != null` ✅ |

All four access patterns are fully covered by existing rules. **No changes to `schema/firestore.rules` are required.**

| Deliverable | Status |
|---|---|
| `firebase-schema.md` — profile posts query pattern documented; follows query patterns expanded | ✅ Done |
| `firestore.indexes.json` — composite index (`userId ASC`, `createdAt DESC`) already present; no new entry needed | ✅ Confirmed |
| `firestore.rules` — all four access patterns covered by existing `allow read` rules | ✅ No change needed |

---

## Firestore Rules Audit — SOCAA-516 Chat

**Audit date:** 2026-05-26
**Classification:** Safe — additive only. Two new collections (`conversations`, `conversations/{id}/messages`). No existing data migration required.

### Collections Affected

| Collection | Change | Notes |
|---|---|---|
| `conversations` | New collection | One document per DM thread; participants listed in `participantIds` array |
| `conversations/{id}/messages` | New subcollection | One document per message; access gated on parent conversation participation |

### Rules Coverage

| Operation | Collection | Who | Rule Added |
|---|---|---|---|
| Read conversation list | `conversations` | Participant | `allow read` when `request.auth.uid in resource.data.participantIds` ✅ |
| Create conversation | `conversations` | Authenticated user (participant) | `allow create` when `request.auth.uid in request.resource.data.participantIds` ✅ |
| Update conversation (lastMessage, unreadCounts) | `conversations` | Participant | `allow update` when `request.auth.uid in resource.data.participantIds` ✅ |
| Read messages | `conversations/{id}/messages` | Participant of parent conversation | `allow read` gated on `get(parent).data.participantIds` ✅ |
| Send message | `conversations/{id}/messages` | Participant of parent conversation | `allow create` gated on `get(parent).data.participantIds` and `senderId == auth.uid` ✅ |

### Composite Index

| Collection | Fields | Required | Reason |
|---|---|---|---|
| `conversations` | `participantIds ARRAY_CONTAINS`, `lastMessageAt DESC` | **Yes** | `arrayContains` filter combined with `orderBy` on a different field requires a composite index |

| Deliverable | Status |
|---|---|
| `firebase-schema.md` — `conversations` and `conversations/{id}/messages` collections added | ✅ Done |
| `firestore.rules` — conversations + messages rules added | ✅ Done |
| `firestore.indexes.json` — composite index (`participantIds CONTAINS`, `lastMessageAt DESC`) added | ✅ Done |

---

## Firestore Rules Audit — SOCAA-511 Like/Unlike Posts

**Audit date:** 2026-05-26
**Classification:** Safe — additive only. New `likes` collection + new `likeCount` field on `posts`. No existing data migration required.

### Collections Affected

| Collection | Change | Notes |
|---|---|---|
| `posts` | Added `likeCount` field (number, default 0) | Cached like count; updated atomically via `FieldValue.increment` |
| `likes` | New collection | Composite key `{userId}_{postId}` ensures uniqueness and O(1) lookup |

### Rules Coverage

| Operation | Collection | Document | Who | Rule Added |
|---|---|---|---|---|
| Write (like) | `likes` | `{userId}_{postId}` | Authenticated user (self) | `allow create` when `data.userId == request.auth.uid` ✅ |
| Delete (unlike) | `likes` | `{userId}_{postId}` | Authenticated user (self) | `allow delete` when `data.userId == request.auth.uid` ✅ |
| Read (check if liked) | `likes` | `{userId}_{postId}` | Any authenticated user | `allow read: if request.auth != null` ✅ |
| Update `likeCount` | `posts` | `{postId}` | Any authenticated user | `allow update` when `affectedKeys().hasOnly(['likeCount'])` ✅ |
| Read `likeCount` in feed | `posts` | `{postId}` | Any authenticated user | Existing `allow read: if request.auth != null` ✅ |

### Composite Index Determination

All like lookups are single-document reads using the composite key `{userId}_{postId}`. No compound queries, no `.orderBy()` — **no composite index required**.

**No entry added to `firestore.indexes.json`.**

| Deliverable | Status |
|---|---|
| `firebase-schema.md` — `likes` collection added; `likeCount` field added to `posts` | ✅ Done |
| `firestore.rules` — `likes` collection rules + `posts` `likeCount` update rule added | ✅ Done |
| `firestore.indexes.json` — no composite index required; confirmed no changes needed | ✅ Confirmed |

---

## Firestore Rules Audit — SOCAA-521 Notifications (FEAT-011)

**Audit date:** 2026-05-26
**Classification:** Safe — additive only. New `notifications` collection. No existing collection fields renamed or removed.

### Collections Affected

| Collection | Change | Notes |
|---|---|---|
| `notifications` | New collection | One document per in-app notification; recipient-scoped reads and updates |

### Rules Coverage

| Operation | Collection | Who | Rule Added |
|---|---|---|---|
| Create notification | `notifications` | Any authenticated user (actor) | `allow create` when `request.auth != null` ✅ |
| Read notifications | `notifications` | Recipient only | `allow read` when `request.auth.uid == resource.data.userId` ✅ |
| Update `isRead` | `notifications` | Recipient only | `allow update` when `request.auth.uid == resource.data.userId` and `affectedKeys().hasOnly(['isRead'])` ✅ |
| Delete notification | `notifications` | — | Denied — no `allow delete` rule ✅ |

### Composite Indexes

| Collection | Fields | Required | Reason |
|---|---|---|---|
| `notifications` | `userId ASC`, `createdAt DESC` | **Yes** | Equality filter on `userId` combined with `orderBy createdAt DESC` requires composite index |
| `notifications` | `userId ASC`, `isRead ASC` | **Yes** | Two-field equality/filter query (userId + isRead) requires composite index |

| Deliverable | Status |
|---|---|
| `firebase-schema.md` — `notifications` collection added; composite indexes table updated | ✅ Done |
| `firestore.rules` — `notifications` create/read/update-isRead rules added; delete denied | ✅ Done |
| `firestore.indexes.json` — two composite indexes added (`userId+createdAt`, `userId+isRead`) | ✅ Done |

---

## Firestore Rules Audit — SOCAA-530 BUG-002a Profile Save Permission-Denied

**Audit date:** 2026-05-26
**Classification:** Safe — additive rule only. New `allow update` on `posts` for author-owned `displayName`/`avatarUrl` fields. No field renames or removals.

### Root Cause

`ProfileFirebaseDataSource.updateProfile()` (BUG-001a fix) issues a Firestore batch write containing:
1. `users/{userId}` — update `displayName`, `bio`, `avatarUrl` — **already allowed** by the existing owner-scoped update rule.
2. `posts/{postId}` (one per post authored by the user) — update `displayName`, `avatarUrl` — **blocked**: the only existing `posts` update rule permitted `likeCount` only.

Because Firestore evaluates every write in a batch independently, the batch failed with `permission-denied` and the profile was never saved.

### Collections Affected

| Collection | Change | Notes |
|---|---|---|
| `posts` | New `allow update` rule for author-owned `displayName` and `avatarUrl` | Additive; scoped to author (`resource.data.userId == request.auth.uid`) and allowed fields only |

### Rules Coverage

| Operation | Collection | Document | Who | Rule Added |
|---|---|---|---|---|
| Update `displayName` + `avatarUrl` | `posts` | `{postId}` | Post author (`request.auth.uid == resource.data.userId`) | `allow update` when `affectedKeys().hasOnly(['displayName', 'avatarUrl'])` ✅ |
| Write `users/{userId}` profile fields | `users` | `{userId}` | Owner | Already covered by existing `allow update` for `['displayName', 'bio', 'avatarUrl', 'postCount']` ✅ |

### Composite Indexes

No new queries introduced. No composite index changes required.

| Deliverable | Status |
|---|---|
| `firebase-schema.md` — posts access patterns updated; audit section added | ✅ Done |
| `firestore.rules` — new `allow update` rule added to `posts` for author `displayName`/`avatarUrl` update | ✅ Done |
| `firestore.indexes.json` — no composite index required; no changes needed | ✅ Confirmed |

---

## Firestore Rules Audit — SOCAA-534 BUG-003 Permission-Denied on Feed Load for New Accounts

**Audit date:** 2026-05-31
**Classification:** Safe — relaxes an over-restrictive create check; adds `username` to allowed update fields. No field renames, collection removals, or access broadening beyond the intended write path.

### Root Cause

Two distinct rules defects in `users/{uid}` caused `permission-denied` for brand-new accounts:

**Defect 1 — Redundant create guard (`request.resource.data.uid == uid`)**

`auth_firebase_data_source.dart._writeUserProfile()` uses `SetOptions(merge: true)` to write the user document on first sign-in. With merge semantics Firestore evaluates the write as a CREATE when the document does not yet exist. The original create rule additionally required `request.resource.data.uid == uid`. If the Auth SDK has not yet fully propagated the new credential at the instant the write is evaluated, `request.auth` resolves to null or the JWT claim mismatch causes the guard to fail — producing `permission-denied` before the document is ever created. The guard is also redundant: `request.auth.uid == uid` (the document-path uid) already guarantees ownership.

**Defect 2 — Missing `username` in owner update allowed fields**

`_writeUserProfile` writes `username` via `SetOptions(merge: true)`. When the `users/{uid}` document already exists (e.g. Google re-sign-in for an existing account), Firestore evaluates the operation as an UPDATE. The existing owner update rule only permitted `['displayName', 'bio', 'avatarUrl', 'postCount']`. Because `username` was not listed, the merge-write was rejected with `permission-denied`.

The feed load `permission-denied` is a downstream consequence: if `_writeUserProfile` fails and throws, `signUpWithEmail` propagates the error and the session state is corrupted, causing subsequent Firestore queries from `PostsFeedBloc` to run under an invalid or missing auth token.

### Collections Affected

| Collection | Change | Classification |
|---|---|---|
| `users` | Removed redundant `&& request.resource.data.uid == uid` from `allow create` | Safe — narrows the create guard, not broadens it |
| `users` | Added `'username'` to `allow update` `hasOnly([...])` list | Safe — allows writing a field already defined in the schema |

### Rules Coverage

| Operation | Collection | Document | Who | Rule Change |
|---|---|---|---|---|
| Create user document on first sign-in | `users` | `{uid}` | Owner (`request.auth.uid == uid`) | Removed redundant `request.resource.data.uid == uid` check ✅ |
| Update `username` field | `users` | `{uid}` | Owner | Added `'username'` to `hasOnly([...])` in owner update rule ✅ |

### Composite Indexes

No new queries introduced. No composite index changes required.

| Deliverable | Status |
|---|---|
| `firebase-schema.md` — users access patterns updated; audit section added | ✅ Done |
| `firestore.rules` — `users/{uid}` create rule simplified; `username` added to owner update allowed fields | ✅ Done |
| `firestore.indexes.json` — no composite index required; no changes needed | ✅ Confirmed |

---

## Firestore Rules Audit — SOCAA-576 BUG-016 Remove Snapshot avatarUrl from Notification Documents

**Audit date:** 2026-06-01
**Classification:** BREAKING — removes `actorPhotoUrl` field from notification document definition. Any existing code reading `notification.actorPhotoUrl` must be updated (Flutter IMPL ticket handles the client-side change).

### Root Cause

Notification documents stored `actorPhotoUrl` as a snapshot at write time (captured from `users/{actorId}.photoUrl` when the notification was created). Two problems:

1. **Wrong field name at write time:** The write path read `actorData['photoUrl']` but the `users` collection stores the avatar as `avatarUrl`. The mismatch meant `actorPhotoUrl` was always `null` in practice.
2. **Stale snapshot:** Even if the field name were correct, the snapshot would go stale whenever the actor updates their profile picture. The correct pattern is a UI-side join: read `users/{actorId}.avatarUrl` at display time.

### Collections Affected

| Collection | Change | Classification |
|---|---|---|
| `notifications` | **BREAKING** — `actorPhotoUrl` field removed | UI must join `users/{actorId}` at read time instead of reading a snapshot field |

**Migration path:** No Firestore migration is required — the field was always `null` in practice due to the wrong source field name. New notification documents will not include `actorPhotoUrl`. Existing documents that happen to have the field will simply have an unused field; they do not need to be backfilled or deleted.

### `actorId` Verification

`actorId` is present and correctly stored on all notification documents:
- Follow notifications: `follows_firebase_data_source.dart` stores `actorId: followerId` ✅
- Like notifications: `posts_firebase_data_source.dart` stores `actorId: userId` ✅

The UI must join `users/{actorId}` at read time to display the actor's current `avatarUrl`.

### Rules Coverage

| Operation | Collection | Document | Who | Rule |
|---|---|---|---|---|
| Read notifications | `notifications` | `{notificationId}` | Recipient owner | `allow read` when `request.auth.uid == resource.data.userId` ✅ — no change needed |
| Write notification | `notifications` | `{notificationId}` | Any authenticated actor | `allow create` when `request.auth != null` ✅ — no change needed |
| Update `isRead` | `notifications` | `{notificationId}` | Recipient owner | `allow update` scoped to `['isRead']` ✅ — no change needed |
| Read actor profile | `users` | `{actorId}` | Any authenticated user | `allow read: if request.auth != null` ✅ — already covered |

**No changes to `schema/firestore.rules` are required.** The rules never referenced `actorPhotoUrl`, and the `users` read rule already covers the UI-side `users/{actorId}` join.

### Composite Index Determination

The notification queries remain unchanged (flat `notifications` collection, `userId` equality filter + `createdAt DESC` orderBy, and `userId` + `isRead` filter). Both composite indexes already in `firestore.indexes.json` are still required and correct. **No changes to `firestore.indexes.json`.**

| Deliverable | Status |
|---|---|
| `firebase-schema.md` — `actorPhotoUrl` removed from notifications field table; `actorId` join note added | ✅ Done |
| `schema/firestore.rules` — no changes required; rules confirmed consistent with `actorId`-only pattern | ✅ Confirmed |
| `firestore.indexes.json` — existing composite indexes unchanged; no new index required | ✅ Confirmed |

---

## Firestore Rules Audit — SOCAA-586 BUG-019: Remove Stored Counter Fields

**Audit date:** 2026-06-01
**Classification:** BREAKING — removes `postCount`, `followerCount`, `followingCount` from `users`; removes `likeCount` from `posts`. Counts are now derived dynamically via Firestore count queries.

### Migration Path

No Firestore data migration is required. The removed fields are additive counters that were maintained client-side. Existing documents that still contain these fields will simply have unused fields; they do not need to be backfilled or deleted. The dynamic count queries ride on existing `allow read: if request.auth != null` rules already in place for `posts`, `follows`, and `likes`.

### Collections Affected

| Collection | Field Removed | Replacement Query |
|---|---|---|
| `users` | `postCount` | `posts.where('userId', '==', uid).count()` |
| `users` | `followerCount` | `follows.where('followeeId', '==', uid).count()` |
| `users` | `followingCount` | `follows.where('followerId', '==', uid).count()` |
| `posts` | `likeCount` | `likes.where('postId', '==', postId).count()` |

### Rules Changes

| Rule Removed | Collection | Reason |
|---|---|---|
| `hasOnly(['followerCount', 'followingCount'])` update block | `users` | Counter writes no longer occur; rule deleted entirely |
| `'postCount'` removed from owner update `hasOnly([...])` list | `users` | `postCount` no longer a valid field |
| `hasOnly(['likeCount'])` update block | `posts` | Counter writes no longer occur; rule deleted entirely |

### Dynamic Count Query Rules Coverage

| Operation | Collection | Rule in Effect |
|---|---|---|
| Count posts by user (`userId == uid`) | `posts` | `allow read: if request.auth != null` ✅ — already exists |
| Count followers (`followeeId == uid`) | `follows` | `allow read: if request.auth != null` ✅ — already exists |
| Count following (`followerId == uid`) | `follows` | `allow read: if request.auth != null` ✅ — already exists |
| Count likes on post (`postId == postId`) | `likes` | `allow read: if request.auth != null` ✅ — already exists |

**No new rules required.** All count queries are covered by existing read rules.

### Composite Index Determination

All four count queries filter on a single field (`userId`, `followeeId`, `followerId`, `postId`). Firestore auto-generates single-field indexes for each of these. **No new composite index entries required.**

| Deliverable | Status |
|---|---|
| `firebase-schema.md` — `postCount`, `followerCount`, `followingCount` removed from `users`; `likeCount` removed from `posts`; BREAKING callouts added; dynamic count query patterns documented | ✅ Done |
| `schema/firestore.rules` — `postCount` removed from owner update allowed keys; `followerCount`/`followingCount` update rule deleted; `likeCount` update rule on `posts` deleted | ✅ Done |
| `firestore.indexes.json` — no new composite index required; single-field auto-indexes are sufficient | ✅ Confirmed |

---

## Firestore Rules Audit — SOCAA-593: Remove displayName/avatarUrl from posts

**Audit date:** 2026-06-02
**Classification:** BREAKING — removes `displayName` and `avatarUrl` from `posts` documents and removes the corresponding `allow update` rule that permitted author-owned profile-sync writes.

### Migration Path

No Firestore data migration is required. Post documents that still contain `displayName` or `avatarUrl` will simply have unused fields; they do not need to be backfilled or deleted. Author display info is now resolved at read time by joining `users/{userId}`.

### Collections Affected

| Collection | Field Removed | Replacement |
|---|---|---|
| `posts` | `displayName` | Resolved at read time from `users/{userId}.displayName` |
| `posts` | `avatarUrl` | Resolved at read time from `users/{userId}.avatarUrl` |

### Rules Changes

| Rule Removed | Collection | Reason |
|---|---|---|
| `allow update` for `hasOnly(['displayName', 'avatarUrl'])` | `posts` | Profile-sync batch writes no longer target post documents; rule removed entirely |

### Access Patterns

| Operation | Collection | Who | Rule in Effect |
|---|---|---|---|
| Read post | `posts/{postId}` | Any authenticated user | `allow read: if request.auth != null` ✅ — no change |
| Create post | `posts/{postId}` | Authenticated author | `allow create` when `request.auth.uid == request.resource.data.userId` ✅ — no change; `displayName`/`avatarUrl` no longer written |
| Delete post | `posts/{postId}` | Author | `allow delete` when `request.auth.uid == resource.data.userId` ✅ — no change |

### Composite Index Determination

No new queries introduced. No composite index changes required.

| Deliverable | Status |
|---|---|
| `firebase-schema.md` — `displayName` and `avatarUrl` removed from `posts` field table; BREAKING callout added; update access pattern row removed | ✅ Done |
| `schema/firestore.rules` — `allow update` rule for `displayName`/`avatarUrl` on `posts` removed | ✅ Done |
| `firestore.indexes.json` — no composite index required; no changes needed | ✅ Confirmed |

---

## Firestore Rules Audit — SOCAA-594 BUG-022: Feed Permission-Denied Verification

**Audit date:** 2026-06-02
**Classification:** Safe — verification only. No rules or indexes were changed.

### Findings

The [SOCAA-586](/SOCAA/issues/SOCAA-586) change (BUG-019: remove stored counter fields) removed only the `FieldValue.increment` update rules from `posts` and `users`. The `allow read` rules on `posts` and `follows` were **not altered**.

| Rule | Location | Status |
|---|---|---|
| `posts`: `allow read: if request.auth != null` | `schema/firestore.rules` line 55 | ✅ Present and correct |
| `follows`: `allow read: if request.auth != null` | `schema/firestore.rules` line 34 | ✅ Present and correct |
| Composite index `posts (userId ASC, createdAt DESC)` | `firestore.indexes.json` | ✅ Present and correct |

### Feed Query Access Patterns — Verified

| Operation | Who | Collection | Rule in Effect |
|---|---|---|---|
| Read posts in feed (`userId whereIn followeeIds`, `orderBy createdAt DESC`) | Authenticated user | `posts` | `allow read: if request.auth != null` ✅ |
| Read follows (`followerId == currentUid`) | Authenticated user | `follows` | `allow read: if request.auth != null` ✅ |

**No changes to `schema/firestore.rules` or `firestore.indexes.json` were required.** Both files already satisfy all acceptance criteria.

### Deploy

Rules and indexes were re-deployed to Firebase project `pulse-94821` to confirm the live state matches the repository:

```
firebase deploy --only firestore:rules,firestore:indexes
✔  cloud.firestore: rules file schema/firestore.rules compiled successfully
✔  firestore: released rules schema/firestore.rules to cloud.firestore
✔  firestore: deployed indexes in firestore.indexes.json successfully
✔  Deploy complete!
```

| Deliverable | Status |
|---|---|
| `schema/firestore.rules` — `posts` and `follows` `allow read` rules verified intact | ✅ Confirmed |
| `firestore.indexes.json` — composite index `(userId ASC, createdAt DESC)` on `posts` verified present | ✅ Confirmed |
| `firebase-schema.md` — audit section added | ✅ Done |
| Firebase deploy — rules and indexes live on `pulse-94821` | ✅ Deployed |

---

## Firestore Rules Audit — SOCAA-737 FEAT: Comments on Posts

**Audit date:** 2026-06-05
**Classification:** Safe — additive only. New `comments` collection. No existing collection fields renamed or removed.

### Collections Affected

| Collection | Change | Notes |
|---|---|---|
| `comments` | New collection | One document per comment; scoped read/create/delete rules |
| `notifications` | `type` field description updated to include `'comment'` | No schema structure change; additive |

### Rules Coverage

| Operation | Collection | Document | Who | Rule Added |
|---|---|---|---|---|
| Read comments for a post | `comments` | `{commentId}` | Any authenticated user | `allow read: if request.auth != null` ✅ |
| Create own comment | `comments` | `{commentId}` | Authenticated user | `allow create` when `request.resource.data.authorId == request.auth.uid` ✅ |
| Delete own comment | `comments` | `{commentId}` | Author | `allow delete` when `resource.data.authorId == request.auth.uid` ✅ |
| Write comment notification | `notifications` | `{notificationId}` | Any authenticated user | Existing `allow create: if request.auth != null` ✅ — no change needed |

### Composite Index

| Collection | Fields | Required | Reason |
|---|---|---|---|
| `comments` | `postId ASC`, `createdAt ASC` | **Yes** | Equality filter on `postId` combined with `orderBy createdAt ASC` requires a composite index |

| Deliverable | Status |
|---|---|
| `firebase-schema.md` — `comments` collection added; `notifications.type` description updated to include `'comment'`; composite indexes table updated | ✅ Done |
| `schema/firestore.rules` — `comments` read/create/delete rules added | ✅ Done |
| `firestore.indexes.json` — composite index (`postId ASC`, `createdAt ASC`) on `comments` added | ✅ Done |
