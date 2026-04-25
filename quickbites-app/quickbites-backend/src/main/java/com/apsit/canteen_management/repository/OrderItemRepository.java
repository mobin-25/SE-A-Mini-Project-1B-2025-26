package com.apsit.canteen_management.repository;

import com.apsit.canteen_management.entity.OrderItem;
import com.apsit.canteen_management.entity.OrderTicket;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface OrderItemRepository extends JpaRepository<OrderItem,Long> {
    Optional<List<OrderItem>> findAllByOrderTicket_Id(Long orderTicketId);
}
