package com.conference.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

@WebServlet("/api/me")
public class MeServlet extends HttpServlet {

    private final ObjectMapper objectMapper =
            new ObjectMapper();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        // Lấy thông tin do AuthFilter cung cấp
        int userId = (int) request.getAttribute("userId");

        String email =
                (String) request.getAttribute("userEmail");

        String role =
                (String) request.getAttribute("userRole");

        ObjectNode result =
                objectMapper.createObjectNode();

        result.put("success", true);
        result.put("message", "Authenticated successfully");

        ObjectNode user = result.putObject("user");

        user.put("user_id", userId);
        user.put("email", email);
        user.put("role", role);

        response.setStatus(HttpServletResponse.SC_OK);

        objectMapper.writeValue(
                response.getWriter(),
                result
        );
    }
}