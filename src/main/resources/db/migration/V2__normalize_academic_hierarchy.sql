-- =============================================================================
-- Migration Script: Normalize Academic Hierarchy (V2)
-- Transition from legacy academic_classes table to Institution -> AcademicProgram -> AcademicLevel -> Subject
-- =============================================================================

-- Step 1: Create new tables
CREATE TABLE IF NOT EXISTS academic_programs (
    program_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    institution_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL,
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT fk_program_institution FOREIGN KEY (institution_id) REFERENCES institutions(institution_id) ON DELETE CASCADE,
    CONSTRAINT uk_program_institution_code UNIQUE (institution_id, code)
);

CREATE TABLE IF NOT EXISTS academic_levels (
    level_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    program_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    level_number INT NOT NULL,
    type VARCHAR(20) NOT NULL,
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT fk_level_program FOREIGN KEY (program_id) REFERENCES academic_programs(program_id) ON DELETE CASCADE,
    CONSTRAINT uk_level_program_number UNIQUE (program_id, level_number)
);

-- Step 2: Migrate data from legacy academic_classes and subjects into academic_programs & academic_levels
-- 2a. Insert programs based on distinct faculties in legacy academic_classes
INSERT INTO academic_programs (institution_id, name, code)
SELECT DISTINCT institution_id, CONCAT('Program ', faculty), faculty
FROM academic_classes
WHERE NOT EXISTS (
    SELECT 1 FROM academic_programs ap WHERE ap.institution_id = academic_classes.institution_id AND ap.code = academic_classes.faculty
);

-- 2b. Insert levels based on legacy academic_classes
INSERT INTO academic_levels (program_id, name, level_number, type)
SELECT ap.program_id, ac.display_name, ac.semester, 'SEMESTER'
FROM academic_classes ac
JOIN academic_programs ap ON ap.institution_id = ac.institution_id AND ap.code = ac.faculty
WHERE NOT EXISTS (
    SELECT 1 FROM academic_levels al WHERE al.program_id = ap.program_id AND al.level_number = ac.semester
);

-- Step 3: Add new foreign key columns
ALTER TABLE subjects ADD COLUMN academic_level_id BIGINT;
ALTER TABLE subjects ADD COLUMN code VARCHAR(50);
ALTER TABLE subjects ADD COLUMN fcm_topic_id VARCHAR(100);

ALTER TABLE students ADD COLUMN academic_level_id BIGINT;

ALTER TABLE notification_targets ADD COLUMN level_id BIGINT;

-- Step 4: Populate level_id foreign keys in subjects and students
UPDATE subjects s
JOIN academic_programs ap ON ap.institution_id = s.institution_id AND ap.code = s.faculty
JOIN academic_levels al ON al.program_id = ap.program_id AND al.level_number = s.semester
SET s.academic_level_id = al.level_id;

UPDATE students st
JOIN academic_classes ac ON ac.class_id = st.class_id
JOIN academic_programs ap ON ap.institution_id = ac.institution_id AND ap.code = ac.faculty
JOIN academic_levels al ON al.program_id = ap.program_id AND al.level_number = ac.semester
SET st.academic_level_id = al.level_id;

UPDATE notification_targets nt
JOIN academic_classes ac ON ac.class_id = nt.class_id
JOIN academic_programs ap ON ap.institution_id = ac.institution_id AND ap.code = ac.faculty
JOIN academic_levels al ON al.program_id = ap.program_id AND al.level_number = ac.semester
SET nt.level_id = al.level_id;

-- Step 5: Foreign key constraints on subjects and students
ALTER TABLE subjects ADD CONSTRAINT fk_subject_academic_level FOREIGN KEY (academic_level_id) REFERENCES academic_levels(level_id) ON DELETE CASCADE;
ALTER TABLE students ADD CONSTRAINT fk_student_academic_level FOREIGN KEY (academic_level_id) REFERENCES academic_levels(level_id) ON DELETE SET NULL;
ALTER TABLE notification_targets ADD CONSTRAINT fk_notification_target_level FOREIGN KEY (level_id) REFERENCES academic_levels(level_id) ON DELETE CASCADE;

-- Step 6: Drop legacy columns and legacy academic_classes table
-- Note: Uncomment when executing migration on production DB
-- ALTER TABLE subjects DROP COLUMN faculty, DROP COLUMN semester, DROP COLUMN institution_id;
-- ALTER TABLE students DROP COLUMN class_id;
-- ALTER TABLE notification_targets DROP COLUMN class_id;
-- DROP TABLE academic_classes;
