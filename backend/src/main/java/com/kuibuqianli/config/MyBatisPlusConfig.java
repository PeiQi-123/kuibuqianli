package com.kuibuqianli.config;

import com.baomidou.mybatisplus.annotation.DbType;
import com.baomidou.mybatisplus.core.config.GlobalConfig;
import com.baomidou.mybatisplus.extension.plugins.MybatisPlusInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.BlockAttackInnerInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.OptimisticLockerInnerInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.PaginationInnerInterceptor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.transaction.annotation.EnableTransactionManagement;

/**
 * MyBatis Plus 配置类
 */
@Configuration
@EnableTransactionManagement  // 启用事务管理
public class MyBatisPlusConfig {

    /**
     * MyBatis Plus 插件配置
     */
    @Bean
    public MybatisPlusInterceptor mybatisPlusInterceptor() {
        MybatisPlusInterceptor interceptor = new MybatisPlusInterceptor();

        // 1. 分页插件
        PaginationInnerInterceptor paginationInnerInterceptor = new PaginationInnerInterceptor(DbType.MYSQL);
        paginationInnerInterceptor.setMaxLimit(1000L); // 设置单页最大记录数
        paginationInnerInterceptor.setOverflow(true);  // 超过最大页数时返回第一页
        interceptor.addInnerInterceptor(paginationInnerInterceptor);

        // 2. 乐观锁插件（如果实体类中有 @Version 注解）
        interceptor.addInnerInterceptor(new OptimisticLockerInnerInterceptor());

        // 3. 防止全表更新与删除插件
        interceptor.addInnerInterceptor(new BlockAttackInnerInterceptor());

        return interceptor;
    }

    /**
     * 全局配置
     */
    @Bean
    public GlobalConfig globalConfig() {
        GlobalConfig globalConfig = new GlobalConfig();
        GlobalConfig.DbConfig dbConfig = new GlobalConfig.DbConfig();

        // 全局逻辑删除配置
        dbConfig.setLogicDeleteField("deleted"); // 逻辑删除字段名
        dbConfig.setLogicDeleteValue("1");       // 逻辑已删除值
        dbConfig.setLogicNotDeleteValue("0");    // 逻辑未删除值

        // ID 生成策略
        dbConfig.setIdType(com.baomidou.mybatisplus.annotation.IdType.AUTO);

        globalConfig.setDbConfig(dbConfig);

        // 设置 SQL 注入器（如果需要自定义批量插入等）
        // globalConfig.setSqlInjector(new DefaultSqlInjector());

        return globalConfig;
    }
}