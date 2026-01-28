package com.kuibuqianli.dao.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kuibuqianli.dao.entity.User;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 用户数据访问接口（MyBatis）
 */
@Mapper  // 必须添加这个注解
public interface UserMapper extends BaseMapper<User> {

    /**
     * 根据用户名查找用户
     */
    @Select("SELECT * FROM user WHERE username = #{username} AND deleted = 0")
    User findByUsername(@Param("username") String username);

    /**
     * 根据邮箱查找用户
     */
    @Select("SELECT * FROM user WHERE email = #{email} AND deleted = 0")
    User findByEmail(@Param("email") String email);

    /**
     * 检查用户名是否存在
     */
    @Select("SELECT COUNT(*) FROM user WHERE username = #{username} AND deleted = 0")
    Long countByUsername(@Param("username") String username);

    /**
     * 检查邮箱是否存在
     */
    @Select("SELECT COUNT(*) FROM user WHERE email = #{email} AND deleted = 0")
    Long countByEmail(@Param("email") String email);
}