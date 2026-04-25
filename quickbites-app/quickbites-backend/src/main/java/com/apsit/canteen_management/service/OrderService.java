package com.apsit.canteen_management.service;

import com.apsit.canteen_management.dto.OrderTicketDto;
import com.apsit.canteen_management.entity.*;
import com.apsit.canteen_management.enums.OrderStatus;
import com.apsit.canteen_management.error.ApiError;
import com.apsit.canteen_management.event.OrderPlaceEvent;
import com.apsit.canteen_management.repository.CartRepository;
import com.apsit.canteen_management.repository.OrderItemRepository;
import com.apsit.canteen_management.repository.OrderTicketRepository;
import lombok.RequiredArgsConstructor;
import org.modelmapper.ModelMapper;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class OrderService {
    private final OrderTicketRepository orderTicketRepository;
    private final CartRepository cartRepository;
    private final ModelMapper modelMapper;
    private final OrderItemRepository orderItemRepository;
    private final CartService cartService;
    private final OrderQueueService orderQueueService;
    private final ApplicationEventPublisher eventPublisher;

    public User getloggedUser(){
        return (User)SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
    @Transactional
    public ResponseEntity<OrderTicketDto> placeOrder(){
        User user =getloggedUser();
        Cart cart=cartRepository.findById(user.getUserId()).orElseThrow();
        if(cart.getCartItems()==null || cart.getCartItems().isEmpty()){
            throw new IllegalArgumentException("Can't place order! your cart is empty.\ntry finding something you like!");
        }
        OrderTicket orderTicket= OrderTicket.builder()
                .username(user.getUsername())
                .totalAmount(cart.getTotalCartPrice())
                .createdAt(LocalDateTime.now())
                .orderStatus(OrderStatus.PENDING)
                .estPrepTime(cart.getEstPrepTime())
                .build();

        List<OrderItem> orderItems= cart.getCartItems().stream()
                .map(cartItem ->
                    OrderItem.builder()
                            .orderTicket(orderTicket)
                            .menuItem(cartItem.getMenuItem())
                            .quantity(cartItem.getQuantity())
                            .historicalPrice(cartItem.getCartItemPrice()/ cartItem.getQuantity())
                            .build()
                ).toList();
        orderTicket.setOrderItems(orderItems);

        // Write payments logic here

        OrderTicket placedOrder= orderTicketRepository.save(orderTicket);
        orderQueueService.addPendingOrder(placedOrder);
        cart.getCartItems().clear();
        cart.setTotalCartPrice(0.0);
        cartRepository.save(cart);
        OrderTicketDto dto=modelMapper.map(placedOrder, OrderTicketDto.class);
        eventPublisher.publishEvent(
                new OrderPlaceEvent(dto)
        );
        return ResponseEntity.ok(dto);
    }
    public ResponseEntity<OrderTicketDto> getOrderDetails(Long orderId){
        OrderTicket orderTicket=orderTicketRepository.findById(orderId)
                .orElseThrow(()->new RuntimeException("Order doesn't exist"));
        return ResponseEntity.ok(modelMapper.map(orderTicket, OrderTicketDto.class));
    }
    public ResponseEntity<?> reOrder(Long orderId) {
        User user=getloggedUser();
        OrderTicket orderTicket=orderTicketRepository.findById(orderId)
                .orElseThrow(()->new RuntimeException("No order present with this order id."));
        if(!orderTicket.getUsername().equals(user.getUsername())){
            throw new RuntimeException("You do not belong to this order!");
        }
        List<OrderItem> orderItems=orderItemRepository.findAllByOrderTicket_Id(orderId)
                .orElseThrow(()->new RuntimeException("No items found for this order. Please create a fresh order manually"));
        cartService.clearCart();
        for (OrderItem orderItem : orderItems) {
            for(int i=0; i<orderItem.getQuantity(); i++){
                cartService.addItemToCart(orderItem.getMenuItem().getItemId());
            }
        }
        return ResponseEntity.ok().build();
    }
    @Transactional
    public ResponseEntity<?> cancelOrder(Long orderId){
        User user=getloggedUser();
        OrderTicket orderTicket=orderTicketRepository.findById(orderId)
                .orElseThrow(()->new RuntimeException("Order doesn't exist anymore"));
        if(!orderTicket.getUsername().equals(user.getUsername())){
            throw new RuntimeException("You are not allowed to cancel this order");
        }
        if(orderTicket.getOrderStatus()==OrderStatus.PENDING){

            // Write payments logic here

            orderTicket.setOrderStatus(OrderStatus.CANCELLED);
            orderQueueService.removePendingOrder(orderTicket.getId());
            OrderTicketDto dto=modelMapper.map(orderTicketRepository.save(orderTicket),OrderTicketDto.class);
            eventPublisher.publishEvent(
                    new OrderPlaceEvent(dto)
            );
            return ResponseEntity.ok(dto);
        }
        ApiError apiError=new ApiError("Order can not be cancelled now",HttpStatus.NOT_ACCEPTABLE);
        return new ResponseEntity<>(apiError,apiError.getHttpStatus());
    }
}
