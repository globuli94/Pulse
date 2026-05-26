# Firebase Schema — Pulse

**Project:** Pulse
**Classification:** Safe — rules tighten access (unauthenticated blocked); no field renames or removals.
**Last updated:** 2026-05-25

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
| `displayName` | string | required | Author's display name captured at post time |
| `avatarUrl` | string | optional | Author's avatar URL captured at post time; null if no avatar |
| `text` | string | required | Post body text |
| `imageUrl` | string | optional | Download URL for the post image in Firebase Storage; null if no image |
| `likeCount` | number | required | Cached count of likes; default 0; incremented/decremented atomically via `FieldValue.increment` |
| `createdAt` | timestamp | required | Server timestamp set on creation |

**Access Patterns:**

| Who | Operation | Condition |
|---|---|---|
| Authenticated user | Read any post | `request.auth != null` |
| Authenticated user | Create own post | `request.auth.uid == request.resource.data.userId` |
| Author | Delete own post | `request.auth.uid == resource.data.userId` |
| Any authenticated user | Update `likeCount` | `FieldValue.increment(1)` or `FieldValue.increment(-1)` — like/unlike action |

**Query Patterns:**

| Query | Index Required |
|---|---|
| No filter, order by `createdAt DESC` — global feed | No (single-field) |
| Filter `userId == X`, order by `createdAt DESC` — user post list / profile grid | **Yes** (composite: `userId ASC`, `createdAt DESC`) |

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

All lookups are single-document reads using the composite key `{userId}_{postId}`. No compound queries, no `.orderBy()` — **no composite index required**.

---

### `notifications` — path: `notifications/{notificationId}`

**Purpose:** Stores in-app notifications delivered to users when another user likes their post or follows them. Document ID is a server-generated unique ID.

**Owner:** `userId` field (Firebase Auth UID of the recipient)

| Field | Firestore Type | Required | Description |
|---|---|---|---|
| `id` | string | required | Equals the document ID; stored redundantly for client convenience |
| `userId` | string | required | Firebase Auth UID of the recipient (post owner or followed user) |
| `type` | string | required | Event type: `'like'` or `'follow'` |
| `actorId` | string | required | Firebase Auth UID of the user who triggered the event |
| `actorDisplayName` | string | required | Display name of the actor captured at event time |
| `actorPhotoUrl` | string | optional | Avatar URL of the actor at event time; null if no avatar |
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
