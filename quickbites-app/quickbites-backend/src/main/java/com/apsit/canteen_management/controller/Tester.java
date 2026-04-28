package com.apsit.canteen_management.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/public/test")
public class Tester {
    @GetMapping
    public String test(){
        return "Ok";
    }
}
