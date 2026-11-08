package com.conference.api;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.conference.config.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.UUID;

@WebServlet(
        name = "IssueTicketServlet",
        urlPatterns = {"/api/admin/issue-ticket/*"}
)
public class IssueTicketServlet extends HttpServlet {

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        // 1. Get conference ID from URL
        String pathInfo = request.getPathInfo();

        if (pathInfo == null || pathInfo.length() <= 1) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write(
                    "{\"message\":\"Conference ID is required\"}"
            );
            return;
        }

        int conferenceId;

        try {
            conferenceId = Integer.parseInt(pathInfo.substring(1));

            if (conferenceId <= 0) {
                throw new NumberFormatException();
            }

        } catch (NumberFormatException e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write(
                    "{\"message\":\"Invalid conference ID\"}"
            );
            return;
        }

        // 2. Read JSON request body
        ObjectMapper mapper = new ObjectMapper();
        JsonNode jsonNode;

        try {
            jsonNode = mapper.readTree(request.getInputStream());

        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write(
                    "{\"message\":\"Invalid JSON request body\"}"
            );
            return;
        }

        // 3. Get user_id
        JsonNode userIdNode = jsonNode.get("attendee_id");

        if (userIdNode == null || !userIdNode.isIntegralNumber()
                || !userIdNode.canConvertToInt()) {

            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write(
                    "{\"message\":\"Valid attendee_id is required\"}"
            );
            return;
        }

        int userId = userIdNode.asInt();

        if (userId <= 0) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write(
                    "{\"message\":\"attendee_id must be greater than zero\"}"
            );
            return;
        }

        // 4. Check conference
        String sql = "SELECT status, registration_policy "
                + "FROM Conference "
                + "WHERE conference_id = ?";

        try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, conferenceId);

            try (ResultSet rs = ps.executeQuery()) {

                // Conference does not exist
                if (!rs.next()) {
                    response.setStatus(
                            HttpServletResponse.SC_NOT_FOUND
                    );

                    response.getWriter().write(
                            "{\"message\":\"Conference not found\"}"
                    );
                    return;
                }

                String status = rs.getString("status");

                String registrationPolicy
                        = rs.getString("registration_policy");

                // Conference must be Upcoming
                if (!"Upcoming".equals(status)) {
                    response.setStatus(
                            HttpServletResponse.SC_BAD_REQUEST
                    );

                    response.getWriter().write(
                            "{\"message\":\"Only upcoming conferences can receive tickets\"}"
                    );
                    return;
                }

                // Conference must be InvitationOnly
                if (!"InvitationOnly".equals(registrationPolicy)) {
                    response.setStatus(
                            HttpServletResponse.SC_BAD_REQUEST
                    );

                    response.getWriter().write(
                            "{\"message\":\"Tickets can only be issued for invitation-only conferences\"}"
                    );
                    return;
                }
            }

            // 5. Check attendee
            String userSql
                    = "SELECT u.user_id, u.full_name, u.email "
                    + "FROM Users u "
                    + "INNER JOIN Roles r ON u.role_id = r.role_id "
                    + "WHERE u.user_id = ? "
                    + "AND r.role_name = 'Attendee' "
                    + "AND u.is_active = 1";

            try (PreparedStatement userPs
                    = conn.prepareStatement(userSql)) {

                userPs.setInt(1, userId);

                try (ResultSet userRs = userPs.executeQuery()) {

                    if (!userRs.next()) {
                        response.setStatus(
                                HttpServletResponse.SC_NOT_FOUND
                        );

                        response.getWriter().write(
                                "{\"message\":\"Active attendee account not found\"}"
                        );
                        return;
                    }

                    String attendeeName
                            = userRs.getString("full_name");

                    String attendeeEmail
                            = userRs.getString("email");
                }
            }

            // 6. Check existing valid registration
            String registrationSql
                    = "SELECT registration_id "
                    + "FROM ConferenceRegistration "
                    + "WHERE conference_id = ? "
                    + "AND user_id = ? "
                    + "AND status = 'Valid'";

            try (PreparedStatement registrationPs
                    = conn.prepareStatement(registrationSql)) {

                registrationPs.setInt(1, conferenceId);
                registrationPs.setInt(2, userId);

                try (ResultSet registrationRs
                        = registrationPs.executeQuery()) {

                    if (registrationRs.next()) {
                        response.setStatus(
                                HttpServletResponse.SC_CONFLICT
                        );

                        response.getWriter().write(
                                "{\"message\":\"Attendee already has a valid ticket for this conference\"}"
                        );
                        return;
                    }
                }
            }

            // 7. Issue ticket
            String insertSql
                    = "INSERT INTO ConferenceRegistration "
                    + "(conference_id, user_id) "
                    + "OUTPUT "
                    + "INSERTED.registration_id, "
                    + "INSERTED.ticket_id, "
                    + "INSERTED.registered_at, "
                    + "INSERTED.status "
                    + "VALUES (?, ?)";

            try (PreparedStatement insertPs
                    = conn.prepareStatement(insertSql)) {

                insertPs.setInt(1, conferenceId);
                insertPs.setInt(2, userId);

                try (ResultSet insertRs = insertPs.executeQuery()) {

                    if (insertRs.next()) {

                        int registrationId
                                = insertRs.getInt("registration_id");

                        UUID ticketId = UUID.fromString(
                                insertRs.getString("ticket_id")
                        );

                        Timestamp registeredAt
                                = insertRs.getTimestamp("registered_at");

                        String ticketStatus
                                = insertRs.getString("status");

                        response.setStatus(
                                HttpServletResponse.SC_CREATED
                        );

                        response.getWriter().write(
                                "{\"message\":\"Ticket issued successfully\","
                                + "\"registration\":{"
                                + "\"registration_id\":" + registrationId + ","
                                + "\"ticket_id\":\"" + ticketId + "\","
                                + "\"conference_id\":" + conferenceId + ","
                                + "\"user_id\":" + userId + ","
                                + "\"registered_at\":\"" + registeredAt + "\","
                                + "\"status\":\"" + ticketStatus + "\""
                                + "}}"
                        );

                        return;
                    }
                }
            }

        } catch (Exception e) {
            e.printStackTrace();

            response.setStatus(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR
            );

            response.getWriter().write(
                    "{\"message\":\"Failed to validate conference\"}"
            );
        }

    }
}
