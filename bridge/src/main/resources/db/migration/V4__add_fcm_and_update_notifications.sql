-- =============================================================================
-- Migration Script: FCM Push Notification & Device Management (V4)
-- =============================================================================

-- 1. Safely alter existing notifications table
ALTER TABLE notifications
    ADD COLUMN IF NOT EXISTS institution_id BIGINT NULL,
    ADD COLUMN IF NOT EXISTS target_type VARCHAR(30) NULL,
    ADD COLUMN IF NOT EXISTS target_id BIGINT NULL,
    ADD COLUMN IF NOT EXISTS updated_at DATETIME(6) NULL;

-- Ensure foreign key for institution_id exists
SET @fk_inst_exists = (SELECT COUNT(*) FROM information_schema.table_constraints 
                       WHERE table_schema = DATABASE() 
                         AND table_name = 'notifications' 
                         AND constraint_name = 'fk_notifications_institution');
SET @sql_inst = IF(@fk_inst_exists = 0, 
                   'ALTER TABLE notifications ADD CONSTRAINT fk_notifications_institution FOREIGN KEY (institution_id) REFERENCES institutions(institution_id) ON DELETE CASCADE', 
                   'SELECT 1');
PREPARE stmt_inst FROM @sql_inst; EXECUTE stmt_inst; DEALLOCATE PREPARE stmt_inst;

CREATE INDEX IF NOT EXISTS idx_notifications_institution ON notifications(institution_id);
CREATE INDEX IF NOT EXISTS idx_notifications_target ON notifications(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- 2. Multi-device FCM token registry (fcm_devices)
CREATE TABLE IF NOT EXISTS fcm_devices (
    device_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    institution_id BIGINT NULL,
    fcm_token VARCHAR(500) NOT NULL,
    platform VARCHAR(20) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    last_seen_at DATETIME(6) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    CONSTRAINT fk_fcm_devices_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_fcm_devices_institution FOREIGN KEY (institution_id) REFERENCES institutions(institution_id) ON DELETE CASCADE,
    CONSTRAINT uk_fcm_devices_token UNIQUE (fcm_token)
);

CREATE INDEX IF NOT EXISTS idx_fcm_devices_user_active ON fcm_devices(user_id, active);
CREATE INDEX IF NOT EXISTS idx_fcm_devices_institution ON fcm_devices(institution_id);

-- 3. Device topic subscriptions tracking table
CREATE TABLE IF NOT EXISTS device_topic_subscriptions (
    subscription_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    device_id BIGINT NOT NULL,
    topic VARCHAR(150) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    CONSTRAINT fk_topic_sub_device FOREIGN KEY (device_id) REFERENCES fcm_devices(device_id) ON DELETE CASCADE,
    CONSTRAINT uk_device_topic UNIQUE (device_id, topic)
);

CREATE INDEX IF NOT EXISTS idx_device_topic ON device_topic_subscriptions(device_id);

-- 4. Notification direct recipients tracking table (target_type = 'USERS')
CREATE TABLE IF NOT EXISTS notification_recipients (
    recipient_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    notification_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    delivery_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    delivered_at DATETIME(6) NULL,
    CONSTRAINT fk_recipients_notification FOREIGN KEY (notification_id) REFERENCES notifications(notification_id) ON DELETE CASCADE,
    CONSTRAINT fk_recipients_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT uk_recipients_notification_user UNIQUE (notification_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_recipients_user ON notification_recipients(user_id);
CREATE INDEX IF NOT EXISTS idx_recipients_notif_status ON notification_recipients(notification_id, delivery_status);

-- 5. Durable queue for asynchronous notification delivery (notification_jobs)
CREATE TABLE IF NOT EXISTS notification_jobs (
    job_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    notification_id BIGINT NOT NULL,
    institution_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    attempt_count INT NOT NULL DEFAULT 0,
    max_attempts INT NOT NULL DEFAULT 5,
    next_attempt_at DATETIME(6) NOT NULL,
    locked_at DATETIME(6) NULL,
    lease_expires_at DATETIME(6) NULL,
    last_error TEXT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    CONSTRAINT fk_jobs_notification FOREIGN KEY (notification_id) REFERENCES notifications(notification_id) ON DELETE CASCADE,
    CONSTRAINT fk_jobs_institution FOREIGN KEY (institution_id) REFERENCES institutions(institution_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_jobs_claim ON notification_jobs(status, next_attempt_at, lease_expires_at);
CREATE INDEX IF NOT EXISTS idx_jobs_institution ON notification_jobs(institution_id);
