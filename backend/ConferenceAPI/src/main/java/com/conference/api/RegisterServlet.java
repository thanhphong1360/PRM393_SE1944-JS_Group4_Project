
package com.conference.api;

import com.conference.config.DBConnection;
import com.conference.util.PasswordUtil;

import java.io.BufferedReader;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.util.regex.Pattern;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

@WebServlet("/api/auth/register")
public class RegisterServlet extends HttpServlet {

    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final Pattern EMAIL_PATTERN =
            Pattern.compile("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$");

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        // Đọc JSON từ request body
        JsonNode json;

        try {
            json = objectMapper.readTree(request.getInputStream());
        } catch (Exception e) {
            sendError(response, HttpServletResponse.SC_BAD_REQUEST,
                    "Invalid JSON");
            return;
        }

        String fullName = getText(json, "full_name");
        String email = getText(json, "email");
        String password = getText(json, "password");

        // Kiểm tra dữ liệu đầu vào
        if (fullName == null || fullName.isBlank()
                || email == null || email.isBlank()
                || password == null || password.isBlank()) {

            sendError(response, HttpServletResponse.SC_BAD_REQUEST,
                    "All fields are required");
            return;
        }

        fullName = fullName.trim();
        email = email.trim().toLowerCase();

        if (fullName.length() > 100) {
            sendError(response, HttpServletResponse.SC_BAD_REQUEST,
                    "Full name is too long");
            return;
        }

        if (email.length() > 255
                || !EMAIL_PATTERN.matcher(email).matches()) {
            sendError(response, HttpServletResponse.SC_BAD_REQUEST,
                    "Invalid email");
            return;
        }

        if (password.length() < 8) {
            sendError(response, HttpServletResponse.SC_BAD_REQUEST,
                    "Password must contain at least 8 characters");
            return;
        }

        // Tạo BCrypt hash
        String passwordHash = PasswordUtil.hashPassword(password);

        String sql = "INSERT INTO Users (full_name,email,password_hash,role_id) SELECT ?, ?, ?, role_id FROM Roles WHERE role_name = ?";

        try (Connection connection = DBConnection.getConnection();
             PreparedStatement statement =
                     connection.prepareStatement(sql)) {

            statement.setString(1, fullName);
            statement.setString(2, email);
            statement.setString(3, passwordHash);
            statement.setString(4, "Attendee");

            int rowsInserted = statement.executeUpdate();

            if (rowsInserted == 0) {
                sendError(response,
                        HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                        "Attendee role is not configured");
                return;
            }

            response.setStatus(HttpServletResponse.SC_CREATED);

            response.getWriter().write("{success: true,message: Registration successful}");

        } catch (SQLException e) {

            // SQL Server error 2601/2627: duplicate unique value
            if (e.getErrorCode() == 2601
                    || e.getErrorCode() == 2627) {

                sendError(response,
                        HttpServletResponse.SC_CONFLICT,
                        "Email already exists");
                return;
            }

            log("Registration database error", e);

            sendError(response,
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Registration failed");
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

        String json = objectMapper.writeValueAsString(
                new ErrorResponse(false, message)
        );

        response.getWriter().write(json);
    }

    private static class ErrorResponse {
        public boolean success;
        public String message;

        public ErrorResponse(boolean success, String message) {
            this.success = success;
            this.message = message;
        }
    }
}
