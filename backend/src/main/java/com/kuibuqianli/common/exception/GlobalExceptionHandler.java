package com.kuibuqianli.common.exception;

import com.kuibuqianli.common.Result;
import com.kuibuqianli.common.constants.ErrorCode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * 全局异常处理器
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public Result<?> businessExceptionHandler(BusinessException e) {
        log.error("BusinessException: {}", e.getMessage(), e);
        return Result.error(e.getCode(), e.getDescription());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public Result<?> validationExceptionHandler(MethodArgumentNotValidException e) {
        log.error("MethodArgumentNotValidException: {}", e.getMessage(), e);
        BindingResult bindingResult = e.getBindingResult();
        String message = bindingResult.getFieldErrors().stream()
                .findFirst()
                .map(fieldError -> fieldError.getDefaultMessage())
                .orElse(ErrorCode.PARAMS_ERROR.getMessage());
        return Result.paramError(message);
    }

    @ExceptionHandler(Exception.class)
    public Result<?> defaultExceptionHandler(Exception e) {
        log.error("Default exception: {}", e.getMessage(), e);
        return Result.error(ErrorCode.SYSTEM_ERROR.getCode(), ErrorCode.SYSTEM_ERROR.getMessage());
    }
}
// 全局异常处理器