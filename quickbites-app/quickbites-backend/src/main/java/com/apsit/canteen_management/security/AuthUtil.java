package com.apsit.canteen_management.security;

import com.apsit.canteen_management.entity.Admin;
import com.apsit.canteen_management.entity.User;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;
import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.List;
import java.util.function.Function;

@Component
public class AuthUtil {
    @Value("${jwt.secretKey}")
    private String secretKey;

    private SecretKey getSecretKey(){
        return Keys.hmacShaKeyFor(secretKey.getBytes(StandardCharsets.UTF_8));
    }

    private <T> T extractClaim(String token, Function<Claims,T> claimsResolver){
        final Claims claims= extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    private Claims extractAllClaims(String token){
        return Jwts.parser()
                .verifyWith(getSecretKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
    public String generateToken(User user){
        return Jwts.builder()
                .subject(user.getUsername())
                .claim("userId", user.getUserId().toString())
                .claim("role", user.getRole())
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis()+(1000*60*5)))
                .signWith(getSecretKey())
                .compact();
    }

    public String generateToken(Admin admin){
        return Jwts.builder()
                .subject(admin.getUsername())
                .claim("userId", admin.getAdminId().toString())
                .claim("role", admin.getRole())
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis()+(1000*60*5)))
                .signWith(getSecretKey())
                .compact();
    }

    public String getUsernameFromToken(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    public String extractRole(String token){
        return extractClaim(token, claims->claims.get("role", String.class));
    }

    public List<GrantedAuthority> getAuthoritiesFromToken(String token){
        return List.of(new SimpleGrantedAuthority("ROLE_"+extractRole(token)));
    }

    public Date getExpireAtFromToken(String token){
        return extractClaim(token, Claims::getExpiration);
    }
}
