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
import java.util.Arrays;
import java.util.List;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;

    @Autowired
    @Lazy
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
        String fullPath = request.getRequestURI();
        System.out.println("=== DEBUG JWT Filter: ServletPath = " + path + ", FullPath = " + fullPath);

        // 特殊处理 /file/avatar/* 和 /file/avatar 路径 - 必须放在最前面
        // 同时处理带context path和不带的情况
        if (path.startsWith("/file/avatar") || fullPath.contains("/file/avatar")) {
            System.out.println("=== DEBUG: Skipping JWT filter for avatar path: " + path);
            filterChain.doFilter(request, response);
            return;
        }

        // 定义不需要认证的路径列表
        List<String> permitAllPaths = Arrays.asList(
                "/user/login",
                "/user/register",
                "/micro-motion/health",
                "/micro-motion/generate-prompt",
                "/micro-motion/test",
                "/micro-motion/test-prompt",
                "/video/list",
                "/video/search",
                "/video/play",
                "/video/stream",
                "/video/files",
                "/video/find-or-generate",
                "/video/find-or-generate-steps",
                "/video/generate",
                "/video/concatenate",
                "/video/concatenate-by-steps",
                "/test-micro/ping"
        );

        // 检查当前路径是否需要跳过认证
        for (String permitPath : permitAllPaths) {
            if (path.equals(permitPath) || path.startsWith(permitPath + "/")) {
                System.out.println("=== DEBUG: Skipping JWT filter for permit path: " + path);
                filterChain.doFilter(request, response);
                return;
            }
        }

        // 其他路径需要验证token
        String token = getTokenFromRequest(request);
        System.out.println("=== DEBUG JWT Filter: Token found = " + (token != null));

        if (token != null && jwtTokenProvider.validateToken(token)) {
            try {
                Long userId = jwtTokenProvider.getUserIdFromJWT(token);
                System.out.println("=== DEBUG JWT Filter: Valid token for user: " + userId);

                // 设置认证信息
                // 如果有 UserDetailsService，可以取消注释下面的代码
                /*
                UserDetails userDetails = userDetailsService.loadUserByUsername(userId.toString());
                UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
                SecurityContextHolder.getContext().setAuthentication(authentication);
                */

            } catch (Exception e) {
                System.out.println("=== ERROR JWT Filter: " + e.getMessage());
            }
        } else {
            System.out.println("=== DEBUG JWT Filter: No valid token for path: " + path);
            // 对于需要认证但没有token的请求，返回401
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json");
            response.getWriter().write("{\"error\":\"Unauthorized\",\"message\":\"Missing or invalid token\"}");
            return;
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