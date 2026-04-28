package com.apsit.canteen_management.service;

import com.apsit.canteen_management.dto.AdminDto;
import com.apsit.canteen_management.dto.PassChangeRequestDto;
import com.apsit.canteen_management.entity.Admin;
import com.apsit.canteen_management.repository.AdminRepository;
import lombok.RequiredArgsConstructor;
import org.modelmapper.ModelMapper;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AdminService {
    private final ModelMapper modelMapper;
    private final AdminRepository adminRepository;
    private final PasswordEncoder passwordEncoder;

    public Admin getAdmin(){
        return (Admin) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }

    public AdminDto getProfile(){
        return modelMapper.map(getAdmin(),AdminDto.class);
    }

    public AdminDto updateProfile(AdminDto adminDto){
        Admin admin=getAdmin();
        admin.setUsername(adminDto.getUsername());
        admin.setEmail(adminDto.getEmail());
        admin.setStaffCount(adminDto.getStaffCount());
        return modelMapper.map(adminRepository.save(admin), AdminDto.class);
    }
    public AdminDto changePassword(PassChangeRequestDto passChangeRequestDto){
        Admin admin=getAdmin();
        if(passwordEncoder.matches(passChangeRequestDto.getOldPassword(),admin.getPassword())){
            admin.setPassword(passwordEncoder.encode(passChangeRequestDto.getNewPassword()));
            return modelMapper.map(adminRepository.save(admin),AdminDto.class);
        }
        throw new IllegalArgumentException("please enter correct password.");
    }
    public boolean toggleCanteenOpenOrClose(){
        Admin admin=getAdmin();
        admin.setCanteenOpen(!admin.isCanteenOpen());
        adminRepository.save(admin);
        return admin.isCanteenOpen();
    }
    public boolean isCanteenOpen(){
        Admin admin=getAdmin();
        return admin.isCanteenOpen();
    }
}
