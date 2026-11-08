package com.conference.api;

import com.conference.config.DBConnection;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

@WebServlet(name = "AdminConferenceListServlet", urlPatterns = {"/api/admin/conferences/all"})
public class AdminConferenceListServlet extends HttpServlet {

    private final ObjectMapper mapper = new ObjectMapper();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json;charset=UTF-8");

        String sql = "SELECT conference_id, title, location,\n"+
                       "start_date, description, status, registration_policy\n"+
                "FROM Conference\n"+
                "ORDER BY start_date ASC";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            ArrayNode conferences = mapper.createArrayNode();

            while (rs.next()) {
                ObjectNode conference = mapper.createObjectNode();

                conference.put(
                        "conference_id",
                        rs.getInt("conference_id")
                );

                conference.put("title", rs.getString("title"));
                conference.put("location", rs.getString("location"));

                conference.put(
                        "start_date",
                        rs.getDate("start_date").toString()
                );

                String description = rs.getString("description");

                if (description != null) {
                    conference.put("description", description);
                } else {
                    conference.putNull("description");
                }

                conference.put("status", rs.getString("status"));
                
                conference.put("registration_policy", rs.getString("registration_policy"));

                conferences.add(conference);
            }

            response.setStatus(HttpServletResponse.SC_OK);
            mapper.writeValue(response.getWriter(), conferences);

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