package com.apsit.canteen_management.service;

import com.apsit.canteen_management.dto.RefreshTokenRequestDto;
import com.apsit.canteen_management.dto.RefreshTokenResponseDto;
import com.apsit.canteen_management.entity.Admin;
import com.apsit.canteen_management.entity.User;
import com.apsit.canteen_management.error.InvalidRefreshTokenException;
import com.apsit.canteen_management.entity.RefreshToken;
import com.apsit.canteen_management.repository.AdminRepository;
import com.apsit.canteen_management.repository.RefreshTokenRepository;
import com.apsit.canteen_management.repository.UserRepository;
import com.apsit.canteen_management.security.AuthUtil;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class RefreshTokenService {
    private final RefreshTokenRepository refreshTokenRepository;
    private final UserRepository userRepository;
    private final AdminRepository adminRepository;

    private final long REFRESH_TOKEN_EXPIRATION_MS = 2592000000L;
    private final AuthUtil authUtil;

    @Transactional
    public String createRefreshToken(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new InvalidRefreshTokenException("User not found for refresh token generation"));

        String rawToken = generateRawRefreshToken();
        String hashedToken = hashRefreshToken(rawToken);
        Instant expiry = Instant.now().plusMillis(REFRESH_TOKEN_EXPIRATION_MS);

        // Find the existing token for the user, or create a new empty one if it doesn't exist
        RefreshToken refreshToken = refreshTokenRepository.findByUser(user)
                .orElseGet(() -> RefreshToken.builder().user(user).build());

        // Update the values
        refreshToken.setTokenHash(hashedToken);
        refreshToken.setExpiryDate(expiry);

        // Save will perform an UPDATE if it already exists, or an INSERT if it's new
        refreshTokenRepository.save(refreshToken);

        return rawToken;
    }

    @Transactional
    public String createAdminRefreshToken(Long adminId) {
        Admin admin=adminRepository.findById(adminId)
                .orElseThrow(()->new RuntimeException("Admin not present to refresh token"));

        String rawToken=UUID.randomUUID().toString();
        String hashedToken=hashRefreshToken(rawToken);
        Instant expiry = Instant.now().plusMillis(REFRESH_TOKEN_EXPIRATION_MS);
        RefreshToken refreshToken = refreshTokenRepository.findByAdmin(admin)
                .orElseGet(() -> RefreshToken.builder().admin(admin).build());

        // Update the values
        refreshToken.setTokenHash(hashedToken);
        refreshToken.setExpiryDate(expiry);

        // Save will perform an UPDATE if it already exists, or an INSERT if it's new
        refreshTokenRepository.save(refreshToken);

        return rawToken;
    }


    // verify if the access token of jwt refresh is valid or not
    public RefreshToken verifyExpiration(RefreshToken token){
        if(token.getExpiryDate().compareTo(Instant.now())<0){
            refreshTokenRepository.delete(token);
            throw new InvalidRefreshTokenException("Refresh token expired");
        }
        return token;
    }
    //refresh the expired jwt
    public ResponseEntity<?> refreshJwt(RefreshTokenRequestDto refreshTokenRequestDto){
        String token = refreshTokenRequestDto.getRefreshToken();
        if (token == null || token.isBlank()) {
            throw new InvalidRefreshTokenException("Refresh token is required");
        }

        return refreshTokenRepository.findByTokenHash(hashRefreshToken(token))
                .map(this::verifyExpiration)
                .map(this::rotateTokenAndBuildResponse)
                .orElseThrow(() -> new InvalidRefreshTokenException("Invalid refresh token"));
    }
    //at each refresh the access token is also getting refreshed as if someone somehow got the access token they get permanent access.
    private ResponseEntity<RefreshTokenResponseDto> rotateTokenAndBuildResponse(RefreshToken refreshToken) {
        String rotatedRawToken = generateRawRefreshToken();
        refreshToken.setTokenHash(hashRefreshToken(rotatedRawToken));
        refreshToken.setExpiryDate(Instant.now().plusMillis(REFRESH_TOKEN_EXPIRATION_MS));
        refreshTokenRepository.save(refreshToken);

        String newJwt;
        // Check if the token belongs to a User or an Admin
        if (refreshToken.getUser() != null) {
            newJwt = authUtil.generateToken(refreshToken.getUser());
        } else if (refreshToken.getAdmin() != null) {
            newJwt = authUtil.generateToken(refreshToken.getAdmin());
        } else {
            // Failsafe in case a token is somehow orphaned in the database
            throw new InvalidRefreshTokenException("Token is orphaned (has no user or admin assigned)");
        }
        return ResponseEntity.ok(new RefreshTokenResponseDto(newJwt, rotatedRawToken));
    }

    //generates random raw string
    private String generateRawRefreshToken() {
        return UUID.randomUUID().toString();
    }
    //Hashes the raw string to make it secure
    private String hashRefreshToken(String rawToken) {
        try {
            MessageDigest messageDigest = MessageDigest.getInstance("SHA-256");
            byte[] digest = messageDigest.digest(rawToken.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : digest) {
                hexString.append(String.format("%02x", b));
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 algorithm not available", e);
        }
    }
}
