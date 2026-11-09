package com.conference.api;

import com.conference.util.JwtUtil;
import com.fasterxml.jackson.databind.ObjectMapper;

import io.jsonwebtoken.Claims;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.Arrays;
import java.util.Map;

@WebFilter({
    "/api/me",
    "/api/admin/*",
    "/api/staff/*",
    "/api/register-conference/*",
    "/api/my-registrations",
    "/api/my-registrations/*"
})
public class AuthFilter implements Filter {

    private final ObjectMapper objectMapper
            = new ObjectMapper();

    @Override
    public void doFilter(
            ServletRequest request,
            ServletResponse response,
            FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest
                = (HttpServletRequest) request;

        HttpServletResponse httpResponse
                = (HttpServletResponse) response;

        httpResponse.setContentType("application/json");
        httpResponse.setCharacterEncoding("UTF-8");

        if ("OPTIONS".equalsIgnoreCase(httpRequest.getMethod())) {
            httpResponse.setStatus(HttpServletResponse.SC_OK);
            return;
        }

        // 1. Lấy JWT từ Authorization header
        String authHeader
                = httpRequest.getHeader("Authorization");

        if (authHeader == null
                || !authHeader.startsWith("Bearer ")) {

            sendError(
                    httpResponse,
                    401,
                    "Missing or invalid Authorization header"
            );
            return;
        }

        String token = authHeader.substring(7).trim();

        if (token.isEmpty()) {
            sendError(
                    httpResponse,
                    401,
                    "Missing or invalid token"
            );
            return;
        }

        // 2. Xác thực JWT
        Claims claims;

        try {
            claims = JwtUtil.validateToken(token);

        } catch (Exception e) {
            sendError(
                    httpResponse,
                    401,
                    "Invalid or expired token"
            );
            return;
        }

        // 3. Lấy thông tin người dùng từ JWT
        int userId;
        String email;
        String role;

        try {
            userId = Integer.parseInt(claims.getSubject());
            email = claims.get("email", String.class);
            role = claims.get("role", String.class);

            if (email == null || role == null) {
                throw new IllegalArgumentException(
                        "Missing user information in token"
                );
            }

        } catch (Exception e) {
            sendError(
                    httpResponse,
                    401,
                    "Invalid token claims"
            );
            return;
        }

        // 4. Kiểm tra quyền theo endpoint
        String path = httpRequest.getServletPath();

        if (path.startsWith("/api/admin/")
                && !"Admin".equals(role)) {

            sendError(
                    httpResponse,
                    403,
                    "Admin permission required"
            );
            return;
        }

        if (path.startsWith("/api/staff/")
                && !Arrays.asList("Admin", "Staff")
                        .contains(role)) {

            sendError(
                    httpResponse,
                    403,
                    "Staff permission required"
            );
            return;
        }

        if (path.contains("/api/register-conference/")) {
            if (!"Attendee".equals(role)) {
                sendError(
                        httpResponse,
                        403,
                        "Attendee permission required"
                );
                return;
            }
        }

        if (path.contains("/api/my-registrations")) {
            if (!"Attendee".equals(role)) {
                sendError(
                        httpResponse,
                        403,
                        "Attendee permission required"
                );
                return;
            }
        }

        // 5. Chuyển thông tin người dùng cho Servlet
        httpRequest.setAttribute("userId", userId);
        httpRequest.setAttribute("userEmail", email);
        httpRequest.setAttribute("userRole", role);

        // 6. Cho phép request tiếp tục
        chain.doFilter(request, response);
    }

    private void sendError(
            HttpServletResponse response,
            int status,
            String message) throws IOException {

        response.setStatus(status);

        objectMapper.writeValue(
                response.getWriter(),
                Map.of(
                        "success", false,
                        "message", message
                )
        );
    }
}
