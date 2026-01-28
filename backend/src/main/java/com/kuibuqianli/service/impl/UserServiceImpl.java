package com.kuibuqianli.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.kuibuqianli.common.constants.ErrorCode;
import com.kuibuqianli.common.exception.BusinessException;
import com.kuibuqianli.dao.entity.User;
import com.kuibuqianli.dao.mapper.UserMapper;
import com.kuibuqianli.dto.LoginDTO;
import com.kuibuqianli.dto.RegisterDTO;
import com.kuibuqianli.dto.UserDTO;
import com.kuibuqianli.security.JwtTokenProvider;
import com.kuibuqianli.service.UserService;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import com.kuibuqianli.dto.LoginResponseDTO;


/**
 * 用户服务实现类
 */
@Service
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements UserService {

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    @Override
    public User register(RegisterDTO registerDTO) {
        // 检查用户名是否已存在
        if (checkUsernameExists(registerDTO.getUsername())) {
            throw new BusinessException("用户名已存在");
        }

        // 检查邮箱是否已存在
        if (checkEmailExists(registerDTO.getEmail())) {
            throw new BusinessException("邮箱已被注册");
        }

        // 创建新用户
        User user = new User();
        user.setUsername(registerDTO.getUsername());
        user.setPassword(passwordEncoder.encode(registerDTO.getPassword()));
        user.setEmail(registerDTO.getEmail());
        user.setPhone(registerDTO.getPhone());
        user.setCreatedAt(LocalDateTime.now());
        user.setUpdatedAt(LocalDateTime.now());
        user.setIsActive(true);

        // 保存用户
        userMapper.insert(user);

        return user;
    }

    @Override
    public String login(LoginDTO loginDTO) {
        // 查找用户
        User user = userMapper.findByUsername(loginDTO.getUsername());
        if (user == null) {
            throw new BusinessException("用户名或密码错误");
        }

        // 验证密码
        if (!passwordEncoder.matches(loginDTO.getPassword(), user.getPassword())) {
            throw new BusinessException("用户名或密码错误");
        }

        // 生成JWT Token
        return jwtTokenProvider.generateToken(user.getId(), user.getUsername());
    }

    @Override
    public UserDTO getUserInfo(Long userId) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException(ErrorCode.NOT_FOUND_ERROR);
        }

        UserDTO userDTO = new UserDTO();
        BeanUtils.copyProperties(user, userDTO);
        return userDTO;
    }

    @Override
    public boolean checkUsernameExists(String username) {
        return userMapper.findByUsername(username) != null;
    }

    @Override
    public boolean checkEmailExists(String email) {
        return userMapper.findByEmail(email) != null;
    }

    @Override
    public LoginResponseDTO loginWithUser(LoginDTO loginDTO) {
        // 查找用户
        User user = userMapper.findByUsername(loginDTO.getUsername());
        if (user == null || !passwordEncoder.matches(loginDTO.getPassword(), user.getPassword())) {
            throw new BusinessException("用户名或密码错误");
        }

        // 生成 token
        String token = jwtTokenProvider.generateToken(user.getId(), user.getUsername());

        // 构建响应
        UserDTO userDTO = new UserDTO();
        BeanUtils.copyProperties(user, userDTO);

        LoginResponseDTO response = new LoginResponseDTO();
        response.setToken(token);
        response.setUser(userDTO);

        return response;
    }

}
// 用户服务实现类