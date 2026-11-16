package com.college.bridge.auth.dto;

import com.college.bridge.auth.entity.OtpType;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VerifyOtpRequest {

    @NotBlank(message = "Email is required.")
    @Email(message = "Invalid email format.")
    private String email;

    @NotBlank(message = "OTP code is required.")
    @Size(min = 6, max = 6, message = "OTP code must be 6 digits.")
    private String code;

    private OtpType type = OtpType.VERIFICATION;
}
