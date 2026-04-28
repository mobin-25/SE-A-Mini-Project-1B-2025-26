package com.apsit.canteen_management.service;

import com.apsit.canteen_management.dto.OrderTicketDto;
import com.apsit.canteen_management.dto.PassChangeRequestDto;
import com.apsit.canteen_management.dto.UserResponseDto;
import com.apsit.canteen_management.entity.User;
import com.apsit.canteen_management.repository.OrderTicketRepository;
import com.apsit.canteen_management.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.modelmapper.ModelMapper;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;
    private final ModelMapper modelMapper;
    private final CloudinaryServiceImpl cloudinaryService;
    private final PasswordEncoder passwordEncoder;
    private final OrderTicketRepository orderTicketRepository;

    public User getUser(){
        return (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }

    public ResponseEntity<UserResponseDto> findByUsername(String username){
        return userRepository.findByUsername(username)
                .map(user-> modelMapper.map(user, UserResponseDto.class))
                .map(ResponseEntity::ok)
                .orElseGet(()-> ResponseEntity.notFound().build());
    }

    public ResponseEntity<UserResponseDto> uploadProfilePicture(MultipartFile profilePicture) {
        User user=getUser();
        Map info=cloudinaryService.upload(profilePicture);
        user.setProfilePictureUrl(info.get("url").toString());
        return ResponseEntity.ok(modelMapper.map(userRepository.save(user),UserResponseDto.class));
    }

    public ResponseEntity<UserResponseDto> getUserDto() {
        return ResponseEntity.ok(modelMapper.map(getUser(),UserResponseDto.class));
    }

    public ResponseEntity<UserResponseDto> changePass(PassChangeRequestDto passChangeRequestDto){
        User user=getUser();
        if(passwordEncoder.matches(passChangeRequestDto.getOldPassword(), user.getPassword())){
            user.setPassword(passwordEncoder.encode(passChangeRequestDto.getNewPassword()));
            return ResponseEntity.ok(modelMapper.map(userRepository.save(user),UserResponseDto.class));
        }
        return ResponseEntity.badRequest().build();
    }
    public ResponseEntity<Page<OrderTicketDto>> myOrders(int pageNo){
        User user=getUser();
        return ResponseEntity.ok(orderTicketRepository
                .findAllByUsername(
                        user.getUsername(),
                        PageRequest.of(pageNo,10, Sort.by(Sort.Direction.DESC,"createdAt"))
                )
                .map(orderTicket -> modelMapper.map(orderTicket, OrderTicketDto.class))
        );
    }
}
