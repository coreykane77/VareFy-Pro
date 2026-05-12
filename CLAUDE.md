# VareFy — Alpha v0.1 System Constitution

## What VareFy Is

VareFy is a DFW-only operational trust network for service professionals.

The alpha proves one loop:

**Client books appointment → Pro arrives, assesses, and works the job → Location, timer, and proof events are recorded → Client reviews and approves completion → Payout state is created → Admin can inspect the entire thing.**

If the job is larger than expected, the pro creates an onsite estimate. The appointment closes normally. If the client accepts, a new linked work order is generated. Same engine, new intent.

This is not a marketplace. It is not a platform. It is a controlled operational trust network for a small number of real people doing real jobs in the Dallas–Fort Worth area.

Every feature should answer: **"Does this help a real service provider successfully complete a real job?"**

---

## The Ecosystem — Three Surfaces, One Backend

| Surface | Type | Audience |
|---|---|---|
| **VareFy** | iOS app (SwiftUI) | Clients — people hiring service providers |
| **VareFy Pro** | iOS app (SwiftUI) | Providers — people completing service jobs |
| **VareFy Command Center** | Web app (Next.js) | Admin / Integrity Agent / Founder |

All three surfaces are **separate codebases** but share a **single Supabase project**.

They do not share Swift code. They do not share UI components. They share database tables, storage buckets, auth roles, and server-enforced work order state.

The iOS apps speak the same data language because they read and write the same Supabase schema — not because they share any code.

---

## Locked Stack — No Revisiting Mid-Build

| Layer | Technology | Reason |
|---|---|---|
| Database | Supabase (PostgreSQL) | Relational data, auditable records, proper constraints |
| Auth | Supabase Auth | Self-signup with manual pro approval, role-based access, RLS enforcement |
| Real-time | Supabase Realtime (pg_notify) | Both apps watch the same work order row |
| File Storage | Supabase Storage | Pre/post photos, receipts, profile images |
| Server Logic | Supabase Edge Functions (Deno) | State transition validation, Stripe webhooks |
| Payments | Stripe Connect Express | Platform account, pro payouts, test mode → live |
| Chat | Stream Chat (stream-chat-swift / Stream Chat React) | Production-grade messaging — delivery, history, read receipts, typing indicators |
| iOS (both apps) | SwiftUI + MVVM + supabase-swift SDK | Consistent with existing codebase |
| Command Center | Next.js + Supabase JS client + Stream Chat React | Simple, deployable to Vercel, admin-only |

Supabase is the single source of truth. Local state in the iOS apps reflects Supabase state. It does not replace it.

---

## Database Schema — Source of Truth

All table and column names are canonical. iOS models and Command Center queries must match these names exactly.

### `profiles`
Extends `auth.users`. Created automatically on signup via Edge Function.

```sql
id                    UUID  PRIMARY KEY  REFERENCES auth.users(id)
role                  TEXT  NOT NULL     -- 'client' | 'pro' | 'admin' | 'integrity_agent'
display_name          TEXT  NOT NULL
email                 TEXT  NOT NULL
phone                 TEXT
avatar_storage_path   TEXT
stripe_connect_id     TEXT              -- pros only
stripe_connect_status TEXT              -- 'pending' | 'active' | 'restricted' | null
approval_status       TEXT  DEFAULT 'approved'
  -- pros: 'pending' on signup, set to 'approved' or 'rejected' by admin
  -- clients: 'approved' automatically on signup
invite_code_used      TEXT              -- deprecated, retained for history
is_verified           BOOL  DEFAULT false
created_at            TIMESTAMPTZ DEFAULT now()
updated_at            TIMESTAMPTZ DEFAULT now()
```

### `invite_codes`
**Deprecated — no longer used for signup.** Table is retained but inactive. Do not build new features against it.

```sql
code          TEXT  PRIMARY KEY
role          TEXT  NOT NULL     -- 'client' | 'pro'
used          BOOL  DEFAULT false
used_by       UUID  REFERENCES profiles(id)
used_at       TIMESTAMPTZ
created_by    UUID  REFERENCES profiles(id)
created_at    TIMESTAMPTZ DEFAULT now()
```

