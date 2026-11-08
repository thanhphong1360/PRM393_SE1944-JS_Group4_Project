
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
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.Set;

@WebServlet(
        name = "CreateConferenceServlet",
        urlPatterns = {"/api/admin/conferences"}
)
public class CreateConferenceServlet extends HttpServlet {

    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final Set<String> VALID_POLICIES = Set.of(
            "Open",
            "ApprovalRequired",
            "InvitationOnly"
    );

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        // 1. Read JSON
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

        // 2. Get data
        String title = getText(json, "title");
        String location = getText(json, "location");
        String startDateText = getText(json, "start_date");
        String description = getText(json, "description");
        String registrationPolicy = getText(json, "registration_policy");

        // 3. Validate required fields
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

        // 4. Validate registration policy
        if (!VALID_POLICIES.contains(registrationPolicy)) {
            sendError(
                    response,
                    400,
                    "Invalid registration_policy. Allowed values: Open, ApprovalRequired, InvitationOnly"
            );
            return;
        }

        // 5. Parse start date
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

        // 6. Insert into SQL Server
        String sql = "INSERT INTO Conference "
                + "(title, location, start_date, description, registration_policy) "
                + "VALUES (?, ?, ?, ?, ?)";

        try (Connection connection = DBConnection.getConnection();
                PreparedStatement statement = connection.prepareStatement(
                        sql,
                        PreparedStatement.RETURN_GENERATED_KEYS
                )) {

            statement.setString(1, title);
            statement.setString(2, location);
            statement.setDate(3, Date.valueOf(startDate));
            statement.setString(4, description);
            statement.setString(5, registrationPolicy);

            int affectedRows = statement.executeUpdate();

            if (affectedRows == 0) {
                sendError(response, 500, "Failed to create conference");
                return;
            }

            // 7. Get generated conference ID
            try (ResultSet generatedKeys = statement.getGeneratedKeys()) {

                if (!generatedKeys.next()) {
                    sendError(
                            response,
                            500,
                            "Conference created but ID could not be retrieved"
                    );
                    return;
                }

                int conferenceId = generatedKeys.getInt(1);

                // 8. Return JSON
                ObjectNode result = objectMapper.createObjectNode();

                result.put("success", true);
                result.put("message", "Conference created successfully");
                result.put("conference_id", conferenceId);
                result.put("registration_policy", registrationPolicy);

                response.setStatus(HttpServletResponse.SC_CREATED);

                objectMapper.writeValue(response.getWriter(), result);
            }

        } catch (SQLException e) {
            log("Create conference database error", e);

            sendError(
                    response,
                    500,
                    "Failed to create conference"
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
}
