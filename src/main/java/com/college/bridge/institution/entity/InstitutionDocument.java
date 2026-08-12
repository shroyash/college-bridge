package com.college.bridge.institution.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "institution_documents")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InstitutionDocument {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "document_id")
    private Long documentId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "institution_id", nullable = false)
    private Institution institution;

    @Column(name = "document_url", nullable = false, length = 255)
    private String documentUrl;

    @Column(name = "document_type", length = 100)
    private String documentType;

    @CreationTimestamp
    @Column(name = "uploaded_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime uploadedAt = LocalDateTime.now();
}
