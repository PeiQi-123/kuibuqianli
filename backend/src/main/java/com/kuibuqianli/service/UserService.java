package com.kuibuqianli.service;

import com.kuibuqianli.dao.entity.User;
import com.kuibuqianli.dto.LoginDTO;
import com.kuibuqianli.dto.RegisterDTO;
import com.kuibuqianli.dto.UserDTO;
import com.kuibuqianli.dto.LoginResponseDTO;
import com.kuibuqianli.dto.UserPreferenceDTO;
import com.kuibuqianli.dto.UserPreferencesUpdateDTO;

import java.util.List;

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

    /**
     * 更新用户信息
     */
    boolean updateUserInfo(Long userId, UserDTO userDTO);

    /**
     * 获取用户偏好
     */
    List<UserPreferenceDTO> getUserPreferences(Long userId);

    /**
     * 保存用户偏好
     */
    boolean saveUserPreferences(Long userId, UserPreferencesUpdateDTO preferencesDTO);

    /**
     * 更新用户头像
     */
    boolean updateAvatar(Long userId, String avatarUrl);
}
// 用户服务接口