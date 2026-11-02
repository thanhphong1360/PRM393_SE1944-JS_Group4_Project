package com.conference.api;

import com.conference.config.DBConnection;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

@WebServlet(name = "ConferenceDetailServlet", urlPatterns = {"/api/conferences/*"})
public class ConferenceDetailServlet extends HttpServlet {

    private final ObjectMapper objectMapper =
            new ObjectMapper();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        // 1. Lấy ID từ URL
        String pathInfo = request.getPathInfo();

        if (pathInfo == null || pathInfo.equals("/")) {
            sendError(
                    response,
                    400,
                    "Conference ID is required"
            );
            return;
        }

        String idText = pathInfo.substring(1);

        // 2. Kiểm tra ID
        int conferenceId;

        try {
            conferenceId = Integer.parseInt(idText);

            if (conferenceId <= 0) {
                throw new NumberFormatException();
            }

        } catch (NumberFormatException e) {
            sendError(
                    response,
                    400,
                    "Invalid conference ID"
            );
            return;
        }

        // 3. Truy vấn database
        String sql = "SELECT conference_id,title,location,start_date,description FROM Conference WHERE conference_id = ?";

        try (Connection connection =
                     DBConnection.getConnection();

             PreparedStatement statement =
                     connection.prepareStatement(sql)) {

            statement.setInt(1, conferenceId);

            try (ResultSet result = statement.executeQuery()) {

                if (!result.next()) {
                    sendError(
                            response,
                            404,
                            "Conference not found"
                    );
                    return;
                }

                // 4. Tạo JSON response
                ObjectNode conference =
                        objectMapper.createObjectNode();

                conference.put(
                        "conference_id",
                        result.getInt("conference_id")
                );

                conference.put(
                        "title",
                        result.getString("title")
                );

                conference.put(
                        "location",
                        result.getString("location")
                );

                conference.put(
                        "start_date",
                        result.getDate("start_date").toString()
                );

                String description =
                        result.getString("description");

                if (description != null) {
                    conference.put(
                            "description",
                            description
                    );
                } else {
                    conference.putNull("description");
                }

                response.setStatus(
                        HttpServletResponse.SC_OK
                );

                objectMapper.writeValue(
                        response.getWriter(),
                        conference
                );
            }

        } catch (SQLException e) {
            log("Get conference detail database error", e);

            sendError(
                    response,
                    500,
                    "Failed to retrieve conference"
            );
        }
    }

    private void sendError(
            HttpServletResponse response,
            int status,
            String message) throws IOException {

        response.setStatus(status);

        ObjectNode error =
                objectMapper.createObjectNode();

        error.put("success", false);
        error.put("message", message);

        objectMapper.writeValue(
                response.getWriter(),
                error
        );
    }
}