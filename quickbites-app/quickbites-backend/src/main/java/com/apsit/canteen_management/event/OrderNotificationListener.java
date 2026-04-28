package com.apsit.canteen_management.event;

import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@Component
@RequiredArgsConstructor
public class OrderNotificationListener {
    private final SimpMessagingTemplate messagingTemplate;
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void sendOrderUpdateNotification(OrderUpdateEvent event){
        messagingTemplate.convertAndSendToUser(
                event.username(),
                "/queue/order-updates",
                event.orderTicketDto()
        );
    }
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void sendOrderPlacedNotification(OrderPlaceEvent event){
        messagingTemplate.convertAndSend(
                "/topic/admin/order",
                event.orderTicketDto()
        );
    }
}
