package com.conference.api;

import java.io.IOException;
import java.io.PrintWriter;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import com.conference.config.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import jakarta.servlet.annotation.WebServlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

@WebServlet(name = "AdminAttendeesServlet", urlPatterns = {"/api/admin/attendees"})
public class AdminAttendeesServlet extends HttpServlet {

    private final ObjectMapper mapper = new ObjectMapper();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json;charset=UTF-8");

        String search = request.getParameter("search");

        String sql = "SELECT \n"+
            "u.user_id,\n"+
            "u.full_name,\n"+
            "u.email,\n"+
            "u.is_active\n"+
        "FROM Users u\n"+
        "INNER JOIN Roles r ON u.role_id = r.role_id\n"+
        "WHERE r.role_name = 'Attendee'\n"+
          "AND u.is_active = 1";

        if (search != null && !search.trim().isEmpty()) {
            sql += " AND (\n"+
                  "u.full_name LIKE ?\n"+
                  "OR u.email LIKE ?)";
        }

        sql += " ORDER BY u.full_name ASC";

        try (Connection conn = DBConnection.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {

            if (search != null && !search.trim().isEmpty()) {
                String keyword = "%" + search.trim() + "%";

                stmt.setString(1, keyword);
                stmt.setString(2, keyword);
            }

            ArrayNode attendees = mapper.createArrayNode();

            try (ResultSet rs = stmt.executeQuery()) {

                while (rs.next()) {
                    ObjectNode attendee = mapper.createObjectNode();

                    attendee.put("user_id", rs.getInt("user_id"));
                    attendee.put("full_name", rs.getString("full_name"));
                    attendee.put("email", rs.getString("email"));
                    attendee.put("is_active", rs.getBoolean("is_active"));

                    attendees.add(attendee);
                }
            }

            ObjectNode result = mapper.createObjectNode();

            result.put("success", true);
            result.set("attendees", attendees);

            mapper.writeValue(response.getWriter(), result);

        } catch (SQLException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);

            ObjectNode error = mapper.createObjectNode();
            error.put("success", false);
            error.put("message", "Database error.");

            mapper.writeValue(response.getWriter(), error);

            e.printStackTrace();
        }
    }

}
