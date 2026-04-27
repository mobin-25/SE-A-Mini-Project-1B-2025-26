package com.apsit.canteen_management.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class CartItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long cartItemId;
    @ManyToOne
    @JoinColumn(name="cart_id", nullable = false)
    private Cart cart;
    @ManyToOne //since many instance of menu item be created as cart item therefore we use many to one relation.
    @JoinColumn(name = "item_id", nullable = false)
    private MenuItem menuItem;
    private Integer quantity;
    private Double cartItemPrice;
    private String cartItemImageUrl;
}
