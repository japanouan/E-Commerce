package com.japan.ecommerce.exception;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import com.japan.ecommerce.dto.ErrorResponse;
import com.japan.ecommerce.dto.ValidationFieldError;

import jakarta.servlet.http.HttpServletRequest;

@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleResourceNotFoundException(
        ResourceNotFoundException ex,
        HttpServletRequest request
    ){
        ErrorResponse errorResponse = ErrorResponse.builder()
            .timestamp(LocalDateTime.now(ZoneId.of("Asia/Bangkok")))
            .status(HttpStatus.NOT_FOUND.value())
            .error(HttpStatus.NOT_FOUND.getReasonPhrase())
            .message(ex.getMessage())
            .path(request.getRequestURI())
            .build();

        return new ResponseEntity<>(
            errorResponse, 
            HttpStatus.NOT_FOUND
        );
    }

    @ExceptionHandler(ForbiddenException.class)
    public ResponseEntity<ErrorResponse> handleForbiddenException(
        ForbiddenException ex,
        HttpServletRequest request
    ){
        ErrorResponse errorResponse = ErrorResponse.builder()
            .timestamp(LocalDateTime.now(ZoneId.of("Asia/Bangkok")))
            .status(HttpStatus.FORBIDDEN.value())
            .error(HttpStatus.FORBIDDEN.getReasonPhrase())
            .message(ex.getMessage())
            .path(request.getRequestURI())
            .build();
        return new ResponseEntity<>(
            errorResponse,
            HttpStatus.FORBIDDEN
        );
    }

    @ExceptionHandler(InsufficientStockException.class)
    public ResponseEntity<ErrorResponse> handleInsufficientStockException(
        InsufficientStockException ex,
        HttpServletRequest request
    ){
        ErrorResponse errorResponse = ErrorResponse.builder()
            .timestamp(LocalDateTime.now(ZoneId.of("Asia/Bangkok")))
            .status(HttpStatus.CONFLICT.value())
            .error(HttpStatus.CONFLICT.getReasonPhrase())
            .message(ex.getMessage())
            .path(request.getRequestURI())
            .build();
        return new ResponseEntity<>(
            errorResponse,
            HttpStatus.CONFLICT
        );
    }

    @ExceptionHandler(BadRequestException.class)
    public ResponseEntity<ErrorResponse> handleBadRequestException(
        BadRequestException ex,
        HttpServletRequest request
    ){
        ErrorResponse errorResponse = ErrorResponse.builder()
            .timestamp(LocalDateTime.now(ZoneId.of("Asia/Bangkok")))
            .status(HttpStatus.BAD_REQUEST.value())
            .error(HttpStatus.BAD_REQUEST.getReasonPhrase())
            .message(ex.getMessage())
            .path(request.getRequestURI())
            .build();
        return new ResponseEntity<>(
            errorResponse,
            HttpStatus.BAD_REQUEST
        );
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleMethodArgumentNotValidException(
        MethodArgumentNotValidException ex,
        HttpServletRequest request
    ){
        List<ValidationFieldError> errors = ex.getBindingResult()
            .getFieldErrors()
            .stream()
            .map(fieldErrors -> new ValidationFieldError(
                fieldErrors.getField(),
                String.valueOf(fieldErrors.getRejectedValue()),
                fieldErrors.getDefaultMessage()
            ))
            .toList();
        ErrorResponse errorResponse = ErrorResponse.builder()
            .timestamp(LocalDateTime.now(ZoneId.of("Asia/Bangkok")))
            .status(HttpStatus.BAD_REQUEST.value())
            .error(HttpStatus.BAD_REQUEST.getReasonPhrase())
            .message("Validation failed For one or more fields")
            .path(request.getRequestURI())
            .validationErrors(errors)
            .build();
        return new ResponseEntity<>(
            errorResponse,
            HttpStatus.BAD_REQUEST
        );
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleException(
        Exception ex,
        HttpServletRequest request
    ){
        ErrorResponse errorResponse = ErrorResponse.builder()
            .timestamp(LocalDateTime.now(ZoneId.of("Asia/Bangkok")))
            .status(HttpStatus.INTERNAL_SERVER_ERROR.value())
            .error(HttpStatus.INTERNAL_SERVER_ERROR.getReasonPhrase())
            .message(ex.getMessage())
            .path(request.getRequestURI())
            .build();
        return new ResponseEntity<>(
            errorResponse,
            HttpStatus.INTERNAL_SERVER_ERROR
        );
    }
}
