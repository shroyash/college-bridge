CREATE TABLE notification_inbox_reads (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    notification_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    read_at DATETIME(6) NOT NULL,
    CONSTRAINT uk_inbox_reads UNIQUE (notification_id, user_id),
    INDEX idx_inbox_reads_user (user_id),
    CONSTRAINT fk_inbox_reads_notification FOREIGN KEY (notification_id)
        REFERENCES notifications(notification_id) ON DELETE CASCADE,
    CONSTRAINT fk_inbox_reads_user FOREIGN KEY (user_id)
        REFERENCES users(user_id) ON DELETE CASCADE
);
