package com.apsit.canteen_management.service;

import com.apsit.canteen_management.entity.Admin;
import com.apsit.canteen_management.entity.OrderTicket;
import com.apsit.canteen_management.enums.OrderStatus;
import com.apsit.canteen_management.record.OrderQueueItem;
import com.apsit.canteen_management.repository.AdminRepository;
import com.apsit.canteen_management.repository.OrderTicketRepository;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Queue;
import java.util.concurrent.ConcurrentLinkedQueue;

@Service
@RequiredArgsConstructor
@Slf4j
public class OrderQueueService {
    private final OrderTicketRepository orderTicketRepository;
    private final AdminRepository adminRepository;
    private final Queue<OrderQueueItem> pendingQueue = new ConcurrentLinkedQueue<>();
    private final Queue<OrderQueueItem> inProgressQueue= new ConcurrentLinkedQueue<>();

    @PostConstruct
    public void initializeQueue(){
        log.info("Initializing order queue");
        List<OrderTicket> pendingOrderList=orderTicketRepository
                .findAllByOrderStatusOrderByCreatedAtAsc(OrderStatus.PENDING);

        pendingOrderList.forEach(pendingOrder->pendingQueue.offer(
                new OrderQueueItem(pendingOrder.getId(),pendingOrder.getEstPrepTime())
        ));

        List<OrderTicket> inProgressOrderList=orderTicketRepository
                .findAllByOrderStatusOrderByCreatedAtAsc(OrderStatus.IN_PROGRESS);
        inProgressOrderList.forEach(inProgressOrder-> inProgressQueue.offer(
                new OrderQueueItem(inProgressOrder.getId(),inProgressOrder.getEstPrepTime())
        ));
        log.info("Queues loaded. Pending: {}, In-Progress: {}", pendingQueue.size(), inProgressQueue.size());
        log.info("total wait time: {}",estWaitTime());
    }

    // pending methods
    public void addPendingOrder(OrderTicket orderTicket){
        pendingQueue.offer(new OrderQueueItem(orderTicket.getId(),orderTicket.getEstPrepTime()));
    }
    public OrderQueueItem getNextPendingOrder(){
        return pendingQueue.poll(); // Retrieves and removes the head of the queue
    }
    public void removePendingOrder(Long orderId){
        pendingQueue.removeIf(pendingOrder->pendingOrder.orderId().equals(orderId));
    }
    public int getPendingQueueSize(){
        return pendingQueue.size();
    }

    // in-progress methods
    public void addInProgressOrder(OrderTicket orderTicket){
        inProgressQueue.offer(new OrderQueueItem(orderTicket.getId(),orderTicket.getEstPrepTime()));
    }
    public OrderQueueItem getNextInProgressOrder(){
        return inProgressQueue.poll();
    }
    public void removeInProgressOrder(Long orderId){
        inProgressQueue.removeIf(inProgressOrder->inProgressOrder.orderId().equals(orderId));
    }
    public int getInProgressQueueSize(){
        return inProgressQueue.size();
    }

    // may we'll consume it later.
    public int totalOrdersInQueue(){
        return getInProgressQueueSize()+getPendingQueueSize();
    }

    public int estWaitTime(){
        int pendingOrdersWaitTime=pendingQueue.stream()
                .mapToInt(OrderQueueItem::estPrepTime)
                .sum();
        int inProgressOrdersWaitTime=inProgressQueue.stream()
                .mapToInt(OrderQueueItem::estPrepTime)
                .sum();
        return calculateParallelTime(pendingOrdersWaitTime+inProgressOrdersWaitTime);
    }

    public int waitTimeForSpecificOrder(Long orderId){
        int totalWaitTime=0;
        for(OrderQueueItem item: inProgressQueue){
            if(item.orderId().equals(orderId)){
                totalWaitTime+=item.estPrepTime();
                return calculateParallelTime(totalWaitTime);
            }
            totalWaitTime+=item.estPrepTime();
        }
        for(OrderQueueItem item: pendingQueue){
            if(item.orderId().equals(orderId)){
                totalWaitTime+=item.estPrepTime();
                return calculateParallelTime(totalWaitTime);
            }
            totalWaitTime+=item.estPrepTime();
        }
        return -1; // if zero means order is not in the queue;
    }

    public int getStaffCount(){
        Admin admin=adminRepository.findById(2L).orElseThrow(()->new RuntimeException("couldn't found admin"));
        // Note: for now admin ID is hardcoded
        return admin.getStaffCount();
    }

    public int calculateParallelTime(int linearTime){
        int staffCount=getStaffCount();
        staffCount=staffCount==0?1:staffCount;
        return (int) Math.ceil((double)linearTime/staffCount);
    }

}
