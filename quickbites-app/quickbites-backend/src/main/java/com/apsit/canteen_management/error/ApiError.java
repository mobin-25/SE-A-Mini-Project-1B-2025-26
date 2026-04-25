package com.apsit.canteen_management.error;

import lombok.Data;
import org.springframework.http.HttpStatus;

import java.time.LocalDateTime;

@Data
public class ApiError {
    private LocalDateTime timeStamp;
    private String message;
    private HttpStatus httpStatus;

    public ApiError(){
        this.timeStamp=LocalDateTime.now();
    }
    public ApiError(String message, HttpStatus httpStatus){
        this();
        this.httpStatus=httpStatus;
        this.message=message;
    }
}
