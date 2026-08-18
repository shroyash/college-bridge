package com.college.bridge.auth.service;

import com.college.bridge.auth.dto.SuperAdminUserResponse;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.entity.UserStatus;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.common.response.PageResponse;
import jakarta.persistence.criteria.Predicate;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class SuperAdminUserService {

    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public PageResponse<SuperAdminUserResponse> getUsers(
            Pageable pageable,
            String search,
            UserRole role,
            UserStatus status,
            Long institutionId
    ) {
        Specification<User> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (search != null && !search.trim().isEmpty()) {
                String searchPattern = "%" + search.trim().toLowerCase() + "%";
                Predicate nameLike = cb.like(cb.lower(root.get("name")), searchPattern);
                Predicate emailLike = cb.like(cb.lower(root.get("email")), searchPattern);
                predicates.add(cb.or(nameLike, emailLike));
            }

            if (role != null) {
                predicates.add(cb.equal(root.get("role"), role));
            }

            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            if (institutionId != null) {
                predicates.add(cb.equal(root.get("institution").get("institutionId"), institutionId));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<User> page = userRepository.findAll(spec, pageable);
        Page<SuperAdminUserResponse> dtoPage = page.map(this::toResponse);

        return PageResponse.from(dtoPage);
    }

    @Transactional(readOnly = true)
    public PageResponse<SuperAdminUserResponse> getAdmins(
            Pageable pageable,
            String search,
            UserStatus status
    ) {
        return getUsers(pageable, search, UserRole.ADMIN, status, null);
    }

    private SuperAdminUserResponse toResponse(User user) {
        Long instId = user.getInstitution() != null ? user.getInstitution().getInstitutionId() : null;
        String instName = user.getInstitution() != null ? user.getInstitution().getName() : null;

        return SuperAdminUserResponse.builder()
                .id(user.getUserId())
                .name(user.getName())
                .email(user.getEmail())
                .profileImage(user.getImageUrl())
                .role(user.getRole())
                .status(user.getStatus())
                .institutionId(instId)
                .institutionName(instName)
                .createdAt(user.getCreatedAt())
                .build();
    }
}
