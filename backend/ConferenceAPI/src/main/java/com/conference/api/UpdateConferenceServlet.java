package com.conference.api;

import com.conference.config.DBConnection;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;

@WebServlet(name = "UpdateConferenceServlet", urlPatterns = {"/api/admin/conferences/*"})
public class UpdateConferenceServlet extends HttpServlet {

    private final ObjectMapper objectMapper
            = new ObjectMapper();

    @Override
    protected void doPut(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        // 1. Lấy ID từ URL
        String pathInfo = request.getPathInfo();

        if (pathInfo == null || pathInfo.equals("/")) {
            sendError(response, 400,
                    "Conference ID is required");
            return;
        }

        int conferenceId;

        try {
            conferenceId = Integer.parseInt(
                    pathInfo.substring(1)
            );

            if (conferenceId <= 0) {
                throw new NumberFormatException();
            }

        } catch (NumberFormatException e) {
            sendError(response, 400,
                    "Invalid conference ID");
            return;
        }

        // 2. Đọc JSON
        JsonNode json;

        try {
            json = objectMapper.readTree(
                    request.getInputStream()
            );
        } catch (Exception e) {
            sendError(response, 400, "Invalid JSON");
            return;
        }

        if (json == null || !json.isObject()) {
            sendError(response, 400, "Invalid JSON object");
            return;
        }

        // 3. Lấy dữ liệu
        String title = getText(json, "title");
        String location = getText(json, "location");
        String startDateText = getText(json, "start_date");
        String description = getText(json, "description");

        if (title == null || title.isBlank()
                || location == null || location.isBlank()
                || startDateText == null
                || startDateText.isBlank()) {

            sendError(response, 400,
                    "Title, location and start_date are required");
            return;
        }

        title = title.trim();
        location = location.trim();

        if (title.length() > 200
                || location.length() > 200
                || (description != null
                && description.length() > 1000)) {

            sendError(response, 400,
                    "One or more fields exceed the allowed length");
            return;
        }

        // 4. Chuyển ngày
        LocalDate startDate;

        try {
            startDate = LocalDate.parse(startDateText);
        } catch (DateTimeParseException e) {
            sendError(response, 400,
                    "start_date must use YYYY-MM-DD format");
            return;
        }

        // 5. Cập nhật database
        String sql = "UPDATE Conference SET title = ?,location = ?,start_date = ?,description = ? WHERE conference_id = ?";

        try (Connection connection
                = DBConnection.getConnection(); PreparedStatement statement
                = connection.prepareStatement(sql)) {

            statement.setString(1, title);
            statement.setString(2, location);
            statement.setDate(
                    3,
                    Date.valueOf(startDate)
            );
            statement.setString(4, description);
            statement.setInt(5, conferenceId);

            int affectedRows = statement.executeUpdate();

            if (affectedRows == 0) {
                sendError(response, 404,
                        "Conference not found");
                return;
            }

            ObjectNode result
                    = objectMapper.createObjectNode();

            result.put("success", true);
            result.put(
                    "message",
                    "Conference updated successfully"
            );
            result.put("conference_id", conferenceId);

            response.setStatus(
                    HttpServletResponse.SC_OK
            );

            objectMapper.writeValue(
                    response.getWriter(),
                    result
            );

        } catch (SQLException e) {
            log("Update conference database error", e);

            sendError(response, 500,
                    "Failed to update conference");
        }
    }

    private String getText(JsonNode json, String field) {
        JsonNode value = json.get(field);

        if (value == null || value.isNull()
                || !value.isTextual()) {
            return null;
        }

        return value.asText();
    }

    private void sendError(
            HttpServletResponse response,
            int status,
            String message) throws IOException {

        response.setStatus(status);

        ObjectNode error
                = objectMapper.createObjectNode();

        error.put("success", false);
        error.put("message", message);

        objectMapper.writeValue(
                response.getWriter(),
                error
        );
    }

    @Override
    protected void doDelete(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json;charset=UTF-8");

        // Lấy conference_id từ URL
        String pathInfo = request.getPathInfo();

        if (pathInfo == null || !pathInfo.matches("/\\d+")) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write(
                    "{\"message\":\"Invalid conference ID\"}"
            );
            return;
        }

        int conferenceId = Integer.parseInt(pathInfo.substring(1));

        String sql = "UPDATE Conference SET status = ? WHERE conference_id = ?";

        try (Connection conn = DBConnection.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, "Cancelled");
            stmt.setInt(2, conferenceId);

            int affectedRows = stmt.executeUpdate();

            if (affectedRows == 0) {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                response.getWriter().write(
                        "{\"message\":\"Conference not found\"}"
                );
                return;
            }

            response.setStatus(HttpServletResponse.SC_OK);
            response.getWriter().write(
                    "{\"message\":\"Conference deleted successfully\"}"
            );

        } catch (SQLException e) {
            e.printStackTrace();

            response.setStatus(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR
            );
            response.getWriter().write(
                    "{\"message\":\"Database error\"}"
            );
        }
    }
}
