package com.apsit.canteen_management.error;

import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.MalformedJwtException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authorization.AuthorizationDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(JwtException.class)
    public ResponseEntity<ApiError> jwtExceptionHandler(JwtException ex){
        ApiError apiError=new ApiError("invalid Jwt as: "+ex.getMessage(), HttpStatus.UNAUTHORIZED);
        return new ResponseEntity<>(apiError, apiError.getHttpStatus());
    }

    @ExceptionHandler(UsernameNotFoundException.class)
    public ResponseEntity<ApiError> usernameNotFoundExceptionHandler(UsernameNotFoundException ex){
        ApiError apiError=new ApiError("user not found with username: "+ ex.getMessage(), HttpStatus.NOT_FOUND);
        return new ResponseEntity<>(apiError, apiError.getHttpStatus());
    }
    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ApiError> authenticationExceptionHandler(AuthenticationException ex){
        ApiError apiError = new ApiError("Authentication failed as: "+ex.getMessage(), HttpStatus.UNAUTHORIZED);
        return  new ResponseEntity<>(apiError, apiError.getHttpStatus());
    }

    @ExceptionHandler(InvalidRefreshTokenException.class)
    public ResponseEntity<ApiError> invalidRefreshTokenHandler(InvalidRefreshTokenException ex){
        ApiError apiError = new ApiError(ex.getMessage(), HttpStatus.UNAUTHORIZED);
        return new ResponseEntity<>(apiError, apiError.getHttpStatus());
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> generalExceptionHandler(Exception ex){
        ApiError apiError=new ApiError("Unexpected error occured: "+ex.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        return new ResponseEntity<>(apiError, apiError.getHttpStatus());
    }
    @ExceptionHandler(ExpiredJwtException.class)
    public ResponseEntity<ApiError> expiredJwtExceptionHandler(ExpiredJwtException ex){
        ApiError apiError=new ApiError("Jwt Expired !", HttpStatus.UNAUTHORIZED);
        return new ResponseEntity<>(apiError, apiError.getHttpStatus());
    }
    @ExceptionHandler(MalformedJwtException.class)
    public ResponseEntity<ApiError> malformedJwtExceptionHandler(MalformedJwtException ex){
        ApiError apiError=new ApiError("Invalid Jwt: "+ex.getMessage(), HttpStatus.UNAUTHORIZED);
        return new ResponseEntity<>(apiError, apiError.getHttpStatus());
    }
    @ExceptionHandler(AuthorizationDeniedException.class)
    public ResponseEntity<ApiError> AuthorizationDeniedExceptionHandler(AuthorizationDeniedException ex){
        ApiError apiError=new ApiError("You do not have access to do this!", HttpStatus.FORBIDDEN);
        return new ResponseEntity<>(apiError, apiError.getHttpStatus());
    }
}
