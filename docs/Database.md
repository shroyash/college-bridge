# College Bridge - Database Architecture & Schema Documentation (MySQL Edition)

## 1. System Overview & Technology Stack
- **Database Engine:** MySQL 8.0+
- **Storage Engine:** `InnoDB` (Enforced across all tables for Foreign Keys & ACID compliance)
- **Default Character Set / Collation:** `utf8mb4` / `utf8mb4_unicode_ci`
- **Primary Keys:** `BIGINT AUTO_INCREMENT` across all primary entities.
- **Schema Source:** DBML (`schema.dbml`) hosted on [dbdiagram.io].

---

## 2. MySQL-Specific Design Rules for AI Agents

To ensure generated code, migrations, and queries are 100% compliant with MySQL:

1. **Foreign Keys & Engines:** All table creation scripts MUST explicitly specify `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`.
2. **Boolean Mapping:** MySQL represents `BOOLEAN` / `BOOL` internally as `TINYINT(1)` (`0` = false, `1` = true). AI engines must handle boolean flags (`deleted`, `is_holiday`, `verified`) accordingly.
3. **Auto-Increment Strategy:** Always use `BIGINT UNSIGNED AUTO_INCREMENT` for high-volume entities (`users`, `notifications`, `failed_batches`).
4. **Timestamp Defaults:** Timestamps should utilize `CURRENT_TIMESTAMP` for default insertions and `ON UPDATE CURRENT_TIMESTAMP` for `updated_at` columns where applicable.

---

## 3. Core Architectural Patterns

### 3.1 Identity & Authorization Architecture (1:1 Extension Tables)
- **Base Identity (`users`):** Central authentication, credentials, soft-delete metadata, and FCM device tokens.
- **Role Tables (`students`, `teachers`, `admins`):** Maintains strict 1:1 relationships using unique Foreign Key constraints on `user_id` (`users.user_id`).
- **Teacher Onboarding Workflow:** Pending teacher sign-ups create a record in `teacher_verification_requests` and associated files in `verification_documents`.

### 3.2 Academic Curriculum vs. Live Class Sections
- **`academic_classes` (Static Track):** Represents institutional syllabus tracks (e.g., *Faculty: BCA, Semester: 3*).
- **`classes` (Operational Section):** Represents an active, teacher-led classroom instance (e.g., *Web Technologies Section A*) mapped to a unique `fcm_topic_id` for group pushes.

### 3.3 Asynchronous Notification & Retry Pipeline
- **`notifications`:** Stores base alert payloads. `idempotency_key` ensures zero duplicate dispatches at the database boundary.
- **`broadcast_jobs` & `failed_batches`:** Implements an outbox / worker processing pattern. Retries use `next_retry_at` timestamps for exponential backoff execution.

---

## 4. MySQL Native Enums

| Enum Name | Defined Values | Purpose |
| :--- | :--- | :--- |
| **`UserRole`** | `'STUDENT'`, `'TEACHER'`, `'ADMIN'` | High-level permission scope. |
| **`UserStatus`** | `'ACTIVE'`, `'INACTIVE'`, `'SUSPENDED'`, `'PENDING_VERIFICATION'` | Account access status. |
| **`Faculty`** | `'BCA'`, `'BBA'`, `'BSC_CSIT'`, `'BIM'`, `'BHM'` | Academic degree programs. |
| **`DoubtStatus`** | `'OPEN'`, `'RESOLVED'`, `'CLOSED'` | Status for Q&A threads. |
| **`NotificationPriority`** | `'LOW'`, `'NORMAL'`, `'HIGH'`, `'URGENT'` | Priority handling for push queues. |
| **`JobStatus`** | `'PENDING'`, `'PROCESSING'`, `'COMPLETED'`, `'FAILED'` | Background job state. |

---

## 5. Entity Modules & Relationships

### 5.1 Module: Authentication & Users (`Auth_Module`)
* **`users`**: Master user store.
    * *Foreign Keys:* None.
    * *Key Indexes:* `UNIQUE (email)`.
* **`students`**: Student records.
    * *Foreign Keys:* `user_id -> users.user_id`, `academic_class_id -> academic_classes.class_id`.
    * *Key Indexes:* `UNIQUE (user_id)`.
