package com.japan.ecommerce.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ValidationFieldError {
    private String field;
    private String rejectedValue;
    private String message;
}

// "validationErrors": [
//     {
//       "field": "email",
//       "rejectedValue": "invalid-email",
//       "message": "Must be a well-formed email address."
//     }
//   ]