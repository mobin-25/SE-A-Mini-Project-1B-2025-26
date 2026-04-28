package com.apsit.canteen_management.enums;

import lombok.Getter;

@Getter
public enum ItemCategory {
    VEG("Veg"),
    BEVERAGE("Beverage"),
    SNACK("Snack"),
    BREAKFAST("Breakfast");

    private final String displayName;

    ItemCategory(String displayName){
        this.displayName=displayName;
    }

}