### `service_categories`

```sql
id          UUID  PRIMARY KEY DEFAULT gen_random_uuid()
name        TEXT  NOT NULL
description TEXT
active      BOOL  DEFAULT true
created_at  TIMESTAMPTZ DEFAULT now()
```

### `work_orders`
The core entity. All state transitions happen here.

```sql
id                   UUID  PRIMARY KEY DEFAULT gen_random_uuid()
client_id            UUID  NOT NULL REFERENCES profiles(id)
pro_id               UUID  REFERENCES profiles(id)   -- null until accepted
status               TEXT  NOT NULL DEFAULT 'pending'
  -- VALID: 'pending' | 'ready_to_navigate' | 'en_route' | 'arrived'
  --        'pre_work' | 'active_billing' | 'paused' | 'post_work'
  --        'client_review' | 'completed' | 'disputed' | 'cancelled'
service_title        TEXT  NOT NULL
service_category_id  UUID  REFERENCES service_categories(id)
address              TEXT  NOT NULL
latitude             FLOAT8
longitude            FLOAT8
hourly_rate          FLOAT8 NOT NULL
client_notes         TEXT
scheduled_at         TIMESTAMPTZ NOT NULL
radius_expanded      BOOL  DEFAULT false
paused_return_status TEXT              -- state to return to on resume

-- Billing (server-anchored, never device clock)
billing_start_at        TIMESTAMPTZ     -- set when active_billing begins
billing_paused_at       TIMESTAMPTZ     -- set when paused
elapsed_billing_seconds FLOAT8 DEFAULT 0  -- accumulated across pauses

-- Review window (auto-release if client doesn't act within 2 hours)
review_deadline  TIMESTAMPTZ     -- set to now() + 2h when status → client_review

-- Totals (computed and stored at completion for record integrity)
labor_total      FLOAT8 DEFAULT 0
materials_total  FLOAT8 DEFAULT 0
total_paid       FLOAT8 DEFAULT 0

-- Payment
payout_status             TEXT DEFAULT 'unpaid'
  -- VALID: 'unpaid' | 'pending' | 'processing' | 'paid' | 'disputed' | 'failed'
stripe_payment_intent_id  TEXT
stripe_transfer_id        TEXT

-- Estimate linkage
estimate_id  UUID REFERENCES estimates(id)  -- set if this work order was spawned from an accepted estimate

-- Materials advance (set when work order is spawned from an accepted estimate with deposit enabled)
materials_advance_amount  FLOAT8 DEFAULT 0
materials_advance_status  TEXT DEFAULT 'none'
  -- VALID: 'none' | 'pending' | 'release_requested' | 'released' | 'disputed'

-- Queue visibility: ready_to_navigate jobs spawned from estimates are hidden until scheduled_at::date = current_date
response_deadline  TIMESTAMPTZ  -- set to created_at + 90 min at booking time
review_deadline    TIMESTAMPTZ  -- set to now() + 2h when status → client_review

created_at    TIMESTAMPTZ DEFAULT now()
updated_at    TIMESTAMPTZ DEFAULT now()
completed_at  TIMESTAMPTZ
```

### `timeline_events`
Append-only. Never delete or modify records.

```sql
id             UUID  PRIMARY KEY DEFAULT gen_random_uuid()
work_order_id  UUID  NOT NULL REFERENCES work_orders(id)
event_type     TEXT  NOT NULL
  -- VALID: 'confirmed' | 'arrived' | 'radius_expanded' | 'started'
  --        'paused' | 'auto_paused' | 'resumed' | 'completed'
  --        'client_approved' | 'client_disputed'
  --        'admin_override' | 'payout_initiated' | 'payout_completed'
  --        'estimate_sent' | 'estimate_accepted' | 'estimate_declined' | 'estimate_expired'
  --        'materials_advance_requested' | 'materials_advance_released' | 'materials_advance_disputed'
actor_id       UUID  REFERENCES profiles(id)
actor_role     TEXT              -- 'pro' | 'client' | 'admin' | 'system'
metadata       JSONB             -- flexible extra data per event type
occurred_at    TIMESTAMPTZ DEFAULT now()
```

### `work_order_photos`

