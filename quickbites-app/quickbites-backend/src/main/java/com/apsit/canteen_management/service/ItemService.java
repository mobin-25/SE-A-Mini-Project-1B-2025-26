package com.apsit.canteen_management.service;

import com.apsit.canteen_management.dto.ItemDto;
import com.apsit.canteen_management.dto.SaveItemDto;
import com.apsit.canteen_management.entity.MenuItem;
import com.apsit.canteen_management.enums.ItemCategory;
import com.apsit.canteen_management.repository.ItemRepository;
import lombok.RequiredArgsConstructor;
import org.modelmapper.ModelMapper;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class ItemService {
    private final ItemRepository itemRepository;
    private final ModelMapper modelMapper;
    private final CloudinaryServiceImpl cloudinaryService;

    @Transactional
    public ResponseEntity<ItemDto> saveItem(SaveItemDto saveItemDto){
        MenuItem newMenuItem= MenuItem.builder()
                .itemName(saveItemDto.getItemName())
                .price(saveItemDto.getPrice())
                .category(ItemCategory.valueOf(saveItemDto.getCategory().toString().toUpperCase()))
                .readyIn(saveItemDto.getReadyIn())
                .isAvailable(true)
                .build();
        MultipartFile itemImage=saveItemDto.getItemImage();
        Map uploadInfo= cloudinaryService.upload(itemImage);
        newMenuItem.setImageUrl(uploadInfo.get("url").toString());
        return ResponseEntity.ok(modelMapper.map(itemRepository.save(newMenuItem),ItemDto.class));
    }
    public ResponseEntity<List<ItemDto>> saveListOfItem(List<MenuItem> menuItems) {
        List<MenuItem> menuItemList = menuItems.stream()
                .map(itemRepository::save)
                .toList();
        return ResponseEntity.ok(menuItemList.stream()
                        .map(menuItem -> modelMapper.map(menuItem, ItemDto.class))
                        .toList()
                    );
    }
    public ResponseEntity deleteItem(Long id){
        try{
            itemRepository.deleteById(id);
            return ResponseEntity.ok().build();
        }catch (Exception e){
            throw(new IllegalArgumentException("Id doesn't exist !!"));
        }
    }

    public ResponseEntity<ItemDto> getItemByItemName(String name){
        return itemRepository.findByItemNameIgnoreCase(name)
                .map(menuItem -> modelMapper.map(menuItem, ItemDto.class))
                .map(ResponseEntity:: ok)
                .orElseGet(()->ResponseEntity.notFound().build());
    }

    public ResponseEntity<Page<ItemDto>> getItemsByCategory(ItemCategory itemCategory, int pageNo){
        return ResponseEntity.ok(itemRepository
                .findAllByCategory(
                    itemCategory,
                    PageRequest.of(pageNo,10, Sort.by(Sort.Direction.ASC,"itemName"))
                )
                .map(menuItem -> modelMapper.map(menuItem, ItemDto.class))
        );
    }

    public ResponseEntity<ItemDto> toggleAvailability(Long id){
        return itemRepository.findById(id)
                .map(menuItem -> {
                    menuItem.setAvailable(!menuItem.isAvailable());
                    return ResponseEntity.ok(modelMapper.map(itemRepository.save(menuItem), ItemDto.class));
                })
                .orElseGet(()->ResponseEntity.notFound().build());
    }

    public ResponseEntity<List<ItemDto>> findByPriceBetween(int minPrice, int highPrice){
        return itemRepository.findByPriceBetween(minPrice, highPrice)
                .map(items-> items.stream()
                        .map(menuItem ->modelMapper.map(menuItem, ItemDto.class))
                        .toList())
                .map(ResponseEntity::ok)
                .orElseGet(()->ResponseEntity.notFound().build());
    }

    public ResponseEntity<Page<ItemDto>> getAllItem(int pageNo) {
        return ResponseEntity.ok(
                itemRepository.findAll(
                        PageRequest.of(pageNo,10,Sort.by(Sort.Direction.ASC,"itemName"))
                )
                        .map(menuItem -> modelMapper.map(menuItem,ItemDto.class))
        );
    }

    public ResponseEntity deleteByListOfItemId(List<Long> idList) {
        idList
                .forEach(itemRepository::deleteById);
        return ResponseEntity.ok().build();
    }

    public ResponseEntity<List<ItemDto>> getInstantReadyItems() {
        return itemRepository.findByReadyInEquals(0)
                .map(menuItems -> menuItems.stream()
                        .map(menuItem -> modelMapper.map(menuItem, ItemDto.class)).toList())
                .map(ResponseEntity::ok)
                .orElseGet(()->ResponseEntity.notFound().build());
    }
}