* **`teachers`**: Faculty member records.
    * *Foreign Keys:* `user_id -> users.user_id`.
    * *Key Indexes:* `UNIQUE (user_id)`.
* **`admins`**: System administrator records.
    * *Foreign Keys:* `user_id -> users.user_id`.
    * *Key Indexes:* `UNIQUE (user_id)`.
* **`one_time_passwords`**: Email OTPs & password reset tokens.
    * *Key Indexes:* Composite `(email, type, verified)`, single index on `expiry_date`.
* **`refresh_tokens`**: User JWT session rotation.
    * *Foreign Keys:* `user_id -> users.user_id`.
* **`teacher_verification_requests`**: Approval workflow for incoming teachers.
    * *Foreign Keys:* `user_id -> users.user_id`, `reviewed_by -> users.user_id`.

### 5.2 Module: Academic Structure (`Academic_Module`)
* **`academic_classes`**: High-level faculty + semester combinations.
    * *Key Indexes:* `UNIQUE (faculty, semester)`.
* **`subjects`**: Course catalog entries.
    * *Key Indexes:* `UNIQUE (faculty, semester, name)`.
* **`subject_enrollments`**: Subject-to-student mapping.
    * *Foreign Keys:* `student_id -> students.student_id`, `subject_id -> subjects.subject_id`.
    * *Key Indexes:* `UNIQUE (student_id, subject_id)`.

### 5.3 Module: Classrooms & Calendar (`Class_Module`)
* **`classes`**: Live classroom sections.
    * *Foreign Keys:* `teacher_id -> teachers.teacher_id`.
    * *Key Indexes:* `UNIQUE (fcm_topic_id)`.
* **`class_enrollments`**: Active student rosters per class.
    * *Foreign Keys:* `class_id -> classes.class_id`, `student_id -> students.student_id`.
    * *Key Indexes:* `UNIQUE (class_id, student_id)`.
* **`calendar_events`**: Academic calendar and AI event logging.
    * *Foreign Keys:* `approved_by -> admins.admin_id`.

### 5.4 Module: Doubts & Q/A (`Doubt_Module`)
* **`doubts`**: Student questions submitted under a class section.
    * *Foreign Keys:* `student_id -> students.student_id`, `class_id -> classes.class_id`.
* **`doubt_answers`**: Peer or teacher replies to doubts.
    * *Foreign Keys:* `doubt_id -> doubts.doubt_id`, `answered_by -> users.user_id`.

### 5.5 Module: Push Notifications & Queue (`Notification_Module`)
* **`notifications`**: Master message logs.
    * *Foreign Keys:* `sender_id -> users.user_id`.
    * *Key Indexes:* `UNIQUE (idempotency_key)`.
* **`notification_targets`**: Scope mapping for targeted broadcasts.
    * *Foreign Keys:* `notification_id -> notifications.notification_id`, `class_id -> classes.class_id`.
* **`broadcast_jobs`**: Job tracking for push notification dispatchers.
    * *Foreign Keys:* `notification_id -> notifications.notification_id`.
* **`failed_batches`**: Dead-letter storage for failed FCM tokens.
    * *Foreign Keys:* `job_id -> broadcast_jobs.job_id`.

---

## 6. Critical Index Summary for Query Optimization

