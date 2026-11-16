package com.college.bridge.auth.dto;

import com.college.bridge.auth.entity.UserRole;
import jakarta.validation.constraints.NotNull;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChangeRoleRequest {

    @NotNull(message = "Role is required")
    private UserRole role;
}
