package com.college.bridge.academic;

import com.college.bridge.academic.entity.AcademicLevel;
import com.college.bridge.academic.entity.AcademicLevelType;
import com.college.bridge.academic.entity.AcademicProgram;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.repository.AcademicLevelRepository;
import com.college.bridge.academic.repository.AcademicProgramRepository;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.entity.InstitutionStatus;
import com.college.bridge.institution.repository.InstitutionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

/**
 * Seeds academic master data (programs, levels, and subjects) for default institution on application startup.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class AcademicDataInitializer implements CommandLineRunner {

    private final AcademicProgramRepository programRepository;
    private final AcademicLevelRepository levelRepository;
    private final SubjectRepository subjectRepository;
    private final InstitutionRepository institutionRepository;

    private static final String[] ORDINALS = {
        "", "First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh", "Eighth"
    };

    private static final Map<String, Map<Integer, List<String>>> CURRICULUM = Map.of(
        "BCA", Map.of(
            1, List.of("Mathematics I", "Digital Logic", "Computer Fundamentals", "English I", "Statistics I"),
            2, List.of("Mathematics II", "Data Structures", "Operating Systems", "English II", "Statistics II"),
            3, List.of("Object Oriented Programming", "Database Management Systems", "Discrete Mathematics", "Software Engineering I", "Web Technology"),
            4, List.of("Computer Networks", "System Analysis and Design", "Java Programming", "Numerical Methods", "Visual Programming"),
            5, List.of("Advanced Java", "Data Mining", "Mobile Computing", "Software Project Management", "Elective I"),
            6, List.of("Cloud Computing", "Artificial Intelligence", "Cyber Security", "Project Work", "Elective II"),
            7, List.of("Machine Learning", "Big Data Analytics", "Minor Project"),
            8, List.of("Major Project", "Internship")
        )
    );

    @Override
    @Transactional
    public void run(String... args) {
        log.info("Seeding academic master data…");

        Institution defaultInstitution = institutionRepository.findByCode("DEFAULT")
                .orElseGet(() -> institutionRepository.save(Institution.builder()
                        .name("Default College")
                        .code("DEFAULT")
                        .status(InstitutionStatus.ACTIVE)
                        .build()));

        int levelCount = 0;
        int subjectCount = 0;

        for (Map.Entry<String, Map<Integer, List<String>>> programEntry : CURRICULUM.entrySet()) {
            String programCode = programEntry.getKey();

            AcademicProgram program = programRepository.findByInstitution_InstitutionIdAndCodeAndDeletedFalse(defaultInstitution.getInstitutionId(), programCode)
                    .orElseGet(() -> programRepository.save(AcademicProgram.builder()
                            .institution(defaultInstitution)
                            .name("Bachelor of Computer Application (" + programCode + ")")
                            .code(programCode)
                            .build()));

            for (Map.Entry<Integer, List<String>> semEntry : programEntry.getValue().entrySet()) {
                int semesterNumber = semEntry.getKey();
                List<String> subjects = semEntry.getValue();

                String ordinal = semesterNumber < ORDINALS.length ? ORDINALS[semesterNumber] : semesterNumber + "th";
                String levelName = ordinal + " Semester";

                AcademicLevel level = levelRepository.findByProgram_ProgramIdAndLevelNumberAndDeletedFalse(program.getProgramId(), semesterNumber)
                        .orElseGet(() -> {
                            AcademicLevel newLevel = levelRepository.save(AcademicLevel.builder()
                                    .program(program)
                                    .name(levelName)
                                    .levelNumber(semesterNumber)
                                    .type(AcademicLevelType.SEMESTER)
                                    .build());
                            return newLevel;
                        });

                levelCount++;

                for (String subjectName : subjects) {
                    if (!subjectRepository.existsByAcademicLevel_LevelIdAndNameAndDeletedFalse(level.getLevelId(), subjectName)) {
                        subjectRepository.save(Subject.builder()
                                .academicLevel(level)
                                .name(subjectName)
                                .creditHours(3)
                                .build());
                        subjectCount++;
                    }
                }
            }
        }

        log.info("Academic seed complete — {} levels, {} subjects created for institution {}.", levelCount, subjectCount, defaultInstitution.getCode());
    }
}
