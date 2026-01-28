package com.kuibuqianli.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * SpringDoc OpenAPI 文档配置
 */
@Configuration
public class SwaggerConfig {

    @Value("${swagger.title:跬步千里 API文档}")
    private String title;

    @Value("${swagger.description:微运动健康管理系统后端API}")
    private String description;

    @Value("${swagger.version:1.0.0}")
    private String version;

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title(title)
                        .description(description)
                        .version(version));
    }
}
