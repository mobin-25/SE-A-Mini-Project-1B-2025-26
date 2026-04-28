package com.apsit.canteen_management.event;

import com.apsit.canteen_management.dto.OrderTicketDto;
import lombok.AllArgsConstructor;
import lombok.Builder;
@Builder
public record OrderUpdateEvent(String username, OrderTicketDto orderTicketDto) {
}
