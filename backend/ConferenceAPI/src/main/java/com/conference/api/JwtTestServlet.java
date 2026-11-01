
package com.conference.api;

import com.conference.util.JwtUtil;
import io.jsonwebtoken.Claims;

import java.io.IOException;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/api/jwt-test")
public class JwtTestServlet extends HttpServlet {

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        try {
            // 1. Tạo token thử nghiệm
            String token = JwtUtil.generateToken(
                    1,
                    "test@example.com",
                    "Attendee"
            );

            // 2. Xác minh token
            Claims claims = JwtUtil.validateToken(token);

            boolean validToken =
                    "1".equals(claims.getSubject());

            // 3. Thử thay đổi token
            String modifiedToken = token + "invalid";

            boolean modifiedTokenRejected;

            try {
                JwtUtil.validateToken(modifiedToken);
                modifiedTokenRejected = false;
            } catch (Exception e) {
                modifiedTokenRejected = true;
            }

            String json = "{token_created: true,valid_token_accepted: %b,modified_token_rejected: %b}".formatted(
                        validToken,
                        modifiedTokenRejected
                    );

            response.getWriter().write(json);

        } catch (Exception e) {
            log("JWT test failed", e);

            response.setStatus(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR
            );

            response.getWriter().write(
                    "{\"success\":false,\"message\":\"JWT test failed\"}"
            );
        }
    }
}
