Claude.md

ANKR Integrity — Hire Side Prototype Spec

Purpose

Build a SwiftUI clickable prototype of the ANKR Hire experience.

This prototype simulates operational integrity rules:
    •    Drive required before arrival
    •    Arrival required before activation
    •    Two pre work photos required before Start Work
    •    Billing starts only when Start Work is pressed
    •    Leaving job radius triggers warning
    •    Two post work photos required before completion

No backend. No Stripe. No persistence beyond session.

⸻

Scope

Hire side only.

Client side is excluded from this prototype.

⸻

Core Screens

1. Hire Home Map

Primary operational hub.

UI Elements:
    •    Static map background
    •    Hamburger menu
    •    Balance pill at top — reflects WalletViewModel balance, updates immediately when a work order transitions to clientReview
    •    Central Work Orders button
    •    Online / Offline state indicator
    •    Optional filter icon

No real GPS required.

⸻

2. Left Drawer Menu

Global navigation.

Header:
    •    Profile photo
    •    Name
    •    Rating
    •    Boss badge

Menu:
    •    Messages
    •    Local Ops
    •    Wallet
    •    H2H
    •    Boss
    •    Refer

Footer:
    •    App Settings
    •    Learning

All items are tappable.

Wallet: navigates to fully implemented Wallet screens.
All other items (Messages, Local Ops, H2H, Boss, Refer, App Settings, Learning): open a placeholder screen showing the item title, "Prototype screen", and "Not implemented".

⸻

3. Work Orders List

Entry point to job flow.

Each card includes:
    •    Client initials
    •    Service title
    •    Address
    •    Scheduled time
    •    Status pill (Pending, En Route, Active, Client Review)

Sorted by date and time.

Use dummy data.

⸻

4. Work Order Detail

Primary job logic screen.

Sections:
    •    Job details
    •    Client notes
    •    Address
    •    Materials line item placeholder

Actions:
    •    Chat (stub)
    •    Drive
    •    Support (stub)

⸻

5. Hire Confirmation Gate

First interaction for new jobs.

Flow:
Work Orders List → Tap Pending → Show Confirmation Screen

Confirmation Screen displays:
    •    "You're hired"
    •    "Review job details to confirm"
    •    Service
    •    Client
    •    Address
    •    Scheduled time
    •    Hourly rate

Primary Button: Confirm Job

Rules:
    •    Drive is disabled until Confirm Job is pressed.
    •    Confirm logs timeline event: confirmed.
    •    Status transitions to readyToNavigate on confirm.

⸻

6. Drive Screen

Simulated GPS activation.

Rules:
    •    Confirm Job must be pressed before Drive is enabled.
    •    Drive must be tapped to enter En Route.
    •    Arrival only allowed after Drive.
    •    Simulate Arrival button transitions to arrived, then automatically to preWork.

Status states:
    •    readyToNavigate
    •    En Route
    •    Arrived

⸻

7. Pre Work Photo Gate

Integrity requirement.

UI:
    •    Minimum 2 required photo slots shown
    •    Maximum 6 photos allowed
    •    Photos displayed as horizontal thumbnails
    •    Add Photo button opens camera picker
    •    User may delete photos (tap to remove)
    •    If deletion drops below 2, gate locks again
    •    Start Work disabled until prePhotoCount >= 2

Lock message:
Required job site photos not yet uploaded.

Large Property Boundary:
    •    Button available during preWork only, before Start Work
    •    Expands job radius for this work order only
    •    Logs timeline event: radiusExpanded
    •    Radius cannot be changed after Start Work begins
    •    Expanded radius used for outside boundary warnings

Photos:
    •    Captured via camera picker
    •    If camera permission denied: show inline message "Camera access is required to add photos." with Open Settings button and Add Sample Photo fallback
    •    Stored in memory only
    •    No disk persistence
    •    Reset on app restart

⸻

8. Active Billing State

Triggered by Start Work.

Behavior:
    •    Timer begins
    •    Status shows Active Work Order
    •    Pause button
    •    Multiple pauses allowed; each pause and resume logs a timeline event
    •    Complete button locked until post photos uploaded

Billing starts only on Start Work.

⸻

9. Leave Radius Simulation

Integrity enforcement simulation.

Add toggle:
Inside radius / Outside radius

If Outside and not paused:
Display banner:
You’ve left the job area. Pause or complete your work order.

Auto pause behavior:
    •    After 10 second buffer outside radius while activeBilling, automatically pause the job.
    •    Log timeline event: autoPause.
    •    No maximum pause duration for prototype.

⸻

10. Post Work Photo Gate

Completion requirement.