```sql
id             UUID  PRIMARY KEY DEFAULT gen_random_uuid()
work_order_id  UUID  NOT NULL REFERENCES work_orders(id)
uploaded_by    UUID  NOT NULL REFERENCES profiles(id)
photo_type     TEXT  NOT NULL
  -- 'pre' | 'post'
  -- 'materials_invoice' | 'materials_quote' | 'materials_proof' | 'materials_delivery'
storage_path   TEXT  NOT NULL
uploaded_at    TIMESTAMPTZ DEFAULT now()
```

### `material_items`

```sql
id                    UUID  PRIMARY KEY DEFAULT gen_random_uuid()
work_order_id         UUID  NOT NULL REFERENCES work_orders(id)
description           TEXT  NOT NULL
amount                FLOAT8 NOT NULL
receipt_storage_path  TEXT
added_by              UUID  REFERENCES profiles(id)
created_at            TIMESTAMPTZ DEFAULT now()
```

### `estimates`
Created by a pro during an active appointment when larger scope is identified. Timer continues running during estimate creation — the appointment is always a billable work order regardless of estimate outcome.

```sql
id                        UUID  PRIMARY KEY DEFAULT gen_random_uuid()
work_order_id             UUID  NOT NULL REFERENCES work_orders(id)  -- the appointment that spawned it
estimated_hours           FLOAT8 NOT NULL
estimated_materials       FLOAT8 NOT NULL DEFAULT 0
estimated_total           FLOAT8 NOT NULL  -- computed and stored at creation
proposed_start_date       TIMESTAMPTZ NOT NULL
materials_deposit_enabled BOOL DEFAULT false
materials_deposit_amount  FLOAT8 DEFAULT 0
status                    TEXT NOT NULL DEFAULT 'pending'
  -- VALID: 'pending' | 'accepted' | 'declined' | 'expired'
client_response_at        TIMESTAMPTZ
linked_work_order_id      UUID REFERENCES work_orders(id)  -- populated when client accepts
created_at                TIMESTAMPTZ DEFAULT now()
```

**Estimate rules:**
- Timer on the originating appointment continues while estimate is being created and discussed
- Originating appointment closes normally (its own billing, photos, payout) regardless of estimate outcome
- If client accepts: system generates a new linked work order with status `ready_to_navigate`, hidden from pro queue until `scheduled_at::date = current_date`
- If client declines: pro still paid for the appointment visit — no penalty
- If client does not respond within 48 hours: status → `expired`

### `transactions`
Financial record. Created at completion. Updated by Stripe webhooks.

```sql
id                        UUID  PRIMARY KEY DEFAULT gen_random_uuid()
work_order_id             UUID  NOT NULL REFERENCES work_orders(id)
pro_id                    UUID  NOT NULL REFERENCES profiles(id)
transaction_type          TEXT  NOT NULL  -- 'labor' | 'materials' | 'materials_advance' | 'payout' | 'refund' | 'adjustment'
amount                    FLOAT8 NOT NULL
status                    TEXT  DEFAULT 'pending'
  -- VALID: 'pending' | 'processing' | 'completed' | 'failed' | 'cancelled'
stripe_payment_intent_id  TEXT
stripe_transfer_id        TEXT
stripe_payout_id          TEXT
is_instant                BOOL  DEFAULT false
fee_amount                FLOAT8 DEFAULT 0
net_amount                FLOAT8
created_at                TIMESTAMPTZ DEFAULT now()
updated_at                TIMESTAMPTZ DEFAULT now()
```

### `favorites`
Client saves a pro as a favorite. Anonymous to the pro — they see a count, not the client's identity.

```sql
id          UUID  PRIMARY KEY DEFAULT gen_random_uuid()
client_id   UUID  NOT NULL REFERENCES profiles(id)
pro_id      UUID  NOT NULL REFERENCES profiles(id)
created_at  TIMESTAMPTZ DEFAULT now()
UNIQUE(client_id, pro_id)
```

### `location_events`
GPS and radius event log for the pro during active jobs.

