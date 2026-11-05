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
import java.sql.SQLException;
import java.util.UUID;

@WebServlet(name = "RevokeTicketServlet", urlPatterns = {"/api/admin/revoke-ticket/*"})
public class RevokeTicketServlet extends HttpServlet {

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        // 1. Get ticket ID from URL
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

// 2. Validate ticket UUID
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
        // 3. Start database transaction
        try (Connection conn = DBConnection.getConnection()) {

            conn.setAutoCommit(false);

            try {

                // 4. Find ticket and lock the row
                String selectSql
                        = "SELECT status "
                        + "FROM ConferenceRegistration WITH (UPDLOCK, HOLDLOCK) "
                        + "WHERE ticket_id = ?";

                String currentStatus;

                try (PreparedStatement ps
                        = conn.prepareStatement(selectSql)) {

                    ps.setObject(1, ticketId);

                    try (ResultSet rs = ps.executeQuery()) {

                        if (!rs.next()) {

                            conn.rollback();

                            response.setStatus(
                                    HttpServletResponse.SC_NOT_FOUND
                            );

                            response.getWriter().write(
                                    "{\"message\":\"Ticket not found\"}"
                            );

                            return;
                        }

                        currentStatus = rs.getString("status");
                    }
                }

                // 5. Only Valid tickets can be revoked
                if (!"Valid".equals(currentStatus)) {

                    conn.rollback();

                    response.setStatus(
                            HttpServletResponse.SC_CONFLICT
                    );

                    response.getWriter().write(
                            "{\"message\":\"Only valid tickets can be revoked\"}"
                    );

                    return;
                }

                // 6. Update ticket status
                String updateSql
                        = "UPDATE ConferenceRegistration "
                        + "SET status = 'Revoked' "
                        + "WHERE ticket_id = ? AND status = 'Valid'";

                try (PreparedStatement ps
                        = conn.prepareStatement(updateSql)) {

                    ps.setObject(1, ticketId);

                    int affectedRows = ps.executeUpdate();

                    // Ensure exactly one ticket was updated
                    if (affectedRows != 1) {

                        conn.rollback();

                        response.setStatus(
                                HttpServletResponse.SC_CONFLICT
                        );

                        response.getWriter().write(
                                "{\"message\":\"Ticket could not be revoked\"}"
                        );

                        return;
                    }
                }

// 7. Commit transaction
                conn.commit();

// 8. Return success response
                response.setStatus(
                        HttpServletResponse.SC_OK
                );

                response.getWriter().write(
                        "{"
                        + "\"message\":\"Ticket revoked successfully\","
                        + "\"ticket_id\":\"" + ticketId + "\","
                        + "\"status\":\"Revoked\""
                        + "}"
                );
            } catch (SQLException e) {

                try {
                    conn.rollback();
                } catch (SQLException rollbackException) {
                    e.addSuppressed(rollbackException);
                }

                throw e;
            }

        } catch (SQLException e) {

            e.printStackTrace();

            response.setStatus(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR
            );

            response.getWriter().write(
                    "{\"message\":\"Failed to revoke ticket\"}"
            );
        }
    }
}
