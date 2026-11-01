
package com.conference.api;

import com.conference.util.PasswordUtil;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/api/password-test")
public class PasswordTestServlet extends HttpServlet {

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        // Chỉ sử dụng mật khẩu giả để kiểm thử
        String testPassword = "DemoPassword123!";

        // Tạo password hash
        String passwordHash =
                PasswordUtil.hashPassword(testPassword);

        // Kiểm tra mật khẩu đúng
        boolean correctPassword =
                PasswordUtil.verifyPassword(
                        testPassword,
                        passwordHash
                );

        // Kiểm tra mật khẩu sai
        boolean wrongPassword =
                PasswordUtil.verifyPassword(
                        "WrongPassword456!",
                        passwordHash
                );

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String json = "{hash_created: %b,correct_password_matches: %b,wrong_password_matches: %b}".formatted(
                    passwordHash != null
                            && !passwordHash.isBlank(),
                    correctPassword,
                    wrongPassword
                );

        response.getWriter().write(json);
    }
}
