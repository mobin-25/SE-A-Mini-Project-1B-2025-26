package com.apsit.canteen_management.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class UserResponseDto {
    private String username;
    private String mobileNumber;
    private String email;
    private String profilePictureUrl;
}
