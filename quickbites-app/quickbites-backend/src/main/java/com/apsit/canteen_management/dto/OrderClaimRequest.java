package com.apsit.canteen_management.dto;

import lombok.*;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class OrderClaimRequest {
    @NonNull
    private String orderToken;
}
