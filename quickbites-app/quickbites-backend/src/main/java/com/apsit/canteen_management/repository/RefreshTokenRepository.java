package com.apsit.canteen_management.repository;

import com.apsit.canteen_management.entity.Admin;
import com.apsit.canteen_management.entity.RefreshToken;
import com.apsit.canteen_management.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface RefreshTokenRepository extends JpaRepository<RefreshToken,Long> {
    Optional<RefreshToken> findByTokenHash(String tokenHash);
    Optional<RefreshToken> findByUser(User user);
    Optional<RefreshToken> findByAdmin(Admin admin);
    void deleteByUser(User user);
}
