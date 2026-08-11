package com.college.bridge.academic;

import com.college.bridge.academic.entity.AcademicClass;
import com.college.bridge.academic.entity.Faculty;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.repository.AcademicClassRepository;
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
 * Seeds academic master data (classes and subjects) for default institution on application startup.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class AcademicDataInitializer implements CommandLineRunner {

    private final AcademicClassRepository academicClassRepository;
    private final SubjectRepository subjectRepository;
    private final InstitutionRepository institutionRepository;

    private static final String[] ORDINALS = {
        "", "First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh", "Eighth"
    };

    private static final Map<Faculty, Map<Integer, List<String>>> CURRICULUM = Map.of(
        Faculty.BCA, Map.of(
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

        int classCount = 0;
        int subjectCount = 0;

        for (Map.Entry<Faculty, Map<Integer, List<String>>> facultyEntry : CURRICULUM.entrySet()) {
            Faculty faculty = facultyEntry.getKey();

            for (Map.Entry<Integer, List<String>> semEntry : facultyEntry.getValue().entrySet()) {
                int semester = semEntry.getKey();
                List<String> subjects = semEntry.getValue();

                if (!academicClassRepository.existsByInstitution_InstitutionIdAndFacultyAndSemester(defaultInstitution.getInstitutionId(), faculty, semester)) {
                    String ordinal = semester < ORDINALS.length ? ORDINALS[semester] : semester + "th";
                    String displayName = formatFacultyName(faculty) + " " + ordinal + " Semester";
                    academicClassRepository.save(AcademicClass.builder()
                            .institution(defaultInstitution)
                            .faculty(faculty)
                            .semester(semester)
                            .displayName(displayName)
                            .build());
                    classCount++;
                }

                for (String subjectName : subjects) {
                    if (!subjectRepository.existsByInstitution_InstitutionIdAndNameAndFacultyAndSemester(defaultInstitution.getInstitutionId(), subjectName, faculty, semester)) {
                        subjectRepository.save(Subject.builder()
                                .institution(defaultInstitution)
                                .name(subjectName)
                                .faculty(faculty)
                                .semester(semester)
                                .creditHours(3)
                                .build());
                        subjectCount++;
                    }
                }
            }
        }

        log.info("Academic seed complete — {} classes, {} subjects created for institution {}.", classCount, subjectCount, defaultInstitution.getCode());
    }

    private String formatFacultyName(Faculty faculty) {
        return switch (faculty) {
            case BCA -> "BCA";
            case BBA -> "BBA";
            case BSC_CSIT -> "BSc CSIT";
            case BIM -> "BIM";
            case BHM -> "BHM";
        };
    }
}
