package com.apsit.canteen_management.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class AdminSignupReqDto {
    private String username;
    private String email;
    private String password;
    private String role;
}
