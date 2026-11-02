
package com.conference.api;

import com.conference.config.DBConnection;
import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@WebServlet(name = "ConferenceServlet", urlPatterns = {"/api/conferences"})
public class ConferenceServlet extends HttpServlet {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String sql = "SELECT conference_id, title, location,\n" +
"               start_date, description, status\n" +
"        FROM Conference\n" +
"        WHERE status <> 'Cancelled'\n" +
"        ORDER BY start_date ASC";

        try (
            Connection connection = DBConnection.getConnection();
            PreparedStatement statement =
                    connection.prepareStatement(sql);
            ResultSet resultSet = statement.executeQuery()
        ) {
            List<Map<String, Object>> conferences =
                    new ArrayList<>();

            while (resultSet.next()) {
                Map<String, Object> conference =
                        new LinkedHashMap<>();

                conference.put(
                        "conference_id",
                        resultSet.getInt("conference_id")
                );
                conference.put(
                        "title",
                        resultSet.getString("title")
                );
                conference.put(
                        "location",
                        resultSet.getString("location")
                );

                java.sql.Date startDate =
                        resultSet.getDate("start_date");

                conference.put(
                        "start_date",
                        startDate != null
                                ? startDate.toString()
                                : null
                );

                conference.put(
                        "description",
                        resultSet.getString("description")
                );
                
                conference.put(
                        "status",
                        resultSet.getString("status")
                );

                conferences.add(conference);
            }

            objectMapper.writeValue(
                    response.getOutputStream(),
                    conferences
            );

        } catch (Exception e) {
            getServletContext().log(
                    "Failed to retrieve conferences", e
            );

            response.reset();
            response.setStatus(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR
            );
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");

            objectMapper.writeValue(
                    response.getOutputStream(),
                    Map.of(
                            "status", "error",
                            "message",
                            "Unable to retrieve conferences"
                    )
            );
        }
    }
}
