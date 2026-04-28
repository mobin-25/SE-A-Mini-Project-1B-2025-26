package com.apsit.canteen_management.entity;

import com.apsit.canteen_management.enums.ItemCategory;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.web.multipart.MultipartFile;

@Entity
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
@Builder
public class MenuItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long itemId;
    @Column(nullable = false, unique = true)
    private String itemName;
    @Column(nullable = false)
    private Double price;
    @Column(nullable = false)
    private String imageUrl;
    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private ItemCategory category;
    @Column(nullable = false)
    private boolean isAvailable;
    private int readyIn;
}
