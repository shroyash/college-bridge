# College Bridge — Product Requirements Document (PRD)

> **Version:** 1.0
> **Last Updated:** July 2026
> **Status:** Active

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Problem Statement](#2-problem-statement)
3. [Vision](#3-vision)
4. [Goals](#4-goals)
5. [Non-Goals](#5-non-goals)
6. [Target Users](#6-target-users)
7. [User Personas](#7-user-personas)
8. [Functional Requirements](#8-functional-requirements)
9. [Non-Functional Requirements](#9-non-functional-requirements)
10. [Complete Feature List](#10-complete-feature-list)
11. [MVP Features](#11-mvp-features)
12. [Future Features](#12-future-features)
13. [User Stories](#13-user-stories)
14. [Success Metrics](#14-success-metrics)
15. [Constraints](#15-constraints)
16. [Assumptions](#16-assumptions)
17. [Risks](#17-risks)
18. [Acceptance Criteria](#18-acceptance-criteria)
19. [Glossary](#19-glossary)

---

## 1. Project Overview

**College Bridge** is a smart, AI-powered mobile notification and communication platform built for educational institutions. It bridges the communication gap between administrators, teachers, and students by delivering real-time push notifications, enabling instant doubt resolution through AI, and automating academic calendar management.

The platform is built as a **single monolithic Spring Boot backend** serving a **Flutter mobile application**, with **Firebase Cloud Messaging (FCM)** handling real-time push notification delivery and **Claude AI** powering intelligent features across three core modules: Calendar, Class, and Doubt.

### Core Capabilities at a Glance

| Capability | Description |
|---|---|
| Broadcast Notifications | Admin sends one message to all students or selected classes |
| Class-Specific Alerts | Teachers notify their class instantly via FCM topics |
| AI Doubt Resolution | Students get instant AI answers; escalates to teacher if needed |
| AI Holiday Detection | System detects holidays, drafts messages, admin approves |
| Async Delivery | Message Queue + Worker Thread Pool + Virtual Threads |
| Multi-Device Support | Separate FCM token table for multiple devices per user |

---

## 2. Problem Statement

Educational institutions in Nepal and similar developing-country contexts face a critical communication breakdown between administrators, teachers, and students. The current reality includes:

- **Notice boards are the primary channel** — students must physically visit boards to get updates, leading to missed information.
- **Informal channels (WhatsApp groups, word-of-mouth)** are unreliable, create misinformation, and exclude students who are not in the right group.
- **Teacher absence/late arrival is not communicated** — students travel to college only to find an empty classroom, wasting hours.
- **Academic doubts go unresolved** for days because teachers are not immediately accessible outside class hours.
- **Holiday announcements are manual** — staff must remember to post notices, leading to missed or late announcements.
- **No targeted communication** — announcements meant for BCA 3rd semester accidentally reach BSCIT students and create confusion.
- **No delivery tracking** — admins have no visibility into whether notifications were received.

This results in wasted time, missed academic information, student disengagement, and increased administrative burden.

---

## 3. Vision

> **"Every student should know what is happening at their college, instantly, without having to look for it."**

College Bridge aims to become the single communication layer for any educational institution — making information flow from administration to students as frictionless as a single tap, while making AI a quiet assistant that reduces manual work for staff without replacing human judgment.

---

## 4. Goals

### Primary Goals
- Deliver push notifications to any number of students within seconds of an admin or teacher action.
- Enable teachers to send class-specific alerts (late arrival, cancellation, rescheduling) in under 10 seconds.
- Give students instant answers to academic doubts 24/7 via AI, with guaranteed human escalation when AI is insufficient.
- Automate holiday message detection and drafting while keeping admin in full control of what gets sent.

### Secondary Goals
- Eliminate dependency on WhatsApp groups and notice boards for official college communication.
- Provide admins with delivery visibility (sent count, failed count, retry status).
- Support multi-device usage so students on phones and tablets both receive notifications.
- Keep the system cost-effective — FCM is free, Claude AI has a generous free tier.

---

## 5. Non-Goals

The following are explicitly out of scope for this project:

- ❌ Video calling or live streaming of lectures
- ❌ Online assignment submission or grading
- ❌ Fee payment or financial transactions
- ❌ Attendance management system
- ❌ Full LMS (Learning Management System) features
- ❌ SMS or WhatsApp-based notification delivery (future feature)
- ❌ Web browser client (mobile-only for MVP)
- ❌ Multi-tenant / multi-institution support (single institution for MVP)
- ❌ Offline-first functionality
- ❌ End-to-end encrypted messaging between individuals

---

## 6. Target Users

### Primary Users

| Role | Description | Count (estimated) |
|---|---|---|
| **Student** | Enrolled college students receiving notifications, posting doubts | 500–5,000 |
| **Teacher** | Faculty sending class alerts, answering escalated doubts | 20–100 |
| **Admin (Super Admin)** | College administration broadcasting announcements, managing system | 2–10 |

### Secondary Users
- **IT Department** — manages system deployment, user account creation
- **Department Heads** — may have admin-level access for their department

---

## 7. User Personas

### Persona 1 — Aarav (Student)

- **Age:** 20
- **Department:** BCA, 3rd Semester
- **Device:** Android smartphone (budget range)
- **Pain points:** Finds out class is cancelled after arriving at college. Cannot get doubt answered until next class (2 days away). Misses holiday notices posted on the board.
- **Goals:** Get notified instantly when something changes. Get help with study doubts at night before exams.
- **Tech comfort:** High — uses social media, comfortable with apps.

### Persona 2 — Mr. Karki (Teacher)

- **Age:** 38
- **Subject:** Database Management Systems
- **Device:** iOS smartphone (mid-range)
- **Pain points:** Cannot notify students quickly when running late. Students call/text him individually which is disruptive. Writing formal notices takes time.
- **Goals:** Send a quick update in under a minute. Get AI to draft the formal message from his short note.
- **Tech comfort:** Moderate — comfortable with standard apps, not technical.

### Persona 3 — Admin Priya (Super Admin)

- **Age:** 45
- **Role:** BCA Department Coordinator
- **Device:** Android smartphone + laptop
- **Pain points:** Must physically post notices on boards and send WhatsApp messages to all group chats. No visibility on whether students received important notices. Holiday messages require manual drafting every time.
- **Goals:** Send one message that reaches everyone. Know it was delivered. Let AI draft holiday greetings automatically.
- **Tech comfort:** Moderate — comfortable with administrative software.

---

## 8. Functional Requirements

### 8.1 Authentication Module

| ID | Requirement | Priority |
|---|---|---|
| FR-AUTH-01 | User must be able to register with name, email, password, and role | Must Have |
| FR-AUTH-02 | User must be able to log in with email and password | Must Have |
| FR-AUTH-03 | System must issue JWT token on successful login | Must Have |
| FR-AUTH-04 | JWT token must expire after 24 hours | Must Have |
| FR-AUTH-05 | User must be able to log out (invalidate token client-side) | Must Have |
| FR-AUTH-06 | Password must be stored as bcrypt hash, never plain text | Must Have |
| FR-AUTH-07 | Role must be validated server-side on every protected request | Must Have |

### 8.2 User Management Module

| ID | Requirement | Priority |
|---|---|---|
| FR-USER-01 | Admin can create, view, update, and delete user accounts | Must Have |
| FR-USER-02 | Admin can assign roles (STUDENT, TEACHER, ADMIN) | Must Have |
| FR-USER-03 | Student profile includes roll number, semester, department | Must Have |
| FR-USER-04 | Teacher profile includes subject and department | Must Have |
| FR-USER-05 | Each user can register multiple FCM device tokens | Must Have |
| FR-USER-06 | FCM token is updated on every app launch | Must Have |
| FR-USER-07 | Stale / UNREGISTERED FCM tokens are automatically deleted | Must Have |

### 8.3 Class Module

| ID | Requirement | Priority |
|---|---|---|
| FR-CLASS-01 | Admin can create, read, update, and delete classes | Must Have |
| FR-CLASS-02 | Admin can assign exactly one teacher to a class | Must Have |
| FR-CLASS-03 | Admin can enroll students into a class | Must Have |
| FR-CLASS-04 | Each class has a unique FCM topic ID (e.g., class_1) | Must Have |
| FR-CLASS-05 | Student is auto-subscribed to class FCM topic on enrollment | Must Have |
| FR-CLASS-06 | Student is auto-unsubscribed from class FCM topic on removal | Must Have |
| FR-CLASS-07 | Student can view all their enrolled classes | Must Have |
| FR-CLASS-08 | Teacher can view all assigned classes and member lists | Must Have |
| FR-CLASS-09 | AI can draft formal announcements from teacher's short note | Should Have |

### 8.4 Notification / Broadcast Module

| ID | Requirement | Priority |
|---|---|---|
| FR-NOTIF-01 | Admin can broadcast to all students at once | Must Have |
| FR-NOTIF-02 | Admin can broadcast to one or more selected classes simultaneously | Must Have |
| FR-NOTIF-03 | Admin can broadcast to an entire department | Must Have |
| FR-NOTIF-04 | Teacher can send alert to their own class only | Must Have |
| FR-NOTIF-05 | Notification is placed in a message queue asynchronously | Must Have |
| FR-NOTIF-06 | Worker thread pool processes the queue with Java Virtual Threads | Must Have |
| FR-NOTIF-07 | FCM topic messaging is used for class-specific alerts (single API call) | Must Have |
| FR-NOTIF-08 | FCM multicast is used for broadcast (500 tokens per batch) | Must Have |
| FR-NOTIF-09 | Idempotency key prevents duplicate sends | Must Have |
| FR-NOTIF-10 | Rate limiting prevents admin from sending too many messages | Must Have |
| FR-NOTIF-11 | Notifications have priority levels: HIGH, MEDIUM, LOW | Must Have |
| FR-NOTIF-12 | HIGH priority notifications are processed before LOW | Must Have |
| FR-NOTIF-13 | Failed deliveries are automatically retried with exponential backoff | Must Have |
| FR-NOTIF-14 | After 5 failed attempts, batch is moved to dead-letter state | Must Have |
| FR-NOTIF-15 | Admin is alerted when a batch is permanently failed (dead) | Must Have |
| FR-NOTIF-16 | Admin can view delivery status (sent, failed, pending counts) | Should Have |
| FR-NOTIF-17 | Student can view notification history | Must Have |
| FR-NOTIF-18 | Student can mark notification as read | Should Have |

### 8.5 Doubt Module

| ID | Requirement | Priority |
|---|---|---|
| FR-DOUBT-01 | Student can post an academic doubt with class context | Must Have |
| FR-DOUBT-02 | AI generates an instant answer immediately after doubt is posted | Must Have |
| FR-DOUBT-03 | AI answer is clearly labeled as AI-generated | Must Have |
| FR-DOUBT-04 | Student can mark AI answer as helpful (Yes) or not helpful (No) | Must Have |
| FR-DOUBT-05 | If marked not helpful, doubt is escalated to the class teacher | Must Have |
| FR-DOUBT-06 | On escalation, all class members are notified via FCM topic push | Must Have |
| FR-DOUBT-07 | Subject teacher receives a dedicated notification for escalated doubt | Must Have |
| FR-DOUBT-08 | Any classmate can post their own answer to a doubt | Must Have |
| FR-DOUBT-09 | Teacher can post a verified answer (is_verified = true) | Must Have |
| FR-DOUBT-10 | Verified teacher answer is visually distinct from peer answers | Must Have |
| FR-DOUBT-11 | Original student is notified when a verified answer is posted | Must Have |
| FR-DOUBT-12 | Student can view all doubts posted in their class | Should Have |

### 8.6 Calendar / AI Module

| ID | Requirement | Priority |
|---|---|---|
| FR-CAL-01 | System runs a scheduled job every midnight to check tomorrow's date | Must Have |
| FR-CAL-02 | Job queries the Nepali calendar / Patro API for holiday status | Must Have |
| FR-CAL-03 | If tomorrow is a holiday, Claude AI generates a greeting message | Must Have |
| FR-CAL-04 | AI-generated message is saved with status PENDING_APPROVAL | Must Have |
| FR-CAL-05 | Admin receives a push notification to review the AI draft | Must Have |
| FR-CAL-06 | Admin can approve, edit, or reject the AI-generated message | Must Have |
| FR-CAL-07 | On approval, message enters the broadcast queue immediately | Must Have |
| FR-CAL-08 | Admin selects target: All students or specific classes | Must Have |
| FR-CAL-09 | Rejected messages are discarded and not sent | Must Have |
| FR-CAL-10 | AI can suggest optimized routine change times in Calendar module | Nice to Have |

---

## 9. Non-Functional Requirements

### 9.1 Performance

| ID | Requirement | Target |
|---|---|---|
| NFR-PERF-01 | Notification delivery to 10,000 students | < 30 seconds |
| NFR-PERF-02 | API response time for all endpoints | < 500ms (p95) |
| NFR-PERF-03 | AI answer generation time | < 5 seconds |
| NFR-PERF-04 | App launch to dashboard load time | < 2 seconds |
| NFR-PERF-05 | DB query response time | < 100ms |

### 9.2 Scalability

| ID | Requirement |
|---|---|
| NFR-SCALE-01 | System must handle 1,000,000 FCM deliveries per broadcast without architecture changes |
| NFR-SCALE-02 | Worker thread pool must scale without increasing OS thread count |
| NFR-SCALE-03 | DB must support read replicas for paginated user queries |
| NFR-SCALE-04 | Message queue must support priority ordering without additional infrastructure |

### 9.3 Reliability

| ID | Requirement |
|---|---|
| NFR-REL-01 | System uptime: 99.5% (allows ~44 hours downtime/year) |
| NFR-REL-02 | Failed notification batches must be retried automatically |
| NFR-REL-03 | Server restart must not lose queued broadcast jobs (DB-backed queue) |
| NFR-REL-04 | Duplicate notification prevention through idempotency keys |

### 9.4 Security

| ID | Requirement |
|---|---|
| NFR-SEC-01 | All API endpoints protected by JWT authentication |
| NFR-SEC-02 | Role-based access control enforced server-side |
| NFR-SEC-03 | Passwords hashed with bcrypt (minimum cost factor 12) |
| NFR-SEC-04 | All communication over HTTPS/TLS |
| NFR-SEC-05 | Rate limiting on broadcast endpoints (max 3 per 10 minutes per admin) |
| NFR-SEC-06 | No sensitive data in JWT payload (no password, no PII beyond user ID) |
| NFR-SEC-07 | Environment variables for all secrets (never hardcoded) |

### 9.5 Usability

| ID | Requirement |
|---|---|
| NFR-USE-01 | Teacher can send a class alert in under 10 seconds |
| NFR-USE-02 | Student can post a doubt and see AI answer in under 6 seconds |
| NFR-USE-03 | Admin can approve an AI holiday message in under 5 seconds |
| NFR-USE-04 | App must work on Android 8.0+ and iOS 14+ |

### 9.6 Maintainability

| ID | Requirement |
|---|---|
| NFR-MAIN-01 | All code follows module-based architecture |
| NFR-MAIN-02 | Every module is independently testable |
| NFR-MAIN-03 | No module may directly access another module's repository |
| NFR-MAIN-04 | All AI calls run on virtual threads to avoid blocking |

---

## 10. Complete Feature List

### Authentication & Users
- [x] User registration (Student, Teacher, Admin)
- [x] JWT-based login/logout
- [x] Role-based access control
- [x] Multi-device FCM token management
- [x] Admin: CRUD on user accounts

### Class Management
- [x] Admin: Create, read, update, delete classes
- [x] Admin: Assign teacher to class
- [x] Admin: Enroll/remove students
- [x] Auto FCM topic subscribe/unsubscribe
- [x] AI-assisted announcement drafting

### Notifications & Broadcast
- [x] Admin: Broadcast to all / selected classes / department
- [x] Teacher: Class-specific FCM topic alert
- [x] Async message queue with priority (HIGH/MEDIUM/LOW)
- [x] Java Virtual Threads for concurrent FCM delivery
- [x] Idempotency key for duplicate prevention
- [x] Rate limiting (Bucket4j)
- [x] Exponential backoff retry
- [x] Dead letter queue + admin alert
- [x] Delivery status dashboard
- [x] Student: notification history + read status

### Doubt Resolution
- [x] Student: post doubt with class context
- [x] AI instant answer (Claude API)
- [x] Helpful/Not helpful feedback
- [x] Escalation to teacher + class notification
- [x] Peer answers from classmates
- [x] Teacher verified answers
- [x] Original student notified on verified answer

### AI Calendar Module
- [x] Midnight scheduled holiday detection
- [x] Patro/Nepali Calendar API integration
- [x] Claude AI holiday message generation
- [x] Admin approval workflow
- [x] Approved message enters broadcast queue

---

## 11. MVP Features

The following features constitute the Minimum Viable Product:

1. **Auth** — Registration, Login, JWT, Role-based access
2. **Class Management** — CRUD, Teacher assignment, Student enrollment, FCM topic subscribe
3. **Teacher Alert** — Send class-specific notification via FCM topic
4. **Admin Broadcast** — Send to all students or selected classes
5. **Async Delivery** — Message queue, worker pool, virtual threads, FCM multicast
6. **Retry + DLQ** — Exponential backoff, dead-letter with admin alert
7. **Doubt Module** — Post doubt, AI answer, helpful check, escalation, peer/teacher answers
8. **Calendar AI** — Holiday detection, AI draft, admin approval, broadcast on approval
9. **Multi-device FCM** — Separate token table per user

---

## 12. Future Features

Post-MVP enhancements planned for future releases:

| Feature | Description | Priority |
|---|---|---|
| SMS Fallback | Send SMS via Sparrow SMS if FCM delivery fails | High |
| Web Dashboard | Admin web interface for analytics and management | High |
| Notification Scheduling | Admin can schedule broadcasts for a future date/time | Medium |
| Department-level Admin | Separate admin roles per department | Medium |
| AI Doubt Auto-Answer Quality Score | Rate AI answer quality, improve prompts over time | Medium |
| Push Notification Templates | Pre-built templates for common notices | Low |
| WhatsApp Integration | Forward important notices via WhatsApp Business API | Low |
| Multi-institution Support | Multi-tenant setup for multiple colleges | Low |
| Analytics Dashboard | Open/read rates, engagement per class/dept | Low |
| Attendance Integration | Link with attendance system | Low |

---

## 13. User Stories

### Student Stories

```
ST-01: As a student, I want to receive instant push notifications
       when my teacher sends a class alert, so I don't waste time
       traveling to a cancelled class.

ST-02: As a student, I want to post an academic doubt and get an
       AI answer immediately, so I can study at any hour without
       waiting for the next class.

ST-03: As a student, I want to mark an AI answer as "not helpful"
       so the question is escalated to my teacher automatically.

ST-04: As a student, I want to see answers from my classmates
       on a posted doubt, so I can benefit from peer knowledge.

ST-05: As a student, I want to receive a holiday notification the
       evening before so I can plan accordingly.

ST-06: As a student, I want to view my full notification history
       so I never miss an important announcement.

ST-07: As a student, I want my notifications to reach both my
       phone and tablet so I never miss them.
```

### Teacher Stories

```
TC-01: As a teacher, I want to send a class alert in under 10
       seconds so I can notify students I'm running late without
       disrupting my schedule.

TC-02: As a teacher, I want AI to draft a formal message from my
       short note so I don't have to write formal language every time.

TC-03: As a teacher, I want to be notified when a student escalates
       a doubt so I can answer it at my convenience.

TC-04: As a teacher, I want my verified answer to be highlighted
       distinctly so students know it's authoritative.

TC-05: As a teacher, I want to review AI-suggested calendar changes
       before they are published so I maintain control of my schedule.

TC-06: As a teacher, I want to see how many students are enrolled
       in each of my classes.
```

### Admin Stories

```
AD-01: As an admin, I want to broadcast a message to all BCA and
       BSCIT students simultaneously with a single action.

AD-02: As an admin, I want to see how many students received my
       broadcast so I can confirm delivery.

AD-03: As an admin, I want to receive an AI-drafted holiday message
       for my approval so I don't have to write it from scratch.

AD-04: As an admin, I want to be alerted when a notification batch
       permanently fails so I can take manual action.

AD-05: As an admin, I want to create and manage classes, assign
       teachers, and enroll students from the app.

AD-06: As an admin, I want rate limiting to prevent me from
       accidentally sending the same message multiple times.
```

---

## 14. Success Metrics

| Metric | Target | Measurement Method |
|---|---|---|
| Notification delivery rate | > 95% | sent_count / total_users per broadcast |
| Average notification delivery time | < 10 seconds for class alerts | Timestamp: job created vs FCM acknowledged |
| AI doubt answer accuracy (student marked helpful) | > 70% | is_helpful = true / total doubts |
| Teacher alert creation time | < 10 seconds | UX time tracking |
| Admin broadcast completion | < 30 seconds for 10,000 students | broadcast_jobs.created_at vs completed_at |
| App retention at 30 days | > 60% | Active users / registered users |
| Dead-letter batch rate | < 1% | failed_batches.status = DEAD / total batches |

---

## 15. Constraints

| Constraint | Description |
|---|---|
| Budget | Zero cost for FCM (free). Claude AI free tier for academic project. No paid infrastructure for MVP. |
| Team Size | BCA semester project team of 4 beginners — monolithic architecture required |
| Timeline | One academic semester (~4 months) |
| Device Support | Android 8.0+ and iOS 14+ (Flutter handles both) |
| Database | Single PostgreSQL instance for MVP (no sharding) |
| Platform | Mobile-only (no web for MVP) |
| AI Provider | Claude AI (Anthropic) API — subject to free tier limits |
| Calendar Source | Nepali Patro API or equivalent (public holiday data for Nepal) |

---

## 16. Assumptions

- Students own smartphones with internet connectivity
- The college has a stable internet connection for the server
- FCM will remain free and available (Google policy)
- Claude AI API will remain accessible within free/low-cost tier for academic use
- All users will download and use the Flutter mobile app
- Admin will actively review and approve AI-generated holiday messages
- A single institution (one college) uses the system for MVP
- Teachers are assigned to classes before the system goes live (initial data setup)

---

## 17. Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| FCM rate limiting during mass broadcast | Medium | High | Batch 500 tokens per request, use topic messaging for classes |
| Claude AI API key quota exceeded | Low | Medium | Cache AI responses, use conservative prompts, monitor usage |
| FCM token staleness (student reinstalls app) | High | Medium | Delete UNREGISTERED tokens automatically on FCM error response |
| Admin sends duplicate broadcasts | Medium | Medium | Idempotency key + UI debounce + content-hash dedupe |
| DB overload during large broadcast | Low | High | Paginate reads (10k/page), use read replicas, cap concurrent workers |
| Server crash mid-broadcast | Low | High | DB-backed job queue survives restarts, resumes from last page |
| AI generates inappropriate holiday message | Low | High | Admin approval required before any AI message is sent |
| Students opt out of push notifications | Medium | High | Cannot bypass OS notification settings — educate users on enabling |
| Nepali Calendar API unavailability | Low | Medium | Cache last known holiday data, fallback to manual holiday entry |

---

## 18. Acceptance Criteria

### Authentication
- ✅ User can register and immediately log in with the same credentials
- ✅ JWT token is returned and validated on protected endpoints
- ✅ A STUDENT cannot access ADMIN or TEACHER endpoints
- ✅ Password is never stored or returned in plain text

### Class Module
- ✅ Admin creates a class and it appears in the student's class list after enrollment
- ✅ Enrolling a student triggers FCM topic subscription automatically
- ✅ Removing a student triggers FCM topic unsubscription automatically
- ✅ Teacher sends an alert and all enrolled students receive the push notification

### Broadcast Module
- ✅ Admin broadcast to "All" reaches every registered student
- ✅ Admin broadcast to "BCA 3rd Sem — DBMS" reaches only enrolled students
- ✅ Sending the same message twice (same idempotency key) results in only one delivery
- ✅ Broadcast job survives server restart and completes after restart
- ✅ Failed batch is retried up to 5 times then marked DEAD with admin alert

### Doubt Module
- ✅ Student posts doubt → AI answer appears within 5 seconds
- ✅ Student marks "Not helpful" → teacher receives escalation notification
- ✅ Classmate posts answer → original student receives notification
- ✅ Teacher posts verified answer → displayed with distinct verified badge

### Calendar AI Module
- ✅ Midnight job detects Dashain and generates a greeting message
- ✅ Admin receives push to review the message
- ✅ Admin approves → message is broadcast to all students
- ✅ Admin rejects → message is discarded, no broadcast
- ✅ Non-holiday nights → no message generated, no admin notification

---

## 19. Glossary

| Term | Definition |
|---|---|
| **FCM** | Firebase Cloud Messaging — Google's free service for sending push notifications to Android, iOS, and web devices |
| **FCM Topic** | A named channel in Firebase that devices subscribe to. Sending to a topic delivers to all subscribed devices with a single API call (e.g., `class_1`) |
| **FCM Token** | A unique identifier for a specific app installation on a specific device. Changes when the app is reinstalled |
| **Virtual Thread** | Java 21 feature — lightweight threads managed by the JVM, not the OS. Ideal for I/O-bound tasks like FCM calls |
| **Message Queue** | A holding area for notification jobs. Worker threads pick up jobs from the queue asynchronously |
| **Worker Thread Pool** | A fixed number of threads (2-3) that process jobs from the message queue concurrently |
| **Idempotency Key** | A unique key attached to each send request. If the same key is seen twice, the second request is ignored, preventing duplicate sends |
| **Dead Letter Queue (DLQ)** | Storage for notification batches that have permanently failed (5 retries exhausted). Admin is alerted to review these |
| **Exponential Backoff** | A retry strategy where wait time doubles with each failure: 2 min → 4 min → 8 min → 16 min |
| **Spring Batch** | A Spring framework for processing large datasets in chunks — used for paginated user reads during broadcast |
| **Bucket4j** | A Java rate limiting library — used to limit how many broadcasts an admin can send per time window |
| **Claude AI** | Anthropic's AI model, used for generating AI doubt answers and holiday messages |
| **Patro API** | Nepali calendar API providing Bikram Sambat (BS) dates and public holiday information for Nepal |
| **BCNF** | Boyce-Codd Normal Form — a database normalization level |
| **JWT** | JSON Web Token — a compact, self-contained token used for authentication |
| **Multicast** | Sending one FCM request with up to 500 device tokens, delivering to all 500 simultaneously |
| **Escalation** | The process of forwarding an unanswered doubt from the AI to the subject teacher for a human response |
| **Monolithic Architecture** | A single deployable application containing all modules, as opposed to microservices |