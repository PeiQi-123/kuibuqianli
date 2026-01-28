package com.kuibuqianli;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@MapperScan("com.kuibuqianli.dao.mapper")
public class KuibuQianliApplication {
    public static void main(String[] args) {
        SpringApplication.run(KuibuQianliApplication.class, args);
    }
}