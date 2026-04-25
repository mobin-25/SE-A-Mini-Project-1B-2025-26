package com.apsit.canteen_management.controller;

import com.apsit.canteen_management.dto.*;
import com.apsit.canteen_management.service.AuthService;
import com.apsit.canteen_management.service.RefreshTokenService;
import com.apsit.canteen_management.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {
    private final AuthService authService;
    private final UserService userService;
    private final RefreshTokenService refreshTokenService;

    @PostMapping("/login")
    public ResponseEntity<LoginResponseDto> login(@RequestBody LoginRequestDto loginRequestDto){
        return ResponseEntity.ok(authService.login(loginRequestDto));
    }

    @PostMapping("/signup")
    public ResponseEntity<SignupResponseDto> signup(@RequestBody SignupRequestDto signupRequestDto){ // using LoginRequestDto for now as SignupRequestDto will also have same fields.
        return ResponseEntity.ok(authService.signup(signupRequestDto));
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping("/change-password")
    public ResponseEntity<UserResponseDto> changePass(@RequestBody PassChangeRequestDto passChangeRequestDto){
        return userService.changePass(passChangeRequestDto);
    }

    @PostMapping("/admin-login")
    public ResponseEntity<?> adminLogin(@RequestBody LoginRequestDto loginRequestDto){
        return ResponseEntity.ok(authService.adminLogin(loginRequestDto));
    }

    //make it later accessible only to super admin
    @PostMapping("/admin/signup")
    public ResponseEntity<SignupResponseDto> adminSignup(@RequestBody AdminSignupReqDto adminSignupReqDto){
        return authService.adminSignUp(adminSignupReqDto);
    }
    @PostMapping("/refresh-jwt")
    public ResponseEntity<?> refreshJwt(@RequestBody RefreshTokenRequestDto refreshTokenRequestDto){
        return refreshTokenService.refreshJwt(refreshTokenRequestDto);
    }

}
