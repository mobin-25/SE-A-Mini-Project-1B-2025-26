package com.apsit.canteen_management.dto;

import com.apsit.canteen_management.enums.ItemCategory;
import lombok.Data;
import org.hibernate.annotations.EmbeddedTable;

@Data
public class ItemDto {

    private Long itemId;
    private String itemName;
    private int price;
    private String imageUrl;
    private ItemCategory category;
    private boolean isAvailable;
    private int readyIn;
}
