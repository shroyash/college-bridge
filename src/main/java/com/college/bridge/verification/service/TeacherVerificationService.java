package com.college.bridge.verification.service;

import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.repository.TeacherRepository;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.common.exception.BusinessRuleException;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.verification.dto.ReviewDecisionRequest;
import com.college.bridge.verification.dto.SubmitVerificationRequest;
import com.college.bridge.verification.dto.VerificationStatusResponse;
import com.college.bridge.verification.entity.TeacherVerificationRequest;
import com.college.bridge.verification.entity.VerificationStatus;
import com.college.bridge.verification.repository.TeacherVerificationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Manages the full Teacher Verification lifecycle —
 * submission, admin review, role upgrade, and rejection.
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class TeacherVerificationService {

    private final TeacherVerificationRepository verificationRepository;
    private final UserRepository userRepository;
    private final TeacherRepository teacherRepository;

    // -------------------------------------------------------------------------
    // Student — submit request
    // -------------------------------------------------------------------------

    /**
     * Submits a new Teacher Verification Request for the given user.
     * <p>
     * Business rules enforced:
     * <ul>
     *   <li>User must not already have a PENDING or APPROVED request.</li>
     *   <li>User must not already be a teacher.</li>
     * </ul>
     */
    public VerificationStatusResponse submitRequest(Long userId, SubmitVerificationRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));

        // Guard: already a teacher
        if (user.getRole() == UserRole.TEACHER) {
            throw new BusinessRuleException("You are already a verified teacher.");
        }

        // Guard: existing request
        verificationRepository.findByUser(user).ifPresent(existing -> {
            if (existing.getStatus() == VerificationStatus.PENDING) {
                throw new BusinessRuleException("You already have a pending verification request.");
            }
            if (existing.getStatus() == VerificationStatus.APPROVED) {
                throw new BusinessRuleException("Your verification has already been approved.");
            }
            // REJECTED: allow resubmission — delete old and create fresh
            verificationRepository.delete(existing);
        });

        TeacherVerificationRequest saved = verificationRepository.save(
                TeacherVerificationRequest.builder()
                        .user(user)
                        .documentUrls(request.getDocumentUrls())
                        .status(VerificationStatus.PENDING)
                        .build()
        );

        log.info("Teacher verification request submitted by user {} (id={}).", user.getEmail(), userId);
        return toResponse(saved);
    }

    // -------------------------------------------------------------------------
    // Student — view own request
    // -------------------------------------------------------------------------

    public VerificationStatusResponse getMyRequest(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));

        TeacherVerificationRequest request = verificationRepository.findByUser(user)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "No verification request found for this user."
                ));

        return toResponse(request);
    }

    // -------------------------------------------------------------------------
    // Admin — list pending
    // -------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public List<VerificationStatusResponse> getPendingRequests() {
        return verificationRepository.findByStatus(VerificationStatus.PENDING)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // -------------------------------------------------------------------------
    // Admin — approve
    // -------------------------------------------------------------------------

    /**
     * Approves a verification request.
     * <p>
     * Side effects:
     * <ul>
     *   <li>Request status → APPROVED</li>
     *   <li>User role upgraded to ROLE_TEACHER</li>
     *   <li>Teacher profile record created</li>
     * </ul>
     */
    public VerificationStatusResponse approveRequest(Long adminUserId, Long requestId) {
        User admin = userRepository.findById(adminUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Admin user", adminUserId));

        TeacherVerificationRequest verRequest = verificationRepository.findById(requestId)
                .orElseThrow(() -> new ResourceNotFoundException("Verification request", requestId));

        if (verRequest.getStatus() != VerificationStatus.PENDING) {
            throw new BusinessRuleException(
                    "Request is not in PENDING state. Current status: " + verRequest.getStatus()
            );
        }

        // Update request
        verRequest.setStatus(VerificationStatus.APPROVED);
        verRequest.setReviewedBy(admin);
        verRequest.setReviewedAt(LocalDateTime.now());
        verificationRepository.save(verRequest);

        // Upgrade role
        User applicant = verRequest.getUser();
        applicant.setRole(UserRole.TEACHER);
        userRepository.save(applicant);

        // Create Teacher profile if not already present
        if (!teacherRepository.existsByUser(applicant)) {
            teacherRepository.save(Teacher.builder().user(applicant).build());
        }

        log.info("User {} approved as teacher by admin {} (requestId={}).",
                applicant.getEmail(), admin.getEmail(), requestId);

        return toResponse(verRequest);
    }

    // -------------------------------------------------------------------------
    // Admin — reject
    // -------------------------------------------------------------------------

    /**
     * Rejects a verification request with a mandatory reason.
     */
    public VerificationStatusResponse rejectRequest(Long adminUserId, Long requestId,
                                                    ReviewDecisionRequest decisionRequest) {
        User admin = userRepository.findById(adminUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Admin user", adminUserId));

        TeacherVerificationRequest verRequest = verificationRepository.findById(requestId)
                .orElseThrow(() -> new ResourceNotFoundException("Verification request", requestId));

        if (verRequest.getStatus() != VerificationStatus.PENDING) {
            throw new BusinessRuleException(
                    "Request is not in PENDING state. Current status: " + verRequest.getStatus()
            );
        }

        if (decisionRequest.getRejectionReason() == null || decisionRequest.getRejectionReason().isBlank()) {
            throw new BusinessRuleException("A rejection reason must be provided.");
        }

        verRequest.setStatus(VerificationStatus.REJECTED);
        verRequest.setRejectionReason(decisionRequest.getRejectionReason());
        verRequest.setReviewedBy(admin);
        verRequest.setReviewedAt(LocalDateTime.now());
        verificationRepository.save(verRequest);

        log.info("Verification request {} rejected by admin {} with reason: {}",
                requestId, admin.getEmail(), decisionRequest.getRejectionReason());

        return toResponse(verRequest);
    }

    // -------------------------------------------------------------------------
    // Mapper
    // -------------------------------------------------------------------------

    private VerificationStatusResponse toResponse(TeacherVerificationRequest req) {
        return VerificationStatusResponse.builder()
                .requestId(req.getRequestId())
                .applicantName(req.getUser().getName())
                .applicantEmail(req.getUser().getEmail())
                .status(req.getStatus())
                .documentUrls(req.getDocumentUrls())
                .rejectionReason(req.getRejectionReason())
                .reviewedByName(req.getReviewedBy() != null ? req.getReviewedBy().getName() : null)
                .submittedAt(req.getSubmittedAt())
                .reviewedAt(req.getReviewedAt())
                .build();
    }
}
