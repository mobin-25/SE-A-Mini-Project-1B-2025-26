package com.apsit.canteen_management.dto;

import com.apsit.canteen_management.enums.ItemCategory;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.web.multipart.MultipartFile;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class SaveItemDto {
    private String itemName;
    private double price;
    private MultipartFile itemImage;
    private ItemCategory category;
    private boolean isAvailable;
    private int readyIn;
}
