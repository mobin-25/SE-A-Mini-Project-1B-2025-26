package com.apsit.canteen_management.controller;

import com.apsit.canteen_management.dto.OrderTicketDto;
import com.apsit.canteen_management.dto.UserResponseDto;
import com.apsit.canteen_management.entity.User;
import com.apsit.canteen_management.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/users")
@PreAuthorize("hasRole('STUDENT') or hasRole('STAFF')")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/{username}")
    public ResponseEntity<UserResponseDto> findByUsername(@PathVariable String username){
        return userService.findByUsername(username);
    }
    @PostMapping("/updateProfilePic")
    public ResponseEntity<UserResponseDto> uploadProfilePicture(@ModelAttribute MultipartFile profilePicture ){
        return userService.uploadProfilePicture(profilePicture);
    }
    @GetMapping
    public ResponseEntity<UserResponseDto> getUser(){
        return userService.getUserDto();
    }

    @GetMapping("/my-orders")
    public ResponseEntity<Page<OrderTicketDto>> myOrders(
            @RequestParam(required = false, defaultValue = "0") int pageNo
    ){
        return userService.myOrders(pageNo);
    }

}