UI:
    •    Minimum 2 required photo slots shown
    •    Maximum 6 photos allowed
    •    Photos displayed as horizontal thumbnails
    •    Add Photo button opens camera picker
    •    User may delete photos (tap to remove)
    •    If deletion drops below 2, gate locks again
    •    Complete disabled until postPhotoCount >= 2

Lock message:
Required post work photos not yet uploaded.

Photos:
    •    If camera permission denied: show inline message "Camera access is required to add photos." with Open Settings button and Add Sample Photo fallback
    •    Memory only. No persistence.

⸻

11. Completion Summary

On Complete:
    •    Stop timer
    •    Stop GPS simulation
    •    Transition status to Client Review
    •    Display:
    •    Total time
    •    Pre photo count
    •    Post photo count

⸻

Wallet Screens (Hire Side)

12. Wallet Overview

UI:
    •    Balance card
    •    Manage button
    •    Recent transactions preview

No Stripe integration.

⸻

13. Manage Payout

UI:
    •    Editable amount
    •    Instant Pay 1.5 percent fee
    •    Bank Transfer free
    •    Destination account row
    •    Fee disclosure
    •    Slide to confirm

Pure UI simulation.

⸻

Hourly Rate Source of Truth

    •    Rate is defined in Profile → Services → Selected Service → Hourly Rate.
    •    When a work order is created, hourlyRate is copied into the WorkOrder struct.
    •    Editing profile rate later does not affect existing work orders.
    •    Labor total = elapsedActiveBillingSeconds / 3600 × stored hourlyRate.

WorkOrder must store:
    •    serviceId
    •    hourlyRate

⸻

Wallet Balance Behavior

    •    WalletViewModel holds the current balance.
    •    Balance pill on Home Map reads from WalletViewModel.
    •    When a work order transitions to clientReview, the work order's totalPaid is immediately added to WalletViewModel balance.
    •    No escrow staging in prototype.

⸻

Work Order Summary Access

    •    Immediately after Submit Completion, navigate to Summary screen.
    •    Work Orders List shows a "View Summary" action for jobs with status clientReview.
    •    Work Order Detail shows a "Work Order Summary" button when status is clientReview.
    •    Summary screen is read only. No editing.

⸻

Error Handling

Camera permission denied:
    •    Show inline message: "Camera access is required to add photos."
    •    Button: Open Settings
    •    Provide Add Sample Photo fallback so prototype remains navigable.

Malformed or missing work order data:
    •    Show error screen: "Work order data unavailable."
    •    Button: Back to Work Orders
    •    Do not crash.

⸻

Back Navigation and Cancel

    •    Back navigation is allowed at any point.
    •    Backing out does not reset status or state.
    •    No cancel or abandon flow in prototype.

⸻

State Model

Define simple enum:

WorkOrderStatus:
    •    pending
    •    readyToNavigate
    •    enRoute
    •    arrived
    •    preWork
    •    activeBilling
    •    paused
    •    postWork
    •    clientReview

Explicit Flow:

pending
→ (tap pending job) → Confirmation Screen
→ Confirm Job
→ readyToNavigate

readyToNavigate
→ Drive
→ enRoute

enRoute
→ Simulate Arrival
→ arrived

arrived
→ automatic
→ preWork

preWork
→ Start Work (requires prePhotoCount >= 2)
→ activeBilling

activeBilling
→ Pause → paused
→ Complete Work → postWork

paused
→ Resume → returns to previous active state

postWork
→ Submit Completion (requires postPhotoCount >= 2)
→ clientReview

clientReview is terminal for prototype.

Pausing During preWork:
    •    Allowed.
    •    No billing impact.
    •    Logs timeline event.
    •    Resume returns to preWork.

Flags:
    •    hasConfirmed
    •    hasDriven
    •    isInsideRadius
    •    prePhotoCount
    •    postPhotoCount
    •    billingStartTime
    •    elapsedSeconds

Rules:
    •    Drive requires hasConfirmed.
    •    Arrival requires hasDriven.
    •    Start Work requires prePhotoCount >= 2.
    •    Complete requires postPhotoCount >= 2.
    •    Billing begins only on Start Work.
    •    Large Property Boundary only configurable during preWork, before Start Work.

⸻

Data

Use hardcoded dummy data:
    •    3 work orders
    •    Different initial statuses for demo

No backend.

⸻

Out of Scope
    •    Real escrow logic
    •    Stripe Connect
    •    KYC
    •    Messaging system
    •    Client app
    •    Background checks
    •    Persistence
    •    Real GPS

⸻