```sql
id             UUID  PRIMARY KEY DEFAULT gen_random_uuid()
work_order_id  UUID  NOT NULL REFERENCES work_orders(id)
pro_id         UUID  NOT NULL REFERENCES profiles(id)
event_type     TEXT  NOT NULL  -- 'entered_radius' | 'exited_radius' | 'auto_paused'
latitude       FLOAT8
longitude      FLOAT8
accuracy       FLOAT8
occurred_at    TIMESTAMPTZ DEFAULT now()
```

### Chat — Stream (not Supabase)
Chat is handled entirely by Stream. There are no chat tables in Supabase.

**Channel convention:** One Stream channel per work order. Channel ID = `work_order_{work_order_id}`.

**User identity:** Stream user IDs match Supabase user IDs (same UUID). On first auth, the app creates or updates the Stream user using the Supabase profile's `id`, `display_name`, and `avatar_storage_path`.

**Members:** Each channel is created with the client and pro as members when the work order is accepted. Admin and integrity_agent users can be added as silent observers via the Stream dashboard or server token.

**SDKs:**
- iOS (both apps): `stream-chat-swift`
- Command Center: Stream Chat React SDK (or Stream dashboard for alpha visibility)

**What Stream handles (do not rebuild in Supabase):**
- Message delivery and persistence
- Read receipts
- Typing indicators
- Message history and pagination
- Photo/file attachments
- Unread counts and badges
- Push notification triggers (Phase 2)

---

## Work Order State Machine

Status transitions are validated server-side via Edge Functions. The client sends an intent. The server confirms or rejects it.

```
pending
  → ready_to_navigate    (pro confirms job)

ready_to_navigate
  → en_route             (pro taps Drive)

en_route
  → arrived              (pro confirms arrival)
  → pre_work             (auto, immediately after arrived)

pre_work
  → active_billing       (Start Work — requires pre photo count >= 2)
  → paused               (manual pause during pre_work)

active_billing
  → paused               (manual pause or auto-pause from radius exit)
  → post_work            (Complete Work)

paused
  → active_billing       (resume — if paused_return_status was active_billing)
  → pre_work             (resume — if paused_return_status was pre_work)

post_work
  → client_review        (Submit — requires post photo count >= 2)

client_review
  → completed            (client approves)
  → disputed             (client disputes)

disputed
  → completed            (admin resolves in pro's favor)
  → cancelled            (admin resolves in client's favor)

completed   → [terminal]
cancelled   → [terminal]
```

**Auto-release rule:**
When status transitions to `client_review`, `review_deadline = now() + INTERVAL '2 hours'` is written server-side. A pg_cron job sweeps every 15 minutes for orders where `status = 'client_review' AND review_deadline < now()` and auto-transitions them to `completed` with `actor_role = 'system'` and `metadata = { auto_released: true }`. Both parties receive a push notification. This protects pros from being held in limbo by non-responsive clients.

**Rules enforced server-side:**
- Drive requires status == ready_to_navigate
- Arrival requires status == en_route
- Start Work requires status == pre_work AND pre photo count >= 2
- Complete Work requires status == active_billing
- Submit Completion requires status == post_work AND post photo count >= 2
- Billing timestamps written by server, not device clock
- Timeline events are system-generated on all transitions
- Estimate-spawned work orders: status = ready_to_navigate, hidden from pro queue until scheduled_at::date = current_date

---

## Estimate Flow

The estimate is a proposal created by a pro during an active appointment when the job turns out to be larger than the initial booking. It does not interrupt the appointment — the timer keeps running.

