package com.conference.api;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

import com.conference.config.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Timestamp;

@WebServlet(name = "RegisterConferenceServlet", urlPatterns = {"/api/register-conference/*"})
public class RegisterConferenceServlet extends HttpServlet {

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

        // 2. Get user ID from AuthFilter
        Integer userId = (Integer) request.getAttribute("userId");

        if (userId == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write(
                    "{\"message\":\"User authentication required\"}"
            );
            return;
        }

        try {
            if (!isConferenceAvailable(conferenceId)) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                response.getWriter().write(
                        "{\"message\":\"Conference is not available for registration\"}"
                );
                return;
            }

        } catch (Exception e) {
            e.printStackTrace();

            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write(
                    "{\"message\":\"Database error\"}"
            );
            return;
        }

        try {
            if (hasValidRegistration(conferenceId, userId)) {
                response.setStatus(HttpServletResponse.SC_CONFLICT);

                response.getWriter().write(
                        "{\"message\":\"You already have a valid ticket for this conference\"}"
                );

                return;
            }

        } catch (Exception e) {
            e.printStackTrace();

            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);

            response.getWriter().write(
                    "{\"message\":\"Database error\"}"
            );

            return;
        }

        try {
            createRegistration(conferenceId, userId, response);

        } catch (Exception e) {
            e.printStackTrace();

            response.setStatus(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR
            );

            response.getWriter().write(
                    "{\"message\":\"Failed to create registration\"}"
            );
        }

    }

    private boolean isConferenceAvailable(int conferenceId)
            throws Exception {

        String sql = "SELECT status, registration_policy\n"
                + "FROM Conference\n"
                + "WHERE conference_id = ?";

        try (java.sql.Connection conn = DBConnection.getConnection(); java.sql.PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, conferenceId);

            try (java.sql.ResultSet rs = ps.executeQuery()) {

                if (!rs.next()) {
                    return false;
                }

                String status = rs.getString("status");
                String policy = rs.getString("registration_policy");

                return "Upcoming".equals(status)
                        && "Open".equals(policy);
            }
        }
    }

    private boolean hasValidRegistration(
            int conferenceId,
            int userId
    ) throws Exception {

        String sql = "SELECT COUNT(*)\n"
                + "FROM ConferenceRegistration\n"
                + "WHERE conference_id = ?\n"
                + "AND user_id = ?\n"
                + "AND status = 'Valid'";

        try (java.sql.Connection conn = DBConnection.getConnection(); java.sql.PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, conferenceId);
            ps.setInt(2, userId);

            try (java.sql.ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        }

        return false;
    }

    private void createRegistration(
            int conferenceId,
            int userId,
            HttpServletResponse response
    ) throws Exception {

        String sql = "INSERT INTO ConferenceRegistration (conference_id,user_id)\n"
                + "OUTPUT\n"
                + "INSERTED.registration_id,\n"
                + "INSERTED.ticket_id,\n"
                + "INSERTED.registered_at,\n"
                + "INSERTED.status\n"
                + "VALUES (?, ?)";

        try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, conferenceId);
            ps.setInt(2, userId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    int registrationId
                            = rs.getInt("registration_id");

                    String ticketId
                            = rs.getString("ticket_id");

                    Timestamp registeredAt
                            = rs.getTimestamp("registered_at");

                    String status
                            = rs.getString("status");

                    response.setStatus(
                            HttpServletResponse.SC_CREATED
                    );

                    response.getWriter().write(
                            "{"
                            + "\"message\":\"Registration successful\","
                            + "\"registration\":{"
                            + "\"registration_id\":" + registrationId + ","
                            + "\"ticket_id\":\"" + ticketId + "\","
                            + "\"conference_id\":" + conferenceId + ","
                            + "\"user_id\":" + userId + ","
                            + "\"registered_at\":\"" + registeredAt + "\","
                            + "\"status\":\"" + status + "\""
                            + "}"
                            + "}"
                    );
                }
            }
        }
    }

}
