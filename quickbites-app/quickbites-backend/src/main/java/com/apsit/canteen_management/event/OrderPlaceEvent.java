package com.apsit.canteen_management.event;

import com.apsit.canteen_management.dto.OrderTicketDto;
import com.apsit.canteen_management.entity.Admin;
import lombok.Builder;

@Builder
public record OrderPlaceEvent(OrderTicketDto orderTicketDto){
}
