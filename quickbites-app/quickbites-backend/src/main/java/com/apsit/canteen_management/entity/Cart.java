package com.apsit.canteen_management.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.List;

@Entity
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Cart {
    @Id
    private Long cartId;
    @OneToOne
    @MapsId
    @JoinColumn(name = "user_id")
    private User user;
    @OneToMany(mappedBy = "cart", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<CartItem> cartItems;
    private Double totalCartPrice;
    private int estPrepTime;

    public void addItemToCart(CartItem cartItem){
        cartItems.add(cartItem);
    }
}