```
Pro during active_billing
  → taps "Create Estimate"
  → fills: estimated_hours, estimated_materials, proposed_start_date
  → optionally enables materials deposit + amount
  → taps Send

estimate.status = 'pending'
timeline_event: 'estimate_sent' on originating work_order_id
client notified (push)

Appointment continues and closes normally:
  active_billing → post_work → client_review → completed
  (independent of estimate outcome)

Client reviews estimate:

  If accepted:
    estimate.status = 'accepted'
    timeline_event: 'estimate_accepted'
    new work_order created:
      - status = 'ready_to_navigate'
      - estimate_id = estimate.id
      - materials_advance_amount = estimate.materials_deposit_amount (if enabled)
      - materials_advance_status = 'pending' (if deposit enabled), else 'none'
      - scheduled_at = estimate.proposed_start_date
      - hidden from pro queue until scheduled_at::date = current_date
    estimate.linked_work_order_id = new work_order id

  If declined:
    estimate.status = 'declined'
    timeline_event: 'estimate_declined'
    originating appointment already closed and paid — no penalty to pro

  If no response in 48 hours:
    estimate.status = 'expired' (system sweep)
    timeline_event: 'estimate_expired'

Materials advance flow (on linked work order, if deposit enabled):
  materials_advance_status = 'pending'    (client accepted, funds not yet released)

  Pro taps "Request Materials Advance":
    → optional note, supplier invoice, quote, custom order proof
    → evidence uploaded to work_order_photos (photo_type: materials_invoice | materials_quote | materials_proof)
    → materials_advance_status = 'release_requested'
    → timeline_event: 'materials_advance_requested' + metadata

  Integrity Agent reviews in Command Center → approves:
    → materials_advance_status = 'released'
    → timeline_event: 'materials_advance_released' + actor_id + reason
    → Stripe transfer initiated (Phase 12)

  If client disputes:
    → materials_advance_status = 'disputed'
    → timeline_event: 'materials_advance_disputed'
    → Integrity Agent reviews evidence
    → 50% markup cap enforced: disputed amount above 150% of verified cost is returned to client
    → no receipt = Integrity Agent determines reasonable value
```

---

## Auth Model

Invite codes are retired. Pros self-signup and require manual founder approval before accessing the app. Clients sign up and get immediate access.

**Pro signup flow:**
1. Pro opens VareFy Pro → enters name, email, password, phone, service category
2. `signup` Edge Function creates Supabase Auth account + `profiles` row with `role = 'pro'` and `approval_status = 'pending'`
3. Pro sees a "Your application is under review" screen — no access to jobs or wallet
4. Founder reviews profile in Command Center → approves or rejects
5. On approval, `approval_status` set to `'approved'` — pro gets full access on next app open
6. Pro proceeds to onboarding (profile photo, Stripe Connect)

**Client signup flow:**
1. Client opens VareFy → enters name, email, password
2. `signup` Edge Function creates account + `profiles` row with `role = 'client'` and `approval_status = 'approved'`
3. Client has immediate access — no review step

**Roles:**
- `client` — can create work orders, view and approve assigned pro work
- `pro` — can view and accept assigned work orders, run the full job flow (requires `approval_status = 'approved'`)
- `admin` — full read/write across all tables (Command Center only)
- `integrity_agent` — read access + payout and dispute write access (Command Center only)

**Row-Level Security** is enforced at the database level, not in app code:
- Clients see only their own work orders
- Pros see only work orders assigned to them, and only if `approval_status = 'approved'`
- Admins and integrity agents see everything

---

## Pro Response Requirement

When a client books a job, the assigned pro has **90 minutes** to respond before the job is flagged for admin attention.

**Rules:**
- `work_orders` stores a `response_deadline` timestamp set to `created_at + 90 minutes` at booking time
- The "Confirm Job" button in VareFy Pro is locked until the pro has sent **at least one chat message** to the client — chat first, then accept
- The 90-minute countdown is visible on the pending job card in VareFy Pro
- Expiry does NOT auto-cancel the job — it flags it for the admin in Command Center
- Admin manually decides: extend the window, reassign, or cancel (no automated reassignment during alpha)

**Why chat-first before confirm:**
- Forces a human acknowledgment before commitment
- Client knows the pro has seen the job
- Mirrors TaskRabbit's pattern but without the hard 1-hour auto-cancel that would leave clients stranded in a small-roster network

**Command Center action at expiry:**
- Pending pro approval queue shows jobs past `response_deadline` highlighted
- Admin can message the pro directly or cancel and notify the client

---

## Supabase Storage Structure

```
/avatars/{user_id}/profile.jpg
/work-orders/{work_order_id}/pre/{photo_id}.jpg
/work-orders/{work_order_id}/post/{photo_id}.jpg
/work-orders/{work_order_id}/receipts/{material_item_id}.jpg
```

Photos upload directly from iOS to Supabase Storage. The storage path is saved to the database record. Status transitions that depend on photo counts check the `work_order_photos` table row count — not a local counter.