Acceptance Criteria
    •    Confirm Job must be pressed before Drive is enabled.
    •    Drive must be tapped before Arrival allowed.
    •    Arrived automatically transitions to preWork.
    •    Two pre work photos required before Start Work unlocks.
    •    Deleting photos below 2 relocks Start Work gate.
    •    Large Property Boundary only available before Start Work.
    •    Timer runs only during Active Billing.
    •    Leaving radius shows warning banner.
    •    After 10 seconds outside radius while billing, job auto pauses.
    •    Two post work photos required before Complete unlocks.
    •    Work Order Summary shown immediately after completion.
    •    Balance updates when work order reaches Client Review.
    •    Restarting app resets photo requirements and all session state.

Project Folder Structure — ANKR Hire Prototype

Architecture: SwiftUI + MVVM
No backend layer. No persistence. In memory state only.

⸻

Root Structure

ANKRHirePrototype/
│
├── App/
├── Core/
├── Features/
├── Components/
├── Models/
├── ViewModels/
├── Services/
├── Utilities/
└── Resources/

App

App/
└── ANKRHirePrototypeApp.swift

Contains:
    •    App entry point
    •    Root NavigationStack
    •    Global environment objects if needed

Core

Shared high level app shells.

Core/
├── Home/
│   ├── HireHomeView.swift
│   └── MapBackgroundView.swift
│
├── Drawer/
│   ├── DrawerMenuView.swift
│   └── DrawerHeaderView.swift
│
└── Navigation/
    └── AppRouter.swift (optional)

Features

Organized by functional domain.

Features/
│
├── WorkOrders/
│   ├── WorkOrdersListView.swift
│   ├── WorkOrderCardView.swift
│   ├── WorkOrderDetailView.swift
│   ├── HireConfirmationView.swift
│   ├── DriveView.swift
│   ├── PreWorkPhotoView.swift
│   ├── ActiveBillingView.swift
│   ├── PostWorkPhotoView.swift
│   └── CompletionSummaryView.swift
│
├── Wallet/
│   ├── WalletOverviewView.swift
│   ├── ManagePayoutView.swift
│   └── WeeklyEarningsView.swift
│
└── Profile/
    ├── HireProfileView.swift
    └── PublicProfileView.swift

Keep screens shallow. Avoid nested over abstraction.

Models

Pure data structs only.

Models/
├── WorkOrder.swift
├── WorkOrderStatus.swift
├── Transaction.swift
└── UserProfile.swift
No networking logic inside models.

ViewModels

State logic only.

ViewModels/
├── WorkOrderViewModel.swift
├── WalletViewModel.swift
└── ProfileViewModel.swift
Rules:
    •    All integrity rules live inside WorkOrderViewModel.
    •    Photo counts stored in memory arrays.
    •    Timer logic handled here.

Services

Mock only.

Services/
├── LocationServiceMock.swift
├── PhotoServiceMock.swift
└── TimerService.swift
No real persistence.
No external SDKs.

Reusable UI pieces.

Components/
├── StatusPillView.swift
├── PrimaryButton.swift
├── SlideToConfirmView.swift
├── StatCardView.swift
└── BannerWarningView.swift
Keep visual system centralized here.

Utilities

Light helpers.

Utilities/
├── Extensions.swift
└── Constants.swift

Resources

Resources/
├── Assets.xcassets
└── PreviewData.swift
PreviewData holds:
    •    Dummy work orders
    •    Dummy user
    •    Dummy transactions

⸻

Development Rules
    •    No disk writes.
    •    No SwiftData.
    •    No network layer.
    •    All state resets on app restart.
    •    Business rules live in ViewModels, not Views.
    •    Views reflect state only.

Work Order Summary Screen

Purpose
Post completion integrity receipt. This is the proof layer of ANKR.

Scrollable vertical layout using ScrollView.

No collapsing sections. No tabs. No cramming.

⸻

Layout Structure (Top to Bottom)

1. Header Section
    •    Work Order ID
    •    Date
    •    Verified badge
    •    Hire profile row:
    •    Profile image
    •    Name
    •    Business name
    •    Verified Hire • ID number

Optional:
Location Verified Throughout Job badge

⸻

2. Labor Section

Title: LABOR

Rows:
    •    Time on Site (formatted)
    •    Hourly Rate
    •    Labor Total

Formatting:
    •    Clear separation
    •    Large readable totals

⸻

3. Materials & Supplies

Title: MATERIALS & SUPPLIES
    •    Materials amount
    •    Approval status indicator
    •    Approved checkmark if applicable

This matches your fixed materials line item decision.

⸻

4. Verified Timeline

Title: VERIFIED TIMELINE

