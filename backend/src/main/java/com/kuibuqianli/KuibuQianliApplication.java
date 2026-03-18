package com.kuibuqianli;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

@SpringBootApplication
@MapperScan("com.kuibuqianli.dao.mapper")
@ComponentScan(basePackages = {"com.kuibuqianli"})  // 显式指定扫描包
public class KuibuQianliApplication {

    public static void main(String[] args) {
        SpringApplication.run(KuibuQianliApplication.class, args);
    }
}