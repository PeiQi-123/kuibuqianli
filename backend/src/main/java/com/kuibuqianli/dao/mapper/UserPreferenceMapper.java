package com.kuibuqianli.dao.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kuibuqianli.dao.entity.UserPreference;
import org.apache.ibatis.annotations.*;

import java.util.List;

/**
 * User Preference Data Access Interface
 */
@Mapper
public interface UserPreferenceMapper extends BaseMapper<UserPreference> {

    /**
     * 根据用户ID获取所有偏好
     */
    @Select("SELECT * FROM user_preference WHERE user_id = #{userId}")
    List<UserPreference> findByUserId(@Param("userId") Long userId);

    /**
     * 根据用户ID和偏好键获取偏好
     */
    @Select("SELECT * FROM user_preference WHERE user_id = #{userId} AND preference_key = #{preferenceKey}")
    UserPreference findByUserIdAndKey(@Param("userId") Long userId, 
                                      @Param("preferenceKey") String preferenceKey);

    /**
     * 删除用户的所有偏好
     */
    @Delete("DELETE FROM user_preference WHERE user_id = #{userId}")
    int deleteByUserId(@Param("userId") Long userId);

    /**
     * 删除用户的特定偏好
     */
    @Delete("DELETE FROM user_preference WHERE user_id = #{userId} AND preference_key = #{preferenceKey}")
    int deleteByUserIdAndKey(@Param("userId") Long userId, 
                             @Param("preferenceKey") String preferenceKey);

    /**
     * 批量插入或更新用户偏好
     */
    @Insert("<script>" +
            "INSERT INTO user_preference (user_id, preference_key, preference_value) VALUES " +
            "<foreach collection='preferences' item='pref' separator=','>" +
            "(#{pref.userId}, #{pref.preferenceKey}, #{pref.preferenceValue})" +
            "</foreach>" +
            " ON DUPLICATE KEY UPDATE preference_value = VALUES(preference_value)" +
            "</script>")
    int batchInsertOrUpdate(@Param("preferences") List<UserPreference> preferences);
}