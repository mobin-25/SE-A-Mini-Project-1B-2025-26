package com.apsit.canteen_management.repository;

import com.apsit.canteen_management.entity.MenuItem;
import com.apsit.canteen_management.enums.ItemCategory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ItemRepository extends JpaRepository<MenuItem,Long> {
    Optional<MenuItem> findByItemNameIgnoreCase(String name);
    @Override
    Page<MenuItem> findAll(Pageable pageable);

    Page<MenuItem> findAllByCategory(ItemCategory category, Pageable pageable);

    Optional<List<MenuItem>> findByPriceBetween(int minPrice, int highPrice);

    Optional<List<MenuItem>> findByReadyInEquals(int readyIn);
}
