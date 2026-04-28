package com.apsit.canteen_management.service;

import com.cloudinary.Cloudinary;
import lombok.AllArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;
@Service
@RequiredArgsConstructor
public class CloudinaryServiceImpl implements CloudinaryService{
    private final Cloudinary cloudinary;
    @Override
    public Map upload(MultipartFile itemImage) {
        try{
            return cloudinary.uploader().upload(itemImage.getBytes(), Map.of());
        }catch (IOException e){
            throw new RuntimeException("Image upload failed !");
        }

    }
}
