-- =============================================================================
-- Migration Script: Add Soft Delete Columns to Academic Structure (V3)
-- =============================================================================

ALTER TABLE academic_programs 
    ADD COLUMN deleted BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN deleted_at DATETIME(6) NULL;

ALTER TABLE academic_levels 
    ADD COLUMN deleted BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN deleted_at DATETIME(6) NULL;

ALTER TABLE subjects 
    ADD COLUMN deleted BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN deleted_at DATETIME(6) NULL;