---

## Payment Architecture

Stripe Connect Express is the payment layer. The architecture assumes real money from day one even if live wiring completes in Phase 2.

**Payout states (`work_orders.payout_status`):**
- `unpaid` — job not yet completed
- `pending` — job completed, payout not yet initiated
- `processing` — payout initiated, waiting on Stripe
- `paid` — Stripe transfer confirmed
- `disputed` — under review
- `failed` — Stripe transfer failed, requires retry

**Platform account:** VareFy holds the Stripe platform account. Pros connect via Stripe Connect Express onboarding. Platform fee rate is defined before live launch. Remaining amount transfers to the pro's connected account.

**Wallet in VareFy Pro:** Reflects real payout state from the `transactions` table. Shows pending, processing, and paid amounts. No fake balance. No hardcoded numbers.

**Phase 1 (Alpha v0.1):** Full schema and payout states in place. UI shows real states. Stripe Connect onboarding flow wired. Payouts shown as `pending` while live Stripe wiring completes.

**Phase 2:** Stripe live mode, real money movement, webhook handlers confirmed end-to-end.

---

## Build Order — Alpha v0.1

Work in this order. Do not skip phases. Do not polish a later phase while an earlier one is incomplete.

| Phase | Deliverable |
|---|---|
| 1 | Supabase project setup — schema, RLS policies, storage buckets |
| 2 | Auth — self-signup, pro approval flow, role assignment |
| 3 | Work order state machine — Edge Functions, server-side transition validation |
| 4 | VareFy (client app): create work order, view status in real time |
| 5 | VareFy Pro: receive, view, and accept work orders from Supabase |
| 6 | Timer and billing — server-anchored timestamps, pause and resume |
| 7 | Photo capture and upload — pre/post gates, Supabase Storage |
| 8 | Location events — real CLLocationManager, geofence auto-pause |
| 9 | Chat — Stream channel per work order, Stream user auth, iOS SDK integration |
| 10 | Payment states — payout_status tracking, transaction record creation |
| 11 | Command Center — work orders, users, proof photos, timelines, payout state |
| 12 | Stripe Connect — live onboarding, real payout initiation |

---

## Command Center — VareFy Command Center

**Tech:** Next.js + Supabase JS client. Deployed to Vercel. Accessible to admin and integrity_agent roles only.

**Alpha v0.1 views:**
- Work order list — all orders, filterable by status
- Work order detail — full timeline, proof photos, billing summary, payout state
- **Pending pro approvals** — new pro signups awaiting review; approve or reject with one action
- **Expired response queue** — jobs where pro hasn't responded within 90 minutes; flag or reassign
- User list — clients and pros, approval status, verification status
- Proof photo review — pre and post photos per job
- Payout queue — pending payouts, initiate or flag
- Manual status override — correct stuck or invalid states during alpha
- Audit log — all timeline events across all jobs

**Rules:**
- Command Center is operational tooling. Build only what is needed to run the alpha.
- Manual override is an explicit feature, not a workaround. Build override tools deliberately.
- No auth bypass. Admin users authenticate through Supabase Auth.
- Do not build reporting, analytics, or charts until the operational tools are complete.

---

## iOS App Structure — VareFy Pro

