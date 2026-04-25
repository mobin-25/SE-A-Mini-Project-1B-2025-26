package com.apsit.canteen_management.dto;

import lombok.*;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class CartItemDto {
    private Long cartItemId;
    private Double cartItemPrice;
    private Integer quantity;
    private ItemDto menuItem;
}
