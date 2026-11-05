package com.conference.api;

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

import com.conference.config.DBConnection;

@WebServlet(name = "MyRegistrationsServlet", urlPatterns = {"/api/my-registrations"})
public class MyRegistrationsServlet extends HttpServlet {

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        Integer userId = (Integer) request.getAttribute("userId");

        if (userId == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");

            response.getWriter().write(
                    "{\"message\":\"User authentication required\"}"
            );
            return;
        }

        try {
            getRegistrations(userId, response);

        } catch (Exception e) {
            e.printStackTrace();

            response.setStatus(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR
            );

            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");

            response.getWriter().write(
                    "{\"message\":\"Failed to retrieve registrations\"}"
            );
        }
    }

    private void getRegistrations(
            int userId,
            HttpServletResponse response
    ) throws Exception {

        String sql = "SELECT\n"
                + "cr.registration_id,\n"
                + "cr.ticket_id,\n"
                + "cr.conference_id,\n"
                + "cr.registered_at,\n"
                + "cr.status,\n"
                + "c.title AS conference_title,\n"
                + "c.location,\n"
                + "c.start_date,\n"
                + "c.description\n"
                + "FROM ConferenceRegistration cr\n"
                + "INNER JOIN Conference c\n"
                + "   ON cr.conference_id = c.conference_id\n"
                + "WHERE cr.user_id = ?\n"
                + "ORDER BY cr.registered_at DESC";

        StringBuilder json = new StringBuilder();
        json.append("{\"registrations\":[");

        try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {

                boolean first = true;

                while (rs.next()) {

                    if (!first) {
                        json.append(",");
                    }

                    first = false;

                    int registrationId
                            = rs.getInt("registration_id");

                    String ticketId
                            = rs.getString("ticket_id");

                    int conferenceId
                            = rs.getInt("conference_id");

                    Timestamp registeredAt
                            = rs.getTimestamp("registered_at");

                    String status
                            = rs.getString("status");

                    String title
                            = rs.getString("conference_title");

                    String location
                            = rs.getString("location");

                    Date startDate
                            = rs.getDate("start_date");

                    String description
                            = rs.getString("description");

                    json.append("{")
                            .append("\"registration_id\":")
                            .append(registrationId).append(",")
                            .append("\"ticket_id\":\"")
                            .append(ticketId).append("\",")
                            .append("\"conference_id\":")
                            .append(conferenceId).append(",")
                            .append("\"conference_title\":\"")
                            .append(title).append("\",")
                            .append("\"location\":\"")
                            .append(location).append("\",")
                            .append("\"start_date\":\"")
                            .append(startDate).append("\",")
                            .append("\"registered_at\":\"")
                            .append(registeredAt).append("\",")
                            .append("\"status\":\"")
                            .append(status).append("\"")
                            .append("}");
                }
            }
        }

        json.append("]}");

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setStatus(HttpServletResponse.SC_OK);

        response.getWriter().write(json.toString());
    }

}
