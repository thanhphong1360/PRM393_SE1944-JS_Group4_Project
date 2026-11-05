
package com.conference.api;

import com.conference.config.DBConnection;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

import java.io.IOException;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.UUID;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet(
        name = "CheckInServlet",
        urlPatterns = {"/api/staff/check-in"}
)
public class CheckInServlet extends HttpServlet {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-store");

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

        // 2. Get ticket_id
        JsonNode ticketNode = json.get("ticket_id");

        if (ticketNode == null
                || !ticketNode.isTextual()
                || ticketNode.asText().isBlank()) {

            sendError(
                    response,
                    HttpServletResponse.SC_BAD_REQUEST,
                    "ticket_id is required"
            );
            return;
        }

        String ticketIdText = ticketNode.asText().trim();

        // 3. Validate UUID
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

        // 4. SQL query
        String sql = "SELECT\n"+
                "cr.ticket_id,\n"+
                "cr.status,\n"+
               "cr.registered_at,\n"+

                "u.user_id,\n"+
                "u.full_name,\n"+
                "u.email,\n"+

                "c.conference_id,\n"+
                "c.title AS conference_title,\n"+
                "c.location,\n"+
                "c.start_date\n"+

            "FROM ConferenceRegistration cr\n"+

            "INNER JOIN Users u\n"+
                "ON cr.user_id = u.user_id\n"+

            "INNER JOIN Conference c\n"+
                "ON cr.conference_id = c.conference_id\n"+

            "WHERE cr.ticket_id = ?";

        try (Connection connection = DBConnection.getConnection()) {

            connection.setAutoCommit(false);

            try {

                // 5. Read ticket information
                String ticketStatus;
                Timestamp registeredAt;

                int userId;
                String fullName;
                String email;

                int conferenceId;
                String conferenceTitle;
                String location;
                Date startDate;

                String selectSql = sql.replace(
                        "FROM ConferenceRegistration cr",
                        "FROM ConferenceRegistration cr WITH (UPDLOCK, HOLDLOCK)"
                );

                try (PreparedStatement statement =
                             connection.prepareStatement(selectSql)) {

                    statement.setString(1, ticketId.toString());

                    try (ResultSet result = statement.executeQuery()) {

                        if (!result.next()) {

                            connection.rollback();

                            sendError(
                                    response,
                                    HttpServletResponse.SC_NOT_FOUND,
                                    "Ticket not found"
                            );

                            return;
                        }

                        ticketStatus = result.getString("status");

                        // 6. Check ticket status
                        if (!"Valid".equals(ticketStatus)) {

                            connection.rollback();

                            sendError(
                                    response,
                                    HttpServletResponse.SC_CONFLICT,
                                    "Ticket is not valid for check-in. Current status: "
                                            + ticketStatus
                            );

                            return;
                        }

                        registeredAt =
                                result.getTimestamp("registered_at");

                        // Attendee information
                        userId = result.getInt("user_id");
                        fullName = result.getString("full_name");
                        email = result.getString("email");

                        // Conference information
                        conferenceId = result.getInt("conference_id");
                        conferenceTitle =
                                result.getString("conference_title");

                        location = result.getString("location");
                        startDate = result.getDate("start_date");
                    }
                }

                // 7. Update ticket status
                String updateSql = "UPDATE ConferenceRegistration\n"+
                    "SET\n"+
                        "status = 'Used',\n"+
                        "checked_in_at = SYSUTCDATETIME()\n"+
                    "OUTPUT INSERTED.checked_in_at\n"+
                    "WHERE\n"+
                        "ticket_id = ?\n"+
                        "AND status = 'Valid'";

                Timestamp checkedInAt;

                try (PreparedStatement updateStatement =
                             connection.prepareStatement(updateSql)) {

                    updateStatement.setString(1, ticketId.toString());

                    try (ResultSet updateResult =
                                 updateStatement.executeQuery()) {

                        if (!updateResult.next()) {

                            connection.rollback();

                            sendError(
                                    response,
                                    HttpServletResponse.SC_CONFLICT,
                                    "Ticket has already been checked in or is no longer valid"
                            );

                            return;
                        }

                        checkedInAt =
                                updateResult.getTimestamp("checked_in_at");
                    }
                }

                // 8. Commit transaction
                connection.commit();

                // 9. Build JSON response
                ObjectNode responseJson =
                        objectMapper.createObjectNode();

                responseJson.put("success", true);
                responseJson.put(
                        "message",
                        "Check-in successful"
                );

                // Ticket information
                ObjectNode ticketJson =
                        responseJson.putObject("ticket");

                ticketJson.put(
                        "ticket_id",
                        ticketId.toString()
                );

                ticketJson.put("status", "Used");

                ticketJson.put(
                        "registered_at",
                        registeredAt.toLocalDateTime().toString()
                );

                ticketJson.put(
                        "checked_in_at",
                        checkedInAt.toLocalDateTime().toString()
                );

                // Attendee information
                ObjectNode attendeeJson =
                        responseJson.putObject("attendee");

                attendeeJson.put("user_id", userId);
                attendeeJson.put("full_name", fullName);
                attendeeJson.put("email", email);

                // Conference information
                ObjectNode conferenceJson =
                        responseJson.putObject("conference");

                conferenceJson.put("conference_id", conferenceId);
                conferenceJson.put("title", conferenceTitle);
                conferenceJson.put("location", location);

                conferenceJson.put(
                        "start_date",
                        startDate.toString()
                );

                // 10. Send response
                response.setStatus(HttpServletResponse.SC_OK);

                objectMapper.writeValue(
                        response.getWriter(),
                        responseJson
                );

            } catch (SQLException | IOException | RuntimeException e) {

                // Rollback if transaction has not been committed
                try {
                    connection.rollback();
                } catch (SQLException rollbackException) {
                    log(
                            "Transaction rollback failed",
                            rollbackException
                    );
                }

                throw e;
            }

        } catch (SQLException e) {

            log("Staff check-in database error", e);

            sendError(
                    response,
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Check-in failed"
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
