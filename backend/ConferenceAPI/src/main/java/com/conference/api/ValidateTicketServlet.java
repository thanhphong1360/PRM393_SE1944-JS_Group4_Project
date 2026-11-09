
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
import java.sql.Timestamp;
import java.util.UUID;

@WebServlet(
        name = "ValidateTicketServlet",
        urlPatterns = {"/api/staff/validate-ticket"}
)
public class ValidateTicketServlet extends HttpServlet {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        // 1. Read JSON request
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

        if (json == null || !json.isObject()) {
            sendError(
                    response,
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Invalid JSON object"
            );
            return;
        }

        // 2. Read ticket_id
        JsonNode ticketIdNode = json.get("ticket_id");

        if (ticketIdNode == null || !ticketIdNode.isTextual()
                || ticketIdNode.asText().isBlank()) {

            sendError(
                    response,
                    HttpServletResponse.SC_BAD_REQUEST,
                    "ticket_id is required"
            );
            return;
        }

        String ticketIdText = ticketIdNode.asText().trim();

        UUID ticketId;

        try {
            ticketId = UUID.fromString(ticketIdText);
        } catch (IllegalArgumentException e) {
            sendError(
                    response,
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Invalid ticket_id format"
            );
            return;
        }

        // 3. Read conference_id
        JsonNode conferenceIdNode = json.get("conference_id");

        if (conferenceIdNode == null
                || !conferenceIdNode.canConvertToInt()) {

            sendError(
                    response,
                    HttpServletResponse.SC_BAD_REQUEST,
                    "conference_id is required and must be an integer"
            );
            return;
        }

        int requestedConferenceId = conferenceIdNode.asInt();

        if (requestedConferenceId <= 0) {
            sendError(
                    response,
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Invalid conference_id"
            );
            return;
        }

        // 4. Query ticket, attendee and conference information
        String sql =
                "SELECT "
                + "cr.ticket_id, "
                + "cr.status, "
                + "cr.registered_at, "
                + "u.user_id, "
                + "u.full_name, "
                + "u.email, "
                + "c.conference_id, "
                + "c.title AS conference_title, "
                + "c.location, "
                + "c.start_date "
                + "FROM ConferenceRegistration cr "
                + "INNER JOIN Users u "
                + "ON cr.user_id = u.user_id "
                + "INNER JOIN Conference c "
                + "ON cr.conference_id = c.conference_id "
                + "WHERE cr.ticket_id = ?";

        try (Connection connection = DBConnection.getConnection();
             PreparedStatement statement =
                     connection.prepareStatement(sql)) {

            statement.setString(1, ticketId.toString());

            try (ResultSet result = statement.executeQuery()) {

                // 5. Check whether ticket exists
                if (!result.next()) {
                    sendError(
                            response,
                            HttpServletResponse.SC_NOT_FOUND,
                            "Ticket not found"
                    );
                    return;
                }

                // 6. Read ticket information
                String ticketStatus = result.getString("status");

                Timestamp registeredAt =
                        result.getTimestamp("registered_at");

                // 7. Check whether ticket belongs to selected conference
                int actualConferenceId =
                        result.getInt("conference_id");

                if (actualConferenceId != requestedConferenceId) {
                    sendError(
                            response,
                            HttpServletResponse.SC_CONFLICT,
                            "This ticket does not belong to the selected conference"
                    );
                    return;
                }

                // 8. Check ticket status
                if (!"Valid".equals(ticketStatus)) {
                    sendError(
                            response,
                            HttpServletResponse.SC_CONFLICT,
                            "Ticket is not valid for check-in. Current status: "
                                    + ticketStatus
                    );
                    return;
                }

                // 9. Read attendee information
                int userId = result.getInt("user_id");
                String fullName = result.getString("full_name");
                String email = result.getString("email");

                // 10. Read conference information
                String conferenceTitle =
                        result.getString("conference_title");

                String location = result.getString("location");
                Date startDate = result.getDate("start_date");

                // 11. Build JSON response
                ObjectNode responseJson =
                        objectMapper.createObjectNode();

                responseJson.put("success", true);
                responseJson.put(
                        "message",
                        "Ticket is valid. Please confirm check-in."
                );

                // Ticket information
                ObjectNode ticketJson =
                        responseJson.putObject("ticket");

                ticketJson.put(
                        "ticket_id",
                        ticketId.toString()
                );

                ticketJson.put("status", ticketStatus);

                if (registeredAt != null) {
                    ticketJson.put(
                            "registered_at",
                            registeredAt.toLocalDateTime().toString()
                    );
                }

                // Attendee information
                ObjectNode attendeeJson =
                        responseJson.putObject("attendee");

                attendeeJson.put("user_id", userId);
                attendeeJson.put("full_name", fullName);
                attendeeJson.put("email", email);

                // Conference information
                ObjectNode conferenceJson =
                        responseJson.putObject("conference");

                conferenceJson.put(
                        "conference_id",
                        actualConferenceId
                );

                conferenceJson.put("title", conferenceTitle);
                conferenceJson.put("location", location);

                if (startDate != null) {
                    conferenceJson.put(
                            "start_date",
                            startDate.toString()
                    );
                }

                response.setStatus(HttpServletResponse.SC_OK);

                objectMapper.writeValue(
                        response.getWriter(),
                        responseJson
                );
            }

        } catch (SQLException e) {

            log("Validate ticket database error", e);

            sendError(
                    response,
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Failed to validate ticket"
            );
        }
    }

    // Send JSON error response
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
