package com.kuibuqianli.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.kuibuqianli.common.constants.ErrorCode;
import com.kuibuqianli.common.exception.BusinessException;
import com.kuibuqianli.dao.entity.User;
import com.kuibuqianli.dao.entity.UserPreference;
import com.kuibuqianli.dao.mapper.UserMapper;
import com.kuibuqianli.dao.mapper.UserPreferenceMapper;
import com.kuibuqianli.dto.LoginDTO;
import com.kuibuqianli.dto.RegisterDTO;
import com.kuibuqianli.dto.UserDTO;
import com.kuibuqianli.dto.UserPreferenceDTO;
import com.kuibuqianli.dto.UserPreferencesUpdateDTO;
import com.kuibuqianli.security.JwtTokenProvider;
import com.kuibuqianli.service.UserService;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import com.kuibuqianli.dto.LoginResponseDTO;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Map;


/**
 * 用户服务实现类
 */
@Service
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements UserService {

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private UserPreferenceMapper userPreferenceMapper;

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
        
        // 确保remindEnabled有默认值（如果数据库为null，默认为true）
        if (userDTO.getRemindEnabled() == null) {
            userDTO.setRemindEnabled(true);
        }
        
        // 处理JSON字段：remind_avoid_time
        if (user.getRemindAvoidTime() != null && !user.getRemindAvoidTime().isEmpty()) {
            try {
                ObjectMapper objectMapper = new ObjectMapper();
                List<Map<String, String>> avoidTimeList = objectMapper.readValue(
                    user.getRemindAvoidTime(), 
                    objectMapper.getTypeFactory().constructCollectionType(List.class, Map.class)
                );
                userDTO.setRemindAvoidTime(avoidTimeList);
            } catch (Exception e) {
                // 如果JSON解析失败，保持为null
                userDTO.setRemindAvoidTime(null);
            }
        }
        
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

        // 构建响应 - 使用getUserInfo方法确保返回完整信息
        UserDTO userDTO = getUserInfo(user.getId());

        LoginResponseDTO response = new LoginResponseDTO();
        response.setToken(token);
        response.setUser(userDTO);

        return response;
    }

    @Override
    public boolean updateUserInfo(Long userId, UserDTO userDTO) {
        try {
            User user = userMapper.selectById(userId);
            if (user == null) {
                throw new BusinessException("用户不存在");
            }

            // 更新基本信息
            if (userDTO.getUsername() != null) {
                // 检查用户名是否已被其他用户使用
                User existingUser = userMapper.findByUsername(userDTO.getUsername());
                if (existingUser != null && !existingUser.getId().equals(userId)) {
                    throw new BusinessException("用户名已被使用");
                }
                user.setUsername(userDTO.getUsername());
            }
            
            if (userDTO.getEmail() != null) {
                // 检查邮箱是否已被其他用户使用
                User existingUser = userMapper.findByEmail(userDTO.getEmail());
                if (existingUser != null && !existingUser.getId().equals(userId)) {
                    throw new BusinessException("邮箱已被使用");
                }
                user.setEmail(userDTO.getEmail());
            }
            
            if (userDTO.getPhone() != null) {
                user.setPhone(userDTO.getPhone());
            }
            
            if (userDTO.getPassword() != null && !userDTO.getPassword().isEmpty()) {
                user.setPassword(passwordEncoder.encode(userDTO.getPassword()));
            }
            
            // 更新健康信息
            if (userDTO.getHeight() != null) {
                user.setHeight(userDTO.getHeight());
            }
            
            if (userDTO.getWeight() != null) {
                user.setWeight(userDTO.getWeight());
            }
            
            if (userDTO.getAge() != null) {
                user.setAge(userDTO.getAge());
            }
            
            if (userDTO.getGender() != null) {
                user.setGender(userDTO.getGender());
            }

            updateHealthMetrics(user);
            
            // 更新提醒设置
            if (userDTO.getRemindEnabled() != null) {
                user.setRemindEnabled(userDTO.getRemindEnabled());
            }
            
            if (userDTO.getRemindInterval() != null) {
                user.setRemindInterval(userDTO.getRemindInterval());
            }
            
            // 处理免打扰时间段
            if (userDTO.getRemindAvoidTime() != null) {
                try {
                    ObjectMapper objectMapper = new ObjectMapper();
                    String avoidTimeJson = objectMapper.writeValueAsString(userDTO.getRemindAvoidTime());
                    user.setRemindAvoidTime(avoidTimeJson);
                } catch (Exception e) {
                    // 如果JSON序列化失败，保持原值
                    System.err.println("Failed to serialize remindAvoidTime: " + e.getMessage());
                }
            } else if (userDTO.getRemindEnabled() != null && !userDTO.getRemindEnabled()) {
                // 如果提醒关闭，清空免打扰时间段
                user.setRemindAvoidTime(null);
            }
            
            user.setUpdatedAt(LocalDateTime.now());
            
            // 更新数据库
            int result = userMapper.updateById(user);
            return result > 0;
            
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            System.err.println("Update user info error: " + e.getMessage());
            return false;
        }
    }

    @Override
    public List<UserPreferenceDTO> getUserPreferences(Long userId) {
        try {
            // 从数据库获取用户偏好
            List<UserPreference> preferences = userPreferenceMapper.findByUserId(userId);
            
            // 转换为DTO
            return preferences.stream().map(pref -> {
                UserPreferenceDTO dto = new UserPreferenceDTO();
                dto.setPreferenceKey(pref.getPreferenceKey());
                
                try {
                    // 解析JSON字符串为List
                    ObjectMapper objectMapper = new ObjectMapper();
                    List<String> values = objectMapper.readValue(
                        pref.getPreferenceValue(), 
                        objectMapper.getTypeFactory().constructCollectionType(List.class, String.class)
                    );
                    dto.setPreferenceValue(values);
                } catch (Exception e) {
                    // 如果解析失败，返回空列表
                    System.err.println("Failed to parse preference value JSON: " + e.getMessage());
                    dto.setPreferenceValue(new java.util.ArrayList<>());
                }
                
                return dto;
            }).collect(java.util.stream.Collectors.toList());
            
        } catch (Exception e) {
            System.err.println("Get user preferences error: " + e.getMessage());
            return new java.util.ArrayList<>();
        }
    }

    @Override
    public boolean saveUserPreferences(Long userId, UserPreferencesUpdateDTO preferencesDTO) {
        try {
            System.out.println("=== DEBUG: Saving user preferences for userId: " + userId);
            
            if (preferencesDTO == null || preferencesDTO.getPreferences() == null) {
                System.out.println("=== DEBUG: preferencesDTO or preferences is null");
                return false;
            }
            
            System.out.println("=== DEBUG: Number of preferences to save: " + preferencesDTO.getPreferences().size());
            
            // 先删除用户现有的偏好
            System.out.println("=== DEBUG: Deleting existing preferences for userId: " + userId);
            int deletedCount = userPreferenceMapper.deleteByUserId(userId);
            System.out.println("=== DEBUG: Deleted " + deletedCount + " existing preferences");
            
            // 转换DTO为实体并保存
            List<UserPreference> preferences = preferencesDTO.getPreferences().stream()
                .map(dto -> {
                    UserPreference pref = new UserPreference();
                    pref.setUserId(userId);
                    pref.setPreferenceKey(dto.getPreferenceKey());
                    
                    try {
                        // 将List转换为JSON字符串
                        ObjectMapper objectMapper = new ObjectMapper();
                        String jsonValue = objectMapper.writeValueAsString(dto.getPreferenceValue());
                        pref.setPreferenceValue(jsonValue);
                        System.out.println("=== DEBUG: Converted preference - key: " + dto.getPreferenceKey() + 
                                         ", value: " + jsonValue);
                    } catch (Exception e) {
                        System.err.println("Failed to serialize preference value: " + e.getMessage());
                        pref.setPreferenceValue("[]"); // 默认空数组
                    }
                    
                    return pref;
                })
                .collect(java.util.stream.Collectors.toList());
            
            // 批量插入
            if (!preferences.isEmpty()) {
                System.out.println("=== DEBUG: Attempting to batch insert " + preferences.size() + " preferences");
                int result = userPreferenceMapper.batchInsertOrUpdate(preferences);
                System.out.println("=== DEBUG: Batch insert result: " + result + " rows affected");
                return result > 0;
            }
            
            System.out.println("=== DEBUG: No preferences to save");
            return true; // 如果没有偏好要保存，也返回成功
            
        } catch (Exception e) {
            System.err.println("Save user preferences error: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    private void updateHealthMetrics(User user) {
        if (user.getHeight() == null || user.getWeight() == null || BigDecimal.ZERO.compareTo(user.getHeight()) == 0) {
            return;
        }

        BigDecimal heightMeter = user.getHeight().divide(BigDecimal.valueOf(100), 4, RoundingMode.HALF_UP);
        BigDecimal bmi = user.getWeight().divide(heightMeter.multiply(heightMeter), 2, RoundingMode.HALF_UP);
        user.setBmi(bmi);

        double bmiValue = bmi.doubleValue();
        if (bmiValue < 18.5) {
            user.setBmiType("偏瘦");
        } else if (bmiValue < 24.0) {
            user.setBmiType("正常");
        } else if (bmiValue < 28.0) {
            user.setBmiType("偏胖");
        } else {
            user.setBmiType("肥胖");
        }
    }

    @Override
    public boolean updateAvatar(Long userId, String avatarUrl) {
        try {
            User user = userMapper.selectById(userId);
            if (user == null) {
                throw new BusinessException("用户不存在");
            }
            user.setAvatarUrl(avatarUrl);
            user.setUpdatedAt(LocalDateTime.now());
            int result = userMapper.updateById(user);
            return result > 0;
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            System.err.println("Update avatar error: " + e.getMessage());
            return false;
        }
    }

}
// 用户服务实现类
