package com.apsit.canteen_management.controller;

import com.apsit.canteen_management.dto.OrderTicketDto;
import com.apsit.canteen_management.service.OrderQueueService;
import com.apsit.canteen_management.service.OrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/order")
@PreAuthorize("hasRole('STUDENT') or hasRole('STAFF')")
@RequiredArgsConstructor
public class OrderController {
    private final OrderService orderService;
    private final OrderQueueService orderQueueService;

    @PostMapping("/place")
    public ResponseEntity<OrderTicketDto> placeOrder(){
        return orderService.placeOrder();
    }

    @PostMapping("/get-order-detail/{orderId}")
    public ResponseEntity<OrderTicketDto> getOrderDetails(@PathVariable Long orderId){
        return orderService.getOrderDetails(orderId);
    }

    @PostMapping("/re-order/{orderId}")
    public ResponseEntity<?> reOrder(@PathVariable Long orderId){
        return orderService.reOrder(orderId);
    }

    @PostMapping("/cancel-order/{orderId}")
    public ResponseEntity<?> cancelOrder(@PathVariable Long orderId){
        return orderService.cancelOrder(orderId);
    }

    @GetMapping("/{orderId}/checkWaitTime")
    public ResponseEntity<?> getMyWaitTime(@PathVariable Long orderId){
        return ResponseEntity.ok(orderQueueService.waitTimeForSpecificOrder(orderId));
    }

    @GetMapping("/wait-time")
    public ResponseEntity<?> totalWaitTime(){
        return ResponseEntity.ok(orderQueueService.estWaitTime());
    }
}
