package com.apsit.canteen_management.controller;

import com.apsit.canteen_management.dto.AdminDto;
import com.apsit.canteen_management.dto.PassChangeRequestDto;
import com.apsit.canteen_management.service.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/admin/profile")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class AdminController {
    private final AdminService adminService;
    @GetMapping
    public ResponseEntity<AdminDto> getProfile(){
        return ResponseEntity.ok(adminService.getProfile());
    }
    @PostMapping("/update")
    public ResponseEntity<AdminDto> updateProfile(@RequestBody AdminDto adminDto){
        return ResponseEntity.ok(adminService.updateProfile(adminDto));
    }
    @PostMapping("/change-pass")
    public ResponseEntity<?> changePass(@RequestBody PassChangeRequestDto passChangeRequestDto){
        return ResponseEntity.ok(adminService.changePassword(passChangeRequestDto));
    }
    @PostMapping("/toggle-duty-status")
    public ResponseEntity<?> toggleCanteenOpenOrClose(){
        return ResponseEntity.ok(adminService.toggleCanteenOpenOrClose());
    }
    @GetMapping("/is-canteen-open")
    public ResponseEntity<Boolean> isCanteenOpen(){
        return ResponseEntity.ok(adminService.isCanteenOpen());
    }
}
