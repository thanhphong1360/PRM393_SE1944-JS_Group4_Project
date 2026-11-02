
package com.conference.api;

import com.conference.config.DBConnection;
import com.conference.util.PasswordUtil;
import com.conference.util.JwtUtil;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet(name = "LoginServlet", urlPatterns = {"/api/auth/login"})
public class LoginServlet extends HttpServlet {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        // Không lưu response đăng nhập vào cache
        response.setHeader("Cache-Control", "no-store");

        // 1. Đọc JSON request
        JsonNode json;

        try {
            json = objectMapper.readTree(request.getInputStream());
        } catch (Exception e) {
            sendError(
                    response,
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Invalid JSON"
            );
            return;
        }

        String email = getText(json, "email");
        String password = getText(json, "password");

        if (email == null || email.isBlank()
                || password == null || password.isBlank()) {

            sendError(
                    response,
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Email and password are required"
            );
            return;
        }

        email = email.trim().toLowerCase();

        // 2. Tìm tài khoản trong database
        String sql = "SELECT u.user_id,u.full_name,u.email,u.password_hash,u.is_active,r.role_name FROM Users u INNER JOIN Roles r ON u.role_id = r.role_id WHERE u.email = ? ";

        try (Connection connection = DBConnection.getConnection();
             PreparedStatement statement =
                     connection.prepareStatement(sql)) {

            statement.setString(1, email);

            try (ResultSet result = statement.executeQuery()) {

                // Không tìm thấy tài khoản
                if (!result.next()) {
                    sendError(
                            response,
                            HttpServletResponse.SC_UNAUTHORIZED,
                            "Invalid email or password"
                    );
                    return;
                }

                int userId = result.getInt("user_id");
                String fullName = result.getString("full_name");
                String userEmail = result.getString("email");
                String passwordHash =
                        result.getString("password_hash");
                boolean isActive = result.getBoolean("is_active");
                String role = result.getString("role_name");

                // 3. Kiểm tra trạng thái tài khoản
                if (!isActive) {
                    sendError(
                            response,
                            HttpServletResponse.SC_UNAUTHORIZED,
                            "Invalid email or password"
                    );
                    return;
                }

                // 4. Xác minh mật khẩu BCrypt
                boolean passwordMatches =
                        PasswordUtil.verifyPassword(
                                password,
                                passwordHash
                        );

                if (!passwordMatches) {
                    sendError(
                            response,
                            HttpServletResponse.SC_UNAUTHORIZED,
                            "Invalid email or password"
                    );
                    return;
                }

                // 5. Tạo JWT
                String accessToken = JwtUtil.generateToken(
                        userId,
                        userEmail,
                        role
                );

                // 6. Tạo JSON response
                ObjectNode resultJson =
                        objectMapper.createObjectNode();

                resultJson.put("success", true);
                resultJson.put("message", "Login successful");

                ObjectNode userJson =
                        resultJson.putObject("user");

                userJson.put("user_id", userId);
                userJson.put("full_name", fullName);
                userJson.put("email", userEmail);
                userJson.put("role", role);

                resultJson.put("access_token", accessToken);

                response.setStatus(
                        HttpServletResponse.SC_OK
                );

                objectMapper.writeValue(
                        response.getWriter(),
                        resultJson
                );
            }

        } catch (SQLException e) {

            log("Login database error", e);

            sendError(
                    response,
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Login failed"
            );

        } catch (Exception e) {

            log("Login processing error", e);

            sendError(
                    response,
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Login failed"
            );
        }
    }

    private String getText(JsonNode json, String field) {
        JsonNode value = json.get(field);

        if (value == null || !value.isTextual()) {
            return null;
        }

        return value.asText();
    }

    private void sendError(
            HttpServletResponse response,
            int status,
            String message) throws IOException {

        response.setStatus(status);

        ObjectNode errorJson =
                objectMapper.createObjectNode();

        errorJson.put("success", false);
        errorJson.put("message", message);

        objectMapper.writeValue(
                response.getWriter(),
                errorJson
        );
    }
}
