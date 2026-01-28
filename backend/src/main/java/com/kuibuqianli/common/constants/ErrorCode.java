package com.kuibuqianli.common.constants;

/**
 * 错误码定义
 */
public enum ErrorCode {
    SUCCESS(200, "操作成功"),
    SYSTEM_ERROR(500, "系统内部错误"),
    PARAMS_ERROR(400, "请求参数错误"),
    OPERATION_ERROR(400, "操作失败"),
    NOT_LOGIN_ERROR(401, "未登录"),
    NO_AUTH_ERROR(403, "无权限"),
    NOT_FOUND_ERROR(404, "不存在");

    private final int code;
    private final String message;

    ErrorCode(int code, String message) {
        this.code = code;
        this.message = message;
    }

    public int getCode() {
        return code;
    }

    public String getMessage() {
        return message;
    }
}
// 错误码定义