```sql
-- High-frequency lookup optimization in MySQL

-- 1. OTP Verification Speedup
CREATE INDEX idx_otp_email_type_verified ON one_time_passwords(email, type, verified);
CREATE INDEX idx_otp_expiry ON one_time_passwords(expiry_date);

-- 2. Curriculum Unique Constraints
ALTER TABLE academic_classes ADD CONSTRAINT uq_faculty_semester UNIQUE (faculty, semester);
ALTER TABLE subjects ADD CONSTRAINT uq_faculty_semester_name UNIQUE (faculty, semester, name);

-- 3. Roster & Enrollment Unique Constraints
ALTER TABLE subject_enrollments ADD CONSTRAINT uq_student_subject UNIQUE (student_id, subject_id);
ALTER TABLE class_enrollments ADD CONSTRAINT uq_class_student UNIQUE (class_id, student_id);

// ==========================================
// DBML Schema for College Bridge Application
// Paste this directly into https://dbdiagram.io
// ==========================================

// --- ENUM DEFINITIONS ---

Enum UserRole {
  STUDENT
  TEACHER
  ADMIN
}

Enum UserStatus {
  ACTIVE
  INACTIVE
  SUSPENDED
  PENDING_VERIFICATION
}

Enum OtpType {
  EMAIL_VERIFICATION
  PASSWORD_RESET
}

Enum VerificationStatus {
  PENDING
  APPROVED
  REJECTED
}

Enum Faculty {
  BCA
  BBA
  BSC_CSIT
  BIM
  BHM
}

Enum DoubtStatus {
  OPEN
  RESOLVED
  CLOSED
}

Enum ApprovalStatus {
  PENDING
  APPROVED
  REJECTED
}

Enum NotificationType {
  ANNOUNCEMENT
  ASSIGNMENT
  EVENT
}

Enum NotificationStatus {
  PENDING
  PROCESSING
  SENT
  FAILED
}

Enum NotificationPriority {
  LOW
  NORMAL
  HIGH
  URGENT
}

Enum TargetType {
  CLASS
  FACULTY
  SEMESTER
  ALL
}

Enum JobStatus {
  PENDING
  PROCESSING
  COMPLETED
  FAILED
}

Enum BatchStatus {
  PENDING
  COMPLETED
  FAILED
}


// --- TABLES ---

// 1. AUTHENTICATION & USERS

Table users {
  user_id bigint [pk, increment]
  name varchar(100) [not null]
  email varchar(150) [not null, unique]
  password_hash varchar(255) [not null]
  role UserRole [not null]
  status UserStatus [not null, default: 'ACTIVE']
  image_url varchar(255)
  fcm_token varchar(255)
  deleted boolean [not null, default: false]
  deleted_at timestamp
  created_at timestamp [not null]
  updated_at timestamp
  version bigint
}

Table students {
  student_id bigint [pk, increment]
  user_id bigint [not null, unique, ref: - users.user_id]
  academic_class_id bigint [not null, ref: > academic_classes.class_id]
  created_at timestamp [not null]
  updated_at timestamp
  version bigint
}

Table teachers {
  teacher_id bigint [pk, increment]
  user_id bigint [not null, unique, ref: - users.user_id]
  created_at timestamp [not null]
  updated_at timestamp
  version bigint
}

Table admins {
  admin_id bigint [pk, increment]
  user_id bigint [not null, unique, ref: - users.user_id]
  department varchar(100)
}

Table one_time_passwords {
  otp_id bigint [pk, increment]
  email varchar(150) [not null]
  code varchar(10) [not null]
  type OtpType [not null]
  expiry_date timestamp [not null]
  attempts int [not null, default: 0]
  verified boolean [not null, default: false]
  verification_token varchar(100)
  created_at timestamp [not null]

  indexes {
    (email, type, verified) [name: 'idx_otp_email_type_verified']
    expiry_date [name: 'idx_otp_expiry']
  }
}

Table refresh_tokens {
  id bigint [pk, increment]
  token varchar(255) [not null, unique]
  user_id bigint [not null, ref: > users.user_id]
  expiry_date timestamp [not null]
  revoked boolean [not null, default: false]
  replaced_by_token varchar(255)
  created_at timestamp [not null]
}

Table teacher_verification_requests {
  request_id bigint [pk, increment]
  user_id bigint [not null, ref: > users.user_id]
  status VerificationStatus [not null, default: 'PENDING']
  rejection_reason text
  reviewed_by bigint [ref: > users.user_id]
  reviewed_at timestamp
  submitted_at timestamp [not null]
  updated_at timestamp
  version bigint
}

Table verification_documents {
  request_id bigint [not null, ref: > teacher_verification_requests.request_id]
  document_url varchar(500)
}


// 2. ACADEMIC STRUCTURE

Table academic_classes {
  class_id bigint [pk, increment]
  faculty Faculty [not null]
  semester int [not null]
  display_name varchar(100) [not null]
  created_at timestamp [not null]

  indexes {
    (faculty, semester) [unique]
  }
}

Table subjects {
  subject_id bigint [pk, increment]
  name varchar(150) [not null]
  faculty Faculty [not null]
  semester int [not null]
  credit_hours int

  indexes {
    (faculty, semester, name) [unique]
  }
}

Table subject_enrollments {
  enrollment_id bigint [pk, increment]
  student_id bigint [not null, ref: > students.student_id]
  subject_id bigint [not null, ref: > subjects.subject_id]
  enrolled_at timestamp [not null]

  indexes {
    (student_id, subject_id) [unique]
  }
}


// 3. CLASS MANAGEMENT & CALENDAR

Table classes {
  class_id bigint [pk, increment]
  class_name varchar(100) [not null]
  subject varchar(100)
  semester int
  faculty Faculty
  department varchar(100)
  fcm_topic_id varchar(150) [not null, unique]
  teacher_id bigint [ref: > teachers.teacher_id]
  created_at timestamp [not null]
}

Table class_enrollments {
  enrollment_id bigint [pk, increment]
  class_id bigint [not null, ref: > classes.class_id]
  student_id bigint [not null, ref: > students.student_id]
  enrolled_at timestamp [not null]

  indexes {
    (class_id, student_id) [unique]
  }
}

Table calendar_events {
  event_id bigint [pk, increment]
  event_date date [not null]
  event_name varchar(200)
  is_holiday boolean [not null]
  ai_message text
  approval_status ApprovalStatus
  approved_by bigint [ref: > admins.admin_id]
  approved_at timestamp
  created_at timestamp [not null]
}


// 4. DOUBTS & Q/A

Table doubts {
  doubt_id bigint [pk, increment]
  student_id bigint [not null, ref: > students.student_id]
  class_id bigint [not null, ref: > classes.class_id]
  question text [not null]
  ai_answer text
  status DoubtStatus
  is_helpful boolean
  created_at timestamp [not null]
}

Table doubt_answers {
  answer_id bigint [pk, increment]
  doubt_id bigint [not null, ref: > doubts.doubt_id]
  answered_by bigint [not null, ref: > users.user_id]
  answer text [not null]
  is_verified boolean [not null, default: false]
  created_at timestamp [not null]
}


// 5. NOTIFICATIONS & BROADCAST

Table notifications {
  notification_id bigint [pk, increment]
  title varchar(200)
  message text [not null]
  sender_id bigint [not null, ref: > users.user_id]
  type NotificationType
  status NotificationStatus
  priority NotificationPriority
  idempotency_key varchar(255) [unique]
  created_at timestamp [not null]
}

Table notification_targets {
  target_id bigint [pk, increment]
  notification_id bigint [not null, ref: > notifications.notification_id]
  class_id bigint [ref: > classes.class_id]
  target_type TargetType
}

Table broadcast_jobs {
  job_id bigint [pk, increment]
  notification_id bigint [not null, ref: > notifications.notification_id]
  status JobStatus
  total_users int
  sent_count int [default: 0]
  failed_count int [default: 0]
  attempts int [default: 0]
  next_retry_at timestamp
  created_at timestamp [not null]
}

Table failed_batches {
  batch_id bigint [pk, increment]
  job_id bigint [not null, ref: > broadcast_jobs.job_id]
  fcm_tokens text
  error_message text
  attempts int [default: 0]
  status BatchStatus
  next_retry_at timestamp
  created_at timestamp [not null]
}


// --- TABLE GROUPS ---

TableGroup Auth_Module {
  users
  students
  teachers
  admins
  one_time_passwords
  refresh_tokens
  teacher_verification_requests
  verification_documents
}

TableGroup Academic_Module {
  academic_classes
  subjects
  subject_enrollments
}

TableGroup Class_Module {
  classes
  class_enrollments
  calendar_events
}

TableGroup Doubt_Module {
  doubts
  doubt_answers
}

TableGroup Notification_Module {
  notifications
  notification_targets
  broadcast_jobs
  failed_batches
}

---

### Key MySQL Specific Adjustments Made:
1. **Added MySQL Runtime Context:** Clear guidelines on `InnoDB`, `utf8mb4`, and how `TINYINT(1)` is expected for boolean fields.
2. **Standardized Indexes:** Provided exact MySQL syntax examples (`CREATE INDEX`, `ADD CONSTRAINT UNIQUE`) so AI tools know how to structure migrations.
3. **Foreign Key Alignment:** Highlighted explicit foreign key mappings across tables to ensure `CASCADE` or `RESTRICT` rules are handled cleanly during backend generation.