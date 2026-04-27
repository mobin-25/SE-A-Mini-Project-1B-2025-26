package com.apsit.canteen_management.service;

import com.apsit.canteen_management.dto.*;
import com.apsit.canteen_management.entity.Admin;
import com.apsit.canteen_management.entity.Cart;
import com.apsit.canteen_management.entity.User;
import com.apsit.canteen_management.enums.Role;
import com.apsit.canteen_management.repository.AdminRepository;
import com.apsit.canteen_management.repository.UserRepository;
import com.apsit.canteen_management.security.AuthUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final AuthenticationManager authenticationManager;
    private final UserRepository userRepository;
    private final AuthUtil authUtil;
    private final PasswordEncoder passwordEncoder;
    private final AdminRepository adminRepository;
    private final RefreshTokenService refreshTokenService;

    public LoginResponseDto login(LoginRequestDto loginRequestDto) {
        Authentication authentication=authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(loginRequestDto.getUsername(), loginRequestDto.getPassword())
        );

        Object principal=authentication.getPrincipal();
        if(!(principal instanceof User)){
            throw new IllegalArgumentException("Admins must use admin login portal!");
        }
        User user=(User) principal;
        String refreshToken = refreshTokenService.createRefreshToken(user.getUserId());
        return new LoginResponseDto(authUtil.generateToken(user), refreshToken, user.getUserId());
    }

    @Transactional
    public SignupResponseDto signup(SignupRequestDto signupRequestDto) {
        User user = userRepository.findByUsername(signupRequestDto.getUsername()).orElse(null);
        if (user != null) throw new IllegalArgumentException("User already exist ! \n Try with different username.");
        user = User.builder()
                .username(signupRequestDto.getUsername())
                .password(passwordEncoder.encode(signupRequestDto.getPassword()))
                .email(signupRequestDto.getUsername() + "@apsit.edu.in")
                .mobileNumber(signupRequestDto.getMobileNumber())
                .role(Role.valueOf(signupRequestDto.getRole()))
                .profilePictureUrl(null)
                .build();
        Cart cart= new Cart();
        cart.setUser(user);
        user.setCart(cart);
        userRepository.save(user);
        return new SignupResponseDto(user.getUserId(), user.getUsername());
    }

    public LoginResponseDto adminLogin(LoginRequestDto loginRequestDto){
        Authentication authentication=authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(loginRequestDto.getUsername(), loginRequestDto.getPassword())
        );

        Object principal=authentication.getPrincipal();
        if(!(principal instanceof Admin)){
            throw new IllegalArgumentException("Users must use user login portal!");
        }

        Admin admin=(Admin) principal;
        String refreshToken = refreshTokenService.createAdminRefreshToken(admin.getAdminId());
        return new LoginResponseDto(authUtil.generateToken(admin), refreshToken, admin.getAdminId());
    }

    public ResponseEntity<SignupResponseDto> adminSignUp(AdminSignupReqDto adminSignupReqDto){
        Admin admin= Admin.builder()
                .email(adminSignupReqDto.getEmail())
                .username(adminSignupReqDto.getUsername())
                .password(passwordEncoder.encode(adminSignupReqDto.getPassword()))
                .role(Role.valueOf(adminSignupReqDto.getRole()))
                .build();
        adminRepository.save(admin);
        return ResponseEntity.ok(new SignupResponseDto(admin.getAdminId(), admin.getUsername()));
    }
}
