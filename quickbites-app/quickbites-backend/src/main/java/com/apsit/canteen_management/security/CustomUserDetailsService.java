package com.apsit.canteen_management.security;

import com.apsit.canteen_management.entity.Admin;
import com.apsit.canteen_management.entity.User;
import com.apsit.canteen_management.repository.AdminRepository;
import com.apsit.canteen_management.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.NonNull;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;
    private final AdminRepository adminRepository;
    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        Optional<User> user=userRepository.findByUsername(username);
        if(user.isPresent()){
            return user.get();
        }
        Optional<Admin> admin=adminRepository.findByUsername(username);
        if(admin.isPresent()){
            return admin.get();
        }
        throw new UsernameNotFoundException("user/admin not found with this username");
    }
}
