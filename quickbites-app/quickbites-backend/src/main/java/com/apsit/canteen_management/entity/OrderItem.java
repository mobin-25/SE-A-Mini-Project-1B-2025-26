package com.apsit.canteen_management.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class OrderItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long orderItemId;
    @ManyToOne
    @JoinColumn(name = "order_id", nullable = false)
    private OrderTicket orderTicket;
    @ManyToOne
    @JoinColumn(name = "item_id", nullable=false)
    private MenuItem menuItem;
    private Integer quantity;
    // price of the item when order was placed
    private double historicalPrice;
}
