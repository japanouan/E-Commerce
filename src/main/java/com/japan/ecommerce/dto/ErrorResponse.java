package com.japan.ecommerce.dto;

import java.time.LocalDateTime;
import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ErrorResponse{
    private LocalDateTime timestamp;
    private int status;
    private String error;
    private String message;
    private String path;
    private List<ValidationFieldError> validationErrors;
}

// {
//   "timestamp": "2026-07-01T08:31:45",
//   "status": 400,
//   "error": "Bad Request",
//   "message": "Validation failed for one or more fields.",
//   "path": "/api/v1/users",
//   "validationErrors": [
//     {
//       "field": "email",
//       "rejectedValue": "invalid-email",
//       "message": "Must be a well-formed email address."
//     }
//   ]
// }