@Entity
public class Doubt {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String question;
    private String studentName;
    private String subject;
    private String status;

    // Getters and Setters
}