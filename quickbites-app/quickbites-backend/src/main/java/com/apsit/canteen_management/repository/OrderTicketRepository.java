package com.apsit.canteen_management.repository;

import com.apsit.canteen_management.entity.OrderTicket;
import com.apsit.canteen_management.enums.OrderStatus;
import org.hibernate.query.Order;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface OrderTicketRepository extends JpaRepository<OrderTicket, Long> {
    Page<OrderTicket> findAllByUsername(String username, Pageable pageable);
    Optional<OrderTicket> findByOrderToken(String orderToken);
    Page<OrderTicket> findByOrderStatus(OrderStatus orderStatus,Pageable pageable);
    Integer countByOrderStatus(OrderStatus orderStatus);
    Integer countByOrderStatusAndCompletedAtBetween(
            OrderStatus orderStatus,
            LocalDateTime start,
            LocalDateTime end
    );
    List<OrderTicket> findAllByOrderStatusOrderByCreatedAtAsc(OrderStatus orderStatus);

}
