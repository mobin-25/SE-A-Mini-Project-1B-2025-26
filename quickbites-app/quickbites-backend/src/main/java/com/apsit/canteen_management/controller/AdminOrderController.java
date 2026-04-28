package com.apsit.canteen_management.controller;

import com.apsit.canteen_management.dto.OrderClaimRequest;
import com.apsit.canteen_management.dto.OrderTicketDto;
import com.apsit.canteen_management.enums.OrderStatus;
import com.apsit.canteen_management.service.AdminOrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/admin/orders")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminOrderController {
    private final AdminOrderService adminOrderService;

    @GetMapping
    public ResponseEntity<Page<OrderTicketDto>> getOrderByOrderStatus(
                                @RequestParam OrderStatus orderStatus,
                                @RequestParam(required = false, defaultValue = "0") int pageNo
                            ){
        return adminOrderService.getOrderByOrderStatus(orderStatus, pageNo);
    }
    @PostMapping("/{orderId}/accept")
    public ResponseEntity<?> acceptPendingOrder(@PathVariable Long orderId){
        return adminOrderService.acceptPendingOrder(orderId);
    }
    @PostMapping("/{orderId}/ready")
    public ResponseEntity<?> markOrderReady(@PathVariable Long orderId){
        return adminOrderService.markOrderReady(orderId);
    }
    @PostMapping("/deliver")
    public ResponseEntity<?> verifyAndClaimOrder(@RequestBody OrderClaimRequest orderClaimRequest){
        return adminOrderService.verifyAndClaimOrder(orderClaimRequest.getOrderToken());
    }
    @PostMapping("/{orderId}/reject")
    public ResponseEntity<?> rejectOrder(@PathVariable Long orderId){
        return adminOrderService.rejectOrder(orderId);
    }

    //Dashboard APIs
    //like
    // pending:35
    // In-Progress:6
    // Ready: 4
    @GetMapping("/count")
    public long countOrdersByStatus(@RequestParam OrderStatus orderStatus){
        return adminOrderService.countByOrderStatus(orderStatus);
    }
    // delivered today:
    @GetMapping("/delivered/count")
    public long countDeleveredOrderToday(){
        return adminOrderService.countOrdersCompletedToday();
    }



}