Chronological list:
    •    Arrived (GPS) with timestamp
    •    Started Work
    •    Paused
    •    Resumed
    •    Completed

Each row:
    •    Icon
    •    Label
    •    Time aligned right

This is core integrity evidence.

⸻

5. Proof of Work

Title: PROOF OF WORK

Subsections:
    •    Before Work
    •    After Completion

Display:
    •    Horizontal image thumbnails
    •    Tap to enlarge optional
    •    Check indicator if minimum met

No editing allowed here. This is record only.

⸻

6. Total Summary

Title: TOTAL SUMMARY

Rows:
    •    Labor
    •    Materials & Supplies
    •    Total

Final row:
Total Paid

Make this visually strong but not flashy.

⸻

Prototype Implementation Notes
    •    Entire screen wrapped in ScrollView.
    •    Use card style grouped sections.
    •    No real photo persistence required for prototype.
    •    Use placeholder images for Proof of Work if needed.
    •    Timeline entries generated from WorkOrderViewModel event log array.

⸻

Data Model Additions

Add to WorkOrder model:

struct TimelineEvent {
    let type: EventType
    let timestamp: Date
}

enum EventType {
    case confirmed
    case arrived
    case radiusExpanded
    case started
    case paused
    case autoPause
    case resumed
    case completed
}

WorkOrder should contain:
    •    serviceId
    •    hourlyRate
    •    totalTime
    •    laborTotal
    •    materialsTotal
    •    totalPaid
    •    timelineEvents array
    •    prePhotoCount
    •    postPhotoCount

⸻

Acceptance Criteria
    •    Screen scrolls vertically.
    •    All sections visible without compression.
    •    Timeline reflects simulated job flow.
    •    Totals calculate correctly from session data.
    •    Visual hierarchy emphasizes trust and verification.

⸻

App Store Review — Demo Build Guidelines

When this prototype is submitted to the App Store for investor demo or tester access, the following rules apply to avoid rejection.

⸻

App Identity

Present the app as:
"ANKR Integrity — Interactive Product Walkthrough"

Do not present it as a live marketplace. Frame it as a structured product experience preview — simulated flow, preloaded data, clear completion endpoints.

⸻

Rejection Risks and How to Avoid Them

1. Non-Functional Appearance (Guideline 2.1 — Completeness)
Apple will reject apps that look like a marketplace but don't do anything.
    •    Always use preloaded sample jobs and hires — never leave a flow that ends in nothing.
    •    Every user path must have a clear completion state (clientReview is the terminal state — use it).
    •    All major buttons must respond. No dead taps on primary actions.
    •    Do not ship placeholder screens as the only reachable destination from a primary CTA.

2. Misleading Financial Language
    •    Do not use: "Guaranteed payment", "Secured escrow", "Fraud-proof", "Zero risk", "Verified payout (live)"
    •    Acceptable: "Simulated billing", "Demo transaction", "Prototype wallet", "Labor total (demo)"
    •    Wallet balance and totals are clearly session-only — do not imply real money movement.

3. Unsubstantiated Trust Claims
    •    Do not use absolute language: "Guaranteed", "Fraud-proof", "Zero risk"
    •    Use informational framing: "Designed to verify", "Integrity-tracked", "Photo-verified workflow"

4. Thin App Risk (Minimal Functionality)
    •    The app must allow tapping through at least one complete work order flow end to end.
    •    State changes must be visible and meaningful (status pills, timer, photo count, balance update).
    •    At least one work order must start in a state that allows immediate interaction (pending status).

5. Login Wall
    •    If any authentication screen is added later, provide Apple Review with demo credentials in the Review Notes field.
    •    Preferred: include a "Demo Mode" bypass that skips login entirely for review purposes.

6. Permissions
    •    Camera: must include a usage description string in Info.plist — "Required to upload job site photos."
    •    Location: not used in this prototype. Do not request location permission.
    •    Do not request any permission not actively used. Unused permission requests are an automatic flag.

⸻

What Makes This Build Safe

    •    No real data collection
    •    No payments or financial processing
    •    No location services
    •    No background tasks or tracking
    •    No external accounts or identity verification
    •    All state resets on app restart (session only)
    •    Preloaded dummy data — app is fully functional on first launch with no setup

This profile is low risk. Keep it this way.

⸻

Review Notes Template (for App Store Connect submission)

This is an interactive prototype of the ANKR Integrity platform — Hire side experience.
It demonstrates the operational workflow for service professionals: job confirmation, navigation, photo documentation, active billing, and completion summary.

All data is preloaded and simulated. No real payments, location, or identity verification are used.
No login is required. The app launches directly into the home screen with sample work orders ready to interact with.

