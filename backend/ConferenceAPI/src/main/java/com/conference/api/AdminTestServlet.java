package com.conference.api;

import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.Map;

@WebServlet(name = "AdminTestServlet", urlPatterns = {"/api/admin/test"})
public class AdminTestServlet extends HttpServlet {

    private final ObjectMapper objectMapper =
            new ObjectMapper();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        objectMapper.writeValue(
                response.getWriter(),
                Map.of(
                        "success", true,
                        "message", "Admin access granted"
                )
        );
    }
}