package com.apsit.canteen_management.service;

import com.apsit.canteen_management.dto.OrderTicketDto;
import com.apsit.canteen_management.entity.OrderTicket;
import com.apsit.canteen_management.enums.OrderStatus;
import com.apsit.canteen_management.event.OrderUpdateEvent;
import com.apsit.canteen_management.repository.OrderTicketRepository;
import lombok.RequiredArgsConstructor;
import org.modelmapper.ModelMapper;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AdminOrderService {
    private final OrderTicketRepository orderTicketRepository;
    private final ModelMapper modelMapper;
    private final OrderQueueService orderQueueService;
    private final SimpMessagingTemplate simpMessagingTemplate;
    private final ApplicationEventPublisher eventPublisher;

    public ResponseEntity<Page<OrderTicketDto>> getOrderByOrderStatus(OrderStatus orderStatus,int pageNo){
        Sort sort=orderStatus==OrderStatus.PENDING
                ? Sort.by(Sort.Direction.ASC,"createdAt")
                : Sort.by(Sort.Direction.DESC, "updatedAt");
        return ResponseEntity.ok(
                orderTicketRepository.findByOrderStatus(
                            orderStatus,
                            PageRequest.of(pageNo,20,sort)
                        )
                        .map(orderTicket -> modelMapper.map(orderTicket, OrderTicketDto.class))
                );
    }
    @Transactional
    public ResponseEntity<?> acceptPendingOrder(Long orderId){
        OrderTicket orderTicket=orderTicketRepository.findById(orderId)
                .orElseThrow(()->new RuntimeException("order does not exist to accept. Try with another one"));
        if(orderTicket.getOrderStatus()==OrderStatus.PENDING){
            orderTicket.setOrderStatus(OrderStatus.IN_PROGRESS);
            orderQueueService.removePendingOrder(orderId);
            orderQueueService.addInProgressOrder(orderTicket);
            orderTicket.setUpdatedAt(LocalDateTime.now());

            OrderTicket savedOrder=orderTicketRepository.save(orderTicket);
            OrderTicketDto dto=modelMapper.map(savedOrder, OrderTicketDto.class);
            // Notify the user
            eventPublisher.publishEvent(
                    new OrderUpdateEvent(orderTicket.getUsername(),dto)
            );
            return ResponseEntity.ok(dto);
        }
        return ResponseEntity.badRequest().build();
    }
    @Transactional
    public ResponseEntity<?> markOrderReady(Long orderId){
        OrderTicket orderTicket=orderTicketRepository.findById(orderId)
                .orElseThrow(()->new RuntimeException("Can't find this order to make it ready!"));
        if(orderTicket.getOrderStatus()!=OrderStatus.IN_PROGRESS){
            return ResponseEntity.badRequest().build();
        }
        orderTicket.setOrderStatus(OrderStatus.READY);
        orderQueueService.removeInProgressOrder(orderId);
        orderTicket.setOrderToken(UUID.randomUUID().toString());
        orderTicket.setUpdatedAt(LocalDateTime.now());

        OrderTicket savedOrder=orderTicketRepository.save(orderTicket);
        OrderTicketDto dto=modelMapper.map(savedOrder, OrderTicketDto.class);
        // Notify the user
        eventPublisher.publishEvent(
                new OrderUpdateEvent(orderTicket.getUsername(),dto)
        );
        return ResponseEntity.ok(dto);
    }
    @Transactional
    public ResponseEntity<?> verifyAndClaimOrder(String orderToken){
        OrderTicket orderTicket=orderTicketRepository.findByOrderToken(orderToken)
                .orElseThrow(()->new IllegalArgumentException("Invalid QR code"));
        if(orderTicket.getOrderStatus()==OrderStatus.DELIVERED){
            return ResponseEntity.badRequest().body("Order already is claimed");
        }
        if(orderTicket.getOrderStatus()!=OrderStatus.READY){
            return ResponseEntity.badRequest().body("Order is NOT ready yet.");
        }
        orderTicket.setOrderStatus(OrderStatus.DELIVERED);
        orderTicket.setUpdatedAt(LocalDateTime.now());
        orderTicket.setCompletedAt(LocalDateTime.now());

        OrderTicket savedOrder=orderTicketRepository.save(orderTicket);
        OrderTicketDto dto=modelMapper.map(savedOrder, OrderTicketDto.class);
        // Notify the user
        eventPublisher.publishEvent(
                new OrderUpdateEvent(orderTicket.getUsername(),dto)
        );
        return ResponseEntity.ok(dto.getOrderItems());
    }
    @Transactional
    public ResponseEntity<?> rejectOrder(Long orderId){
        OrderTicket orderTicket=orderTicketRepository.findById(orderId)
                .orElseThrow(()-> new RuntimeException("order does not exist to cancel"));
        // first check whether the order is in pending or in-progress status.
        OrderStatus status=orderTicket.getOrderStatus();
        if(status!=OrderStatus.PENDING && status!=OrderStatus.IN_PROGRESS){
            return ResponseEntity.badRequest().body("Only pending or in-progress orders can be cancelled");
        }

        if(status==OrderStatus.PENDING){
            orderQueueService.removePendingOrder(orderTicket.getId());
        }else{
            orderQueueService.removeInProgressOrder(orderTicket.getId());
        }
        orderTicket.setOrderStatus(OrderStatus.CANCELLED);
        orderTicket.setUpdatedAt(LocalDateTime.now());

        // Write payments logic here

        OrderTicket savedOrder=orderTicketRepository.save(orderTicket);
        OrderTicketDto dto=modelMapper.map(savedOrder, OrderTicketDto.class);
        // Notify the user
        eventPublisher.publishEvent(
                new OrderUpdateEvent(orderTicket.getUsername(),dto)
        );
        return ResponseEntity.ok(dto);
    }
    public long countByOrderStatus(OrderStatus orderStatus){
        return orderTicketRepository.countByOrderStatus(orderStatus);
    }
    public long countOrdersCompletedToday(){
        LocalDateTime now=LocalDateTime.now();
        return orderTicketRepository.countByOrderStatusAndCompletedAtBetween(
                OrderStatus.DELIVERED,now.toLocalDate().atStartOfDay(),now
        );
    }



}
