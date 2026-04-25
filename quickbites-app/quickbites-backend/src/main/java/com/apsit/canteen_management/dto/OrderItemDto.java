package com.apsit.canteen_management.dto;


import com.apsit.canteen_management.entity.MenuItem;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class OrderItemDto {
    private MenuItem menuItem;
    private int quantity;
    private double historicalPrice;
}
