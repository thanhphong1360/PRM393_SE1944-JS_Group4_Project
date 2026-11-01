package com.conference.api;

import com.conference.config.DBConnection;
import java.io.IOException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/api/db-test")
public class DatabaseTestServlet extends HttpServlet {

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        String dbUsername = System.getenv("DB_USERNAME");
        String dbPassword = System.getenv("DB_PASSWORD");

        getServletContext().log(
                "DB_USERNAME exists: "
                + (dbUsername != null && !dbUsername.isBlank())
        );

        getServletContext().log(
                "DB_PASSWORD exists: "
                + (dbPassword != null && !dbPassword.isEmpty())
        );

        try (
                Connection connection = DBConnection.getConnection(); Statement statement = connection.createStatement(); ResultSet resultSet = statement.executeQuery("SELECT 1")) {
            if (resultSet.next()) {
                response.setStatus(HttpServletResponse.SC_OK);
                response.getWriter().write(
                        "{\"status\":\"ok\","
                        + "\"message\":\"Database connection successful\"}"
                );
            }

        } catch (Exception e) {
            getServletContext().log(
                    "Database connection test failed", e
            );

            response.setStatus(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR
            );

            response.getWriter().write(
                    "{\"status\":\"error\","
                    + "\"message\":\"Database connection failed. "
                    + "Check server logs.\"}"
            );
        }
    }
}
