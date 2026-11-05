
package com.conference.api;

import com.conference.config.DBConnection;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Date;
import java.sql.Timestamp;
import java.util.UUID;

@WebServlet(name = "RegistrationDetailServlet", urlPatterns = {"/api/my-registrations/*"})
public class RegistrationDetailServlet extends HttpServlet {

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        // 1. Get user ID from AuthFilter
        Integer userId = (Integer) request.getAttribute("userId");

        if (userId == null) {
            response.setStatus(
                HttpServletResponse.SC_UNAUTHORIZED
            );

            response.getWriter().write(
                "{\"message\":\"User authentication required\"}"
            );
            return;
        }

        // 2. Get ticket ID from URL
        String pathInfo = request.getPathInfo();

        if (pathInfo == null || pathInfo.length() <= 1) {
            response.setStatus(
                HttpServletResponse.SC_BAD_REQUEST
            );

            response.getWriter().write(
                "{\"message\":\"Ticket ID is required\"}"
            );
            return;
        }

        UUID ticketId;

        try {
            ticketId = UUID.fromString(pathInfo.substring(1));

        } catch (IllegalArgumentException e) {
            response.setStatus(
                HttpServletResponse.SC_BAD_REQUEST
            );

            response.getWriter().write(
                "{\"message\":\"Invalid ticket ID\"}"
            );
            return;
        }

        // 3. Query registration
        String sql = "SELECT\n"+
                "cr.registration_id,\n"+
                "cr.ticket_id,\n"+
                "cr.conference_id,\n"+
                "cr.registered_at,\n"+
                "cr.status,\n"+
                "c.title AS conference_title,\n"+
                "c.location,\n"+
                "c.start_date,\n"+
                "c.description\n"+
            "FROM ConferenceRegistration cr\n"+
            "INNER JOIN Conference c\n"+
             "   ON cr.conference_id = c.conference_id\n"+
            "WHERE cr.ticket_id = ?\n"+
             " AND cr.user_id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setObject(1, ticketId);
            ps.setInt(2, userId);

            try (ResultSet rs = ps.executeQuery()) {

                if (!rs.next()) {
                    response.setStatus(
                        HttpServletResponse.SC_NOT_FOUND
                    );

                    response.getWriter().write(
                        "{\"message\":\"Registration not found\"}"
                    );
                    return;
                }

                int registrationId =
                    rs.getInt("registration_id");

                int conferenceId =
                    rs.getInt("conference_id");

                Timestamp registeredAt =
                    rs.getTimestamp("registered_at");

                String status =
                    rs.getString("status");

                String title =
                    rs.getString("conference_title");

                String location =
                    rs.getString("location");

                Date startDate =
                    rs.getDate("start_date");

                String description =
                    rs.getString("description");

                // 4. Build response
                String json = "{"
                    + "\"registration_id\":" + registrationId + ","
                    + "\"ticket_id\":\"" + ticketId + "\","
                    + "\"conference_id\":" + conferenceId + ","
                    + "\"conference_title\":\"" + title + "\","
                    + "\"location\":\"" + location + "\","
                    + "\"start_date\":\"" + startDate + "\","
                    + "\"registered_at\":\"" + registeredAt + "\","
                    + "\"status\":\"" + status + "\","
                    + "\"description\":"
                    + (description == null
                        ? "null"
                        : "\"" + description + "\"")
                    + "}";

                response.setStatus(
                    HttpServletResponse.SC_OK
                );

                response.getWriter().write(json);
            }

        } catch (Exception e) {
            e.printStackTrace();

            response.setStatus(
                HttpServletResponse.SC_INTERNAL_SERVER_ERROR
            );

            response.getWriter().write(
                "{\"message\":\"Failed to retrieve registration\"}"
            );
        }
    }
}
