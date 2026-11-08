
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
import java.util.Set;

@WebServlet(
        name = "UpdateConferenceServlet",
        urlPatterns = {"/api/admin/conferences/*"}
)
public class UpdateConferenceServlet extends HttpServlet {

    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final Set<String> VALID_POLICIES = Set.of(
            "Open",
            "ApprovalRequired",
            "InvitationOnly"
    );

    @Override
    protected void doPut(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        // 1. Get ID from URL
        String pathInfo = request.getPathInfo();

        if (pathInfo == null || pathInfo.equals("/")) {
            sendError(response, 400, "Conference ID is required");
            return;
        }

        int conferenceId;

        try {
            conferenceId = Integer.parseInt(pathInfo.substring(1));

            if (conferenceId <= 0) {
                throw new NumberFormatException();
            }

        } catch (NumberFormatException e) {
            sendError(response, 400, "Invalid conference ID");
            return;
        }

        // 2. Read JSON
        JsonNode json;

        try {
            json = objectMapper.readTree(request.getInputStream());
        } catch (Exception e) {
            sendError(response, 400, "Invalid JSON");
            return;
        }

        if (json == null || !json.isObject()) {
            sendError(response, 400, "Invalid JSON object");
            return;
        }

        // 3. Get data
        String title = getText(json, "title");
        String location = getText(json, "location");
        String startDateText = getText(json, "start_date");
        String description = getText(json, "description");
        String registrationPolicy = getText(json, "registration_policy");

        // 4. Validate required fields
        if (title == null || title.isBlank()
                || location == null || location.isBlank()
                || startDateText == null || startDateText.isBlank()
                || registrationPolicy == null
                || registrationPolicy.isBlank()) {

            sendError(
                    response,
                    400,
                    "Title, location, start_date and registration_policy are required"
            );
            return;
        }

        title = title.trim();
        location = location.trim();
        registrationPolicy = registrationPolicy.trim();

        if (title.length() > 200
                || location.length() > 200
                || (description != null && description.length() > 1000)) {

            sendError(
                    response,
                    400,
                    "One or more fields exceed the allowed length"
            );
            return;
        }

        // 5. Validate registration policy
        if (!VALID_POLICIES.contains(registrationPolicy)) {
            sendError(
                    response,
                    400,
                    "Invalid registration_policy. Allowed values: Open, ApprovalRequired, InvitationOnly"
            );
            return;
        }

        // 6. Parse date
        LocalDate startDate;

        try {
            startDate = LocalDate.parse(startDateText);
        } catch (DateTimeParseException e) {
            sendError(
                    response,
                    400,
                    "start_date must use YYYY-MM-DD format"
            );
            return;
        }

        // 7. Update database
        String sql = "UPDATE Conference SET "
                + "title = ?, "
                + "location = ?, "
                + "start_date = ?, "
                + "description = ?, "
                + "registration_policy = ? "
                + "WHERE conference_id = ?";

        try (Connection connection = DBConnection.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setString(1, title);
            statement.setString(2, location);
            statement.setDate(3, Date.valueOf(startDate));
            statement.setString(4, description);
            statement.setString(5, registrationPolicy);
            statement.setInt(6, conferenceId);

            int affectedRows = statement.executeUpdate();

            if (affectedRows == 0) {
                sendError(response, 404, "Conference not found");
                return;
            }

            ObjectNode result = objectMapper.createObjectNode();

            result.put("success", true);
            result.put("message", "Conference updated successfully");
            result.put("conference_id", conferenceId);
            result.put("registration_policy", registrationPolicy);

            response.setStatus(HttpServletResponse.SC_OK);

            objectMapper.writeValue(response.getWriter(), result);

        } catch (SQLException e) {
            log("Update conference database error", e);

            sendError(
                    response,
                    500,
                    "Failed to update conference"
            );
        }
    }

    private String getText(JsonNode json, String field) {
        JsonNode value = json.get(field);

        if (value == null || value.isNull() || !value.isTextual()) {
            return null;
        }

        return value.asText();
    }

    private void sendError(
            HttpServletResponse response,
            int status,
            String message) throws IOException {

        response.setStatus(status);

        ObjectNode error = objectMapper.createObjectNode();

        error.put("success", false);
        error.put("message", message);

        objectMapper.writeValue(response.getWriter(), error);
    }

    @Override
    protected void doDelete(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json;charset=UTF-8");

        // Get conference ID from URL
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

        try (Connection conn = DBConnection.getConnection();
                PreparedStatement stmt = conn.prepareStatement(sql)) {

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
            log("Delete conference database error", e);

            response.setStatus(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR
            );
            response.getWriter().write(
                    "{\"message\":\"Database error\"}"
            );
        }
    }
}
