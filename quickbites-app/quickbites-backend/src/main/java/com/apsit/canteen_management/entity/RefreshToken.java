package com.apsit.canteen_management.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class RefreshToken {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long refreshTokenId;

    @Column(name = "token", nullable = false, unique = true)
    private String tokenHash;

    @OneToOne
    @JoinColumn(name = "user_id", referencedColumnName = "userId")
    private User user;

    @OneToOne
    @JoinColumn(name="admin_id", referencedColumnName ="adminId")
    private Admin admin;

    @Column(nullable = false)
    private Instant expiryDate;
}