```
VareFy Pro/
├── App/
│   └── VareFyProApp.swift
│
├── Supabase/
│   ├── SupabaseClient.swift       ← shared client instance
│   ├── AuthManager.swift          ← session, profile, sign in/out
│   └── RealtimeManager.swift      ← work order subscriptions
│
├── Core/
│   ├── Home/
│   ├── Menu/
│   ├── Drawer/
│   └── Navigation/
│
├── Features/
│   ├── Auth/
│   │   ├── SignUpView.swift        ← no invite code, self-signup
│   │   ├── SignInView.swift
│   │   ├── PendingApprovalView.swift  ← shown to pros until approved
│   │   └── OnboardingView.swift
│   │
│   ├── WorkOrders/
│   │   ├── WorkOrdersListView.swift
│   │   ├── WorkOrderDetailView.swift
│   │   ├── HireConfirmationView.swift
│   │   ├── DriveView.swift
│   │   ├── PreWorkPhotoView.swift
│   │   ├── ActiveBillingView.swift
│   │   ├── PostWorkPhotoView.swift
│   │   ├── SubmitReviewView.swift
│   │   └── CompletionSummaryView.swift
│   │
│   ├── Wallet/
│   │   ├── WalletOverviewView.swift
│   │   ├── ManagePayoutView.swift
│   │   └── WeeklyEarningsView.swift
│   │
│   ├── Chat/                      ← Stream Chat SDK
│   │   ├── ChatView.swift         ← StreamChatUI or custom wrapper
│   │   └── ChatViewModel.swift    ← Stream channel setup, token auth
│   │
│   ├── Profile/
│   ├── Messages/
│   └── Settings/
│
├── Models/                        ← Field names match Supabase column names exactly
│   ├── WorkOrder.swift
│   ├── WorkOrderStatus.swift
│   ├── TimelineEvent.swift
│   ├── UserProfile.swift
│   ├── Transaction.swift
│   └── MaterialItem.swift
│   -- ChatMessage is Stream's domain, not a local model
│
├── ViewModels/
│   ├── WorkOrderViewModel.swift   ← Supabase-backed, Realtime subscriptions
│   ├── WalletViewModel.swift      ← Real transaction records from Supabase
│   ├── ProfileViewModel.swift
│   └── AuthViewModel.swift
│
├── Services/
│   ├── LocationService.swift      ← Real CLLocationManager
│   ├── PhotoService.swift         ← Camera + Supabase Storage upload
│   ├── TimerService.swift         ← Server-anchored elapsed time display
│   └── StripeService.swift        ← Connect onboarding, payout initiation
│
├── Components/
├── Utilities/
│   ├── Extensions.swift
│   └── Constants.swift
└── Resources/
    └── Assets.xcassets
```

VareFy (client app) and Command Center follow equivalent structures for their platforms. Model names and field names match the Supabase schema across all three surfaces.

---

## Design System & Cross-App Parity

VareFy and VareFy Pro are two surfaces of one product. They share the same brand identity, visual language, and asset library. A user who has both apps should feel like they are looking at the same system from a different angle — not two different products.

### Shared Brand Assets
Both iOS apps use identical asset catalogs for all brand elements:
- **Logo mark:** `VFYX` — lime green, transparent background
- **Wordmark:** `VareFy` — shared across both apps
- **Navigation icons:** `"3"` (Waze), `"4"` (Google Maps) — identical in both apps
- **App icon:** Same base icon, differentiated only by the "Pro" label on VareFy Pro
- Do not create separate versions of brand assets per app. Maintain one master asset reference and copy on update.

### Shared Color System
Both apps use the same named colors. Define them identically in each app's `Extensions.swift`:

| Token | Usage |
|---|---|
| `varefyProCyan` | Primary brand accent — tabs, highlights, CTAs |
| `varefyProLime` | Balance pill, success states, logo color |
| `varefyProGold` | BOSS badge, premium indicators, star ratings |
| `appBackground` | Primary background (dark) |
| `appCard` | Card surface |
| `appNavBar` | Navigation bar background |

### Shared Visual Language
Both apps use the same component patterns. A card in VareFy looks like a card in VareFy Pro:
- Dark theme throughout
- Rounded card surfaces (`cornerRadius: 16` for major cards, `12` for secondary)
- Same typography scale (caption → subheadline → headline → title)
- Same status pill component (same colors per status)
- Same timeline event row layout
- Same photo grid and thumbnail style
- Same primary button style
- Same slide-to-confirm interaction for high-consequence actions

### Mirrored Screens
Several screens have a direct counterpart in the other app. Both sides show the same data — role determines controls, not visibility.

| Screen | VareFy Pro (provider) | VareFy (client) |
|---|---|---|
| Work order detail | Full job info, action buttons | Same info, approval controls |
| Active job view | Timer, pause/complete controls | Live timer, pro location state |
| Chat | Send/receive thread | Same thread, flipped sender |
| Completion summary | Read-only receipt | Approve or dispute controls |
| Proof of work | Uploaded photos | Same photos, verification badge |
| Verified timeline | Full event log | Same event log |
| Billing summary | Labor + materials breakdown | Same breakdown, pay total |

