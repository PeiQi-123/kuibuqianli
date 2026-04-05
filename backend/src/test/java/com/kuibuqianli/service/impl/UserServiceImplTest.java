package com.kuibuqianli.service.impl;

import com.kuibuqianli.common.exception.BusinessException;
import com.kuibuqianli.dao.entity.User;
import com.kuibuqianli.dao.mapper.UserMapper;
import com.kuibuqianli.dao.mapper.UserPreferenceMapper;
import com.kuibuqianli.dto.RegisterDTO;
import com.kuibuqianli.dto.UserDTO;
import com.kuibuqianli.security.JwtTokenProvider;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserServiceImplTest {

    @Mock
    private UserMapper userMapper;

    @Mock
    private UserPreferenceMapper userPreferenceMapper;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtTokenProvider jwtTokenProvider;

    @InjectMocks
    private UserServiceImpl service;

    @Test
    void registerShouldEncodePasswordAndApplyReminderDefaults() {
        RegisterDTO dto = new RegisterDTO();
        dto.setUsername("alice");
        dto.setEmail("alice@example.com");
        dto.setPassword("secret");
        dto.setPhone("13800000000");

        when(userMapper.findByUsername("alice")).thenReturn(null);
        when(userMapper.findByEmail("alice@example.com")).thenReturn(null);
        when(passwordEncoder.encode("secret")).thenReturn("ENCODED");

        User result = service.register(dto);

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userMapper).insert(captor.capture());
        User saved = captor.getValue();

        assertEquals("alice", saved.getUsername());
        assertEquals("ENCODED", saved.getPassword());
        assertEquals("alice@example.com", saved.getEmail());
        assertEquals(true, saved.getRemindEnabled());
        assertEquals(30, saved.getRemindInterval());
        assertEquals(3, saved.getRemindMaxTimes());
        assertEquals("ENCODED", result.getPassword());
    }

    @Test
    void registerShouldRejectDuplicateUsername() {
        RegisterDTO dto = new RegisterDTO();
        dto.setUsername("alice");
        dto.setEmail("alice@example.com");
        dto.setPassword("secret");

        when(userMapper.findByUsername("alice")).thenReturn(new User());

        assertThrows(BusinessException.class, () -> service.register(dto));
    }

    @Test
    void getUserInfoShouldFillReminderDefaultsAndParseAvoidTimes() {
        User user = new User();
        user.setId(3L);
        user.setUsername("alice");
        user.setRemindEnabled(null);
        user.setRemindInterval(null);
        user.setRemindMaxTimes(null);
        user.setRemindAvoidTime("[{\"start\":\"12:00\",\"end\":\"13:00\"}]");

        when(userMapper.selectById(3L)).thenReturn(user);

        UserDTO result = service.getUserInfo(3L);

        assertEquals(true, result.getRemindEnabled());
        assertEquals(30, result.getRemindInterval());
        assertEquals(3, result.getRemindMaxTimes());
        assertNotNull(result.getRemindAvoidTime());
        assertEquals("12:00", result.getRemindAvoidTime().get(0).get("start"));
    }

    @Test
    void updateUserInfoShouldRecalculateBmiAndClearAvoidTimesWhenReminderDisabled() {
        User existing = new User();
        existing.setId(5L);
        existing.setUsername("alice");
        existing.setHeight(new BigDecimal("180"));
        existing.setWeight(new BigDecimal("80"));
        existing.setRemindAvoidTime("[{\"start\":\"12:00\",\"end\":\"13:00\"}]");

        UserDTO dto = new UserDTO();
        dto.setHeight(new BigDecimal("170"));
        dto.setWeight(new BigDecimal("65"));
        dto.setRemindEnabled(false);

        when(userMapper.selectById(5L)).thenReturn(existing);
        when(userMapper.updateById(any(User.class))).thenReturn(1);

        boolean updated = service.updateUserInfo(5L, dto);

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userMapper).updateById(captor.capture());
        User saved = captor.getValue();

        assertEquals(true, updated);
        assertEquals(new BigDecimal("22.49"), saved.getBmi());
        assertEquals("\u6b63\u5e38", saved.getBmiType());
        assertNull(saved.getRemindAvoidTime());
    }
}
