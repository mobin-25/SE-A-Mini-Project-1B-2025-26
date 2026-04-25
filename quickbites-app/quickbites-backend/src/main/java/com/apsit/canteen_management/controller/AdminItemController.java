package com.apsit.canteen_management.controller;

import com.apsit.canteen_management.dto.ItemDto;
import com.apsit.canteen_management.dto.SaveItemDto;
import com.apsit.canteen_management.entity.MenuItem;
import com.apsit.canteen_management.service.ItemService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@PreAuthorize("hasRole('ADMIN')")
@RequestMapping("/admin/item")
@RequiredArgsConstructor
public class AdminItemController {
    private final ItemService itemService;
    @DeleteMapping("/{id}/delete")
    public ResponseEntity deleteItemById(@PathVariable Long id){
        return itemService.deleteItem(id);
    }

    @PostMapping(value = "/save", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    // Instead of using @ModelAttribute we can manually use @RequestParam for each parameter in the request
    public ResponseEntity<ItemDto> saveItem(@ModelAttribute SaveItemDto saveItemDto) {
        return itemService.saveItem(saveItemDto);
    }

    @PostMapping("/save/all")
    public ResponseEntity<List<ItemDto>> saveListOfItem(@RequestBody List<MenuItem> menuItems){
        return itemService.saveListOfItem(menuItems);
    }

    @PatchMapping("/{id}/toggleAvailability")
    public ResponseEntity<ItemDto> toggleAvailability(@PathVariable Long id){
        return itemService.toggleAvailability(id);
    }

    // temporary method for quick testings
    @PostMapping("/delete-all")
    public ResponseEntity deleteByListOfItemId(@RequestBody List<Long> idList){
        return itemService.deleteByListOfItemId(idList);
    }
}
