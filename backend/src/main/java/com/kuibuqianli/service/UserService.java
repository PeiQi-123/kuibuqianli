package com.kuibuqianli.service;

import com.kuibuqianli.dao.entity.User;
import com.kuibuqianli.dto.LoginDTO;
import com.kuibuqianli.dto.RegisterDTO;
import com.kuibuqianli.dto.UserDTO;
import com.kuibuqianli.dto.LoginResponseDTO;
/**
 * 用户服务接口
 */
public interface UserService {
    /**
     * 用户注册
     */
    User register(RegisterDTO registerDTO);

    /**
     * 用户登录
     */
    String login(LoginDTO loginDTO);
    LoginResponseDTO loginWithUser(LoginDTO loginDTO);
    /**
     * 获取用户信息
     */
    UserDTO getUserInfo(Long userId);

    /**
     * 检查用户名是否存在
     */
    boolean checkUsernameExists(String username);

    /**
     * 检查邮箱是否存在
     */
    boolean checkEmailExists(String email);
}
// 用户服务接口