**Rule:** If data is visible to one side, it is visible to both sides. Role controls what actions you can take — not what information you can see. Both parties look at the same record.

### Command Center Parity
Command Center shows the same data as both apps combined — the admin view is the union of both perspectives on every work order.

---

## Ground Rules

**State:**
- Supabase is the source of truth. ViewModels reflect it — they do not replace it.
- Billing timers are anchored to server timestamps (`billing_start_at`). Device clock is used only for display math (elapsed seconds = now - billing_start_at + accumulated).
- Status transitions happen on the server. The app sends an intent. The server confirms or rejects.
- Timeline events are written by the server on every transition. Apps do not write timeline events directly.

**Photos:**
- Photos upload to Supabase Storage before the status transition that depends on them.
- Pre-work and post-work gates check the `work_order_photos` row count in Supabase — not a local counter.
- Never block the upload on status. Allow upload. Gate the transition.

**Data integrity:**
- Timeline events are append-only. Never delete or update them.
- Completed work order financials (`labor_total`, `materials_total`, `total_paid`) are written at completion and locked. They are a permanent record, not a live calculation.
- Transaction records are created at completion and updated only by Stripe webhook events.

**Alpha scope:**
- DFW only. No national assumptions, no geo-expansion scaffolding in code.
- Admin manual oversight is a feature, not a workaround. Build for it explicitly.
- Build for 10–50 concurrent users. Not 10,000.
- No automation that replaces human judgment during the alpha.

**Code:**
- No hardcoded demo data in production builds.
- No mock services in production builds.
- If a feature is not yet wired to the real backend, it shows a real pending state — not fake data.
- Business rules live in ViewModels and Edge Functions, not in Views.
- Views reflect state. They do not produce it.

## Push Notifications

**Blocked on:** APNs key (.p8) must be generated from Apple Developer portal. App IDs are already registered.

**Stack:** Stream Chat handles chat push natively once APNs key is added to Stream dashboard. All other notifications go through one `send-push` Supabase Edge Function calling APNs directly. Device tokens stored in `profiles.device_token`.

**Triggers and recipients:**

| Event | Recipient |
|---|---|
| New job assigned | Pro |
| Pro account approved | Pro |
| Job confirmed by pro | Client |
| Pro arrived | Client |
| Pro left the jobsite | Client |
| Pro returned to jobsite | Client |
| Submitted for review (2h countdown starts) | Client |
| Auto-released after 2h | Pro + Client |
| Job approved by client | Pro |
| New chat message | Both (Stream) |
| Favorited (anonymous) | Pro |
| Day-before reminder (9am Central) | Pro + Client |
| Day-of reminder (9am Central) | Pro + Client |

Reminders use pg_cron scheduled jobs, not event triggers. Both run at 9am Central (14:00 UTC; 15:00 UTC Nov–Mar). Only fire for orders not in a terminal state.

Full implementation spec: see memory file `project_push_notifications.md`.

---

**What we are not building in Alpha v0.1:**
- Automated dispute resolution
- Rating and review system
- Push notifications (Phase 2)
- In-app client payment collection
- Advanced fraud detection
- Analytics and reporting dashboards
- National scale infrastructure
- AI-assisted job matching or scheduling

---

## App Identity

- **VareFy Pro** — provider iOS app — bundle: `com.varefypro.app`
- **VareFy** — client iOS app — bundle: `com.VarefyClient`
- **VareFy Command Center** — web — deployed to `command.varefypro.com` or equivalent

VareFy and VareFy Pro are the public-facing names. Do not use ANKR in any user-facing surface. Internal code history references ANKR as legacy only.

---

## Current Status

VareFy Pro contains a functional SwiftUI prototype with a complete in-memory job flow. All prototype screens are navigable and reflect the correct state machine.

**Immediate next step:** Supabase project setup and schema creation (Phase 1).

The prototype serves as the UI and flow reference. This document is the operational target.

Migrate in phase order. Wire real data into existing screens rather than rebuilding screens for polish during migration. The screens are correct. The data layer is what changes.
