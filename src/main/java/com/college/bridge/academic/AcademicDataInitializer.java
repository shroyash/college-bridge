package com.college.bridge.academic;

import com.college.bridge.academic.entity.AcademicClass;
import com.college.bridge.academic.entity.Faculty;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.repository.AcademicClassRepository;
import com.college.bridge.academic.repository.SubjectRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

/**
 * Seeds academic master data (classes and subjects) on application startup.
 * <p>
 * This data is idempotent — already-existing records are skipped.
 * Subject lists reflect a typical Nepali college curriculum for each faculty/semester.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class AcademicDataInitializer implements CommandLineRunner {

    private final AcademicClassRepository academicClassRepository;
    private final SubjectRepository subjectRepository;

    private static final String[] ORDINALS = {
        "", "First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh", "Eighth"
    };

    /**
     * Faculty → Semester → Subject list seed data.
     */
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
        ),
        Faculty.BBA, Map.of(
            1, List.of("Business Mathematics", "Financial Accounting I", "Business English", "Economics I", "Computer Applications"),
            2, List.of("Business Statistics", "Financial Accounting II", "Business Communication", "Economics II", "Organizational Behaviour"),
            3, List.of("Cost Accounting", "Business Law", "Marketing Management", "Human Resource Management", "Research Methodology"),
            4, List.of("Management Accounting", "Business Finance", "Production Management", "Entrepreneurship", "Elective I"),
            5, List.of("Strategic Management", "International Business", "E-Commerce", "Elective II"),
            6, List.of("Business Ethics", "Project Work", "Elective III"),
            7, List.of("Thesis / Major Project"),
            8, List.of("Internship")
        ),
        Faculty.BSC_CSIT, Map.of(
            1, List.of("Mathematics I", "Physics", "Digital Logic", "C Programming", "English I"),
            2, List.of("Mathematics II", "Statistics", "Data Structures & Algorithms", "Object Oriented Programming", "Microprocessor"),
            3, List.of("Operating Systems", "Database Management Systems", "Computer Architecture", "Numerical Methods", "Web Technology"),
            4, List.of("Computer Networks", "Theory of Computation", "Artificial Intelligence", "Software Engineering", "Advanced Java"),
            5, List.of("Compiler Design", "Computer Graphics", "Advanced Database Systems", "Project I", "Elective I"),
            6, List.of("Distributed Systems", "Information Security", "Project II", "Elective II"),
            7, List.of("Major Project I", "Machine Learning", "Cloud Computing"),
            8, List.of("Major Project II", "Internship")
        ),
        Faculty.BIM, Map.of(
            1, List.of("Mathematics", "Financial Accounting", "Computer Fundamentals", "Business English", "Microeconomics"),
            2, List.of("Statistics", "Cost Accounting", "Programming Logic", "Business Communication", "Macroeconomics"),
            3, List.of("Management Information Systems", "Database Management", "Networking", "Business Law", "HR Management"),
            4, List.of("E-Commerce", "System Analysis & Design", "Business Intelligence", "Marketing", "Elective I"),
            5, List.of("ERP Systems", "Project Management", "Information Security", "Elective II"),
            6, List.of("IT Audit", "Research Project", "Elective III"),
            7, List.of("Major Project"),
            8, List.of("Internship")
        ),
        Faculty.BHM, Map.of(
            1, List.of("Food & Beverage Service I", "Front Office Operations I", "Housekeeping I", "English I", "Hospitality Mathematics"),
            2, List.of("Food & Beverage Service II", "Front Office Operations II", "Housekeeping II", "English II", "Communication Skills"),
            3, List.of("Food Production I", "Accommodation Management", "Tourism Management", "Business Accounting", "Personnel Management"),
            4, List.of("Food Production II", "Hotel Operations Management", "Event Management", "Entrepreneurship", "Elective I"),
            5, List.of("Revenue Management", "Property Management", "Resort Management", "Elective II"),
            6, List.of("Strategic Hospitality Management", "Research Project"),
            7, List.of("Industrial Training I"),
            8, List.of("Industrial Training II")
        )
    );

    @Override
    @Transactional
    public void run(String... args) {
        log.info("Seeding academic master data…");
        int classCount = 0;
        int subjectCount = 0;

        for (Map.Entry<Faculty, Map<Integer, List<String>>> facultyEntry : CURRICULUM.entrySet()) {
            Faculty faculty = facultyEntry.getKey();

            for (Map.Entry<Integer, List<String>> semEntry : facultyEntry.getValue().entrySet()) {
                int semester = semEntry.getKey();
                List<String> subjects = semEntry.getValue();

                // Seed AcademicClass
                if (!academicClassRepository.existsByFacultyAndSemester(faculty, semester)) {
                    String ordinal = semester < ORDINALS.length ? ORDINALS[semester] : semester + "th";
                    String displayName = formatFacultyName(faculty) + " " + ordinal + " Semester";
                    academicClassRepository.save(AcademicClass.builder()
                            .faculty(faculty)
                            .semester(semester)
                            .displayName(displayName)
                            .build());
                    classCount++;
                }

                // Seed Subjects
                for (String subjectName : subjects) {
                    if (!subjectRepository.existsByNameAndFacultyAndSemester(subjectName, faculty, semester)) {
                        subjectRepository.save(Subject.builder()
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

        log.info("Academic seed complete — {} classes, {} subjects created.", classCount, subjectCount);
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
