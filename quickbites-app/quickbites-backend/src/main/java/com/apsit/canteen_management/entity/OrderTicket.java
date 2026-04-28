package com.apsit.canteen_management.entity;

import com.apsit.canteen_management.enums.OrderStatus;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;



@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class OrderTicket {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String username;
    @OneToMany(mappedBy = "orderTicket", cascade = CascadeType.ALL, orphanRemoval = true)
    @Column(nullable = false)
    private List<OrderItem> orderItems;
    @Column(nullable=false)
    private double totalAmount;
    @Enumerated(EnumType.STRING)
    private OrderStatus orderStatus;
    @Column(unique = true)
    private String orderToken;
    private LocalDateTime createdAt;
    private LocalDateTime completedAt;
    private LocalDateTime updatedAt;
    private int estPrepTime;
}
