package com.apsit.canteen_management.service;

import com.apsit.canteen_management.dto.CartDto;
import com.apsit.canteen_management.entity.Cart;
import com.apsit.canteen_management.entity.CartItem;
import com.apsit.canteen_management.entity.MenuItem;
import com.apsit.canteen_management.entity.User;
import com.apsit.canteen_management.repository.CartRepository;
import com.apsit.canteen_management.repository.ItemRepository;
import lombok.RequiredArgsConstructor;
import org.modelmapper.ModelMapper;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Iterator;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class CartService {
    private final CartRepository cartRepository;
    private final ModelMapper modelMapper;
    private final ItemRepository itemRepository;
    private final OrderQueueService orderQueueService;

    private void updateCart(Cart cart){
        double newTotal=cart.getCartItems().stream()
                .mapToDouble(CartItem::getCartItemPrice)
                .sum();
        int cartPrepTime=cart.getCartItems().stream()
                .mapToInt(item->item.getMenuItem().getReadyIn()*item.getQuantity())
                .sum();
        cart.setTotalCartPrice(newTotal);
        cart.setEstPrepTime(updateCartPrepTime(cartPrepTime));
    }

    private int updateCartPrepTime(int cartPrepTime){
        return orderQueueService.estWaitTime()+orderQueueService.calculateParallelTime(cartPrepTime) ;
    }

    private User getUser(){
        return (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
    public CartDto getCartById() {
        User user = getUser();
        return cartRepository.findById(user.getUserId())
                .map(cart -> modelMapper.map(cart, CartDto.class))
                .orElseThrow(()->new RuntimeException("your cart not found!\nplease contact admin."));
    }
    @Transactional
    public CartDto addItemToCart(Long itemId){
        User user=getUser();
        Cart prevCart=cartRepository.findById(user.getUserId()).orElseThrow();
        MenuItem menuItem= itemRepository.findById(itemId).orElseThrow();
        Optional<CartItem> existingItemOpt=prevCart.getCartItems().stream()
                .filter(cartItem -> cartItem.getMenuItem().getItemId().equals(itemId))
                .findFirst();
        if(existingItemOpt.isPresent()){
            CartItem existingItem=existingItemOpt.get();
            existingItem.setCartItemPrice(existingItem.getCartItemPrice()+ menuItem.getPrice());
            existingItem.setQuantity(existingItem.getQuantity()+1);
        }else {
            CartItem cartItem = CartItem.builder()
                    .cartItemPrice(menuItem.getPrice())
                    .cart(prevCart)
                    .quantity(1)
                    .cartItemImageUrl(menuItem.getImageUrl())
                    .menuItem(menuItem)
                    .build();
            prevCart.addItemToCart(cartItem);
        }
        updateCart(prevCart);
        return modelMapper.map(cartRepository.save(prevCart), CartDto.class);
    }
    @Transactional
    public CartDto adjustQuantity(Long cartItemId, int change){
        User user=getUser();
        Cart prevCart=cartRepository.findById(user.getUserId()).orElseThrow(()->new RuntimeException("Your has been deleted! ask admin."));
        CartItem itemToChange=prevCart.getCartItems().stream()
                .filter(cartItem -> cartItem.getCartItemId().equals(cartItemId))
                .findFirst()
                .orElseThrow(()->new RuntimeException("Item not found in your cart"));
        int newQty=itemToChange.getQuantity()+change;
        if(newQty<=0){
            prevCart.getCartItems().remove(itemToChange);
        }else{
            itemToChange.setQuantity(newQty);
            itemToChange.setCartItemPrice(itemToChange.getMenuItem().getPrice()*newQty);
        }
        updateCart(prevCart);
        return modelMapper.map(cartRepository.save(prevCart), CartDto.class);
    }

    @Transactional
    public CartDto removeItemCompletelyFromCart(Long cartItemId) {
        User user = getUser();
        Cart prevCart = cartRepository.findById(user.getUserId())
                .orElseThrow(() -> new RuntimeException("Cart not found! Please ask admin."));

        CartItem itemToRemove = prevCart.getCartItems().stream()
                .filter(item -> item.getCartItemId().equals(cartItemId))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("Item not found in your cart."));

        prevCart.getCartItems().remove(itemToRemove);
        updateCart(prevCart);
        return modelMapper.map(cartRepository.save(prevCart), CartDto.class);
    }
    @Transactional
    public void clearCart(){
        User user=getUser();
        Cart cart=cartRepository.findById(user.getUserId()).orElseThrow();
        cart.getCartItems().clear();
        cart.setTotalCartPrice(0.0);
        cart.setEstPrepTime(0);
        cartRepository.save(cart);
    }
}
