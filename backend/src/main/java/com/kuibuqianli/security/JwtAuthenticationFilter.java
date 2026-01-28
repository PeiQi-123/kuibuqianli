package com.kuibuqianli.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * JWT认证过滤器
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;

    @Autowired
    @Lazy  // 添加@Lazy注解延迟加载
    private UserDetailsService userDetailsService;

    @Autowired
    public JwtAuthenticationFilter(JwtTokenProvider jwtTokenProvider) {
        this.jwtTokenProvider = jwtTokenProvider;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        String path = request.getServletPath();
        System.out.println("=== DEBUG JWT Filter: Path = " + path);

        // 跳过登录和注册接口
        if (path.equals("/api/user/login") || path.equals("/api/user/register")) {
            System.out.println("=== DEBUG: Skipping JWT filter for auth endpoints");
            filterChain.doFilter(request, response);
            return;
        }

        String token = getTokenFromRequest(request);
        System.out.println("=== DEBUG JWT Filter: Token found = " + (token != null));

        if (token != null && jwtTokenProvider.validateToken(token)) {
            try {
                Long userId = jwtTokenProvider.getUserIdFromJWT(token);
                System.out.println("=== DEBUG JWT Filter: UserId = " + userId);

                // 临时方案：跳过认证，直接继续
                System.out.println("=== DEBUG: Token valid, continuing without authentication");

            } catch (Exception e) {
                System.out.println("=== ERROR JWT Filter: " + e.getMessage());
            }
        } else {
            System.out.println("=== DEBUG JWT Filter: No valid token, continuing");
        }

        filterChain.doFilter(request, response);
    }

    private String getTokenFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}