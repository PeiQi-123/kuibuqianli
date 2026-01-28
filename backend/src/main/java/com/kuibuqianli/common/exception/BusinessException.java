package com.kuibuqianli.common.exception;

import com.kuibuqianli.common.constants.ErrorCode;

/**
 * 业务异常类
 */
public class BusinessException extends RuntimeException {
    private final int code;
    private final String description;

    public BusinessException(String message) {
        super(message);
        this.code = ErrorCode.OPERATION_ERROR.getCode();
        this.description = message;
    }

    public BusinessException(ErrorCode errorCode) {
        super(errorCode.getMessage());
        this.code = errorCode.getCode();
        this.description = errorCode.getMessage();
    }

    public BusinessException(ErrorCode errorCode, String description) {
        super(description);
        this.code = errorCode.getCode();
        this.description = description;
    }

    public int getCode() {
        return code;
    }

    public String getDescription() {
        return description;
    }
}
// 业务异常类