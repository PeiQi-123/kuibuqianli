package com.kuibuqianli.common;

import com.kuibuqianli.common.constants.ResponseConstants;
import lombok.Data;

/**
 * 统一返回结果类
 */
@Data
public class Result<T> {
    private int code;
    private String message;
    private T data;

    private Result(int code, String message, T data) {
        this.code = code;
        this.message = message;
        this.data = data;
    }

    /**
     * 成功返回
     */
    public static <T> Result<T> success(T data) {
        return new Result<>(ResponseConstants.SUCCESS_CODE, ResponseConstants.SUCCESS_MESSAGE, data);
    }

    public static <T> Result<T> success(String message, T data) {
        return new Result<>(ResponseConstants.SUCCESS_CODE, message, data);
    }

    /**
     * 失败返回
     */
    public static <T> Result<T> error(int code, String message) {
        return new Result<>(code, message, null);
    }

    public static <T> Result<T> error(String message) {
        return new Result<>(ResponseConstants.ERROR_CODE, message, null);
    }

    /**
     * 参数错误
     */
    public static <T> Result<T> paramError(String message) {
        return new Result<>(ResponseConstants.PARAM_ERROR_CODE, message, null);
    }
}
// 统一返回结果类