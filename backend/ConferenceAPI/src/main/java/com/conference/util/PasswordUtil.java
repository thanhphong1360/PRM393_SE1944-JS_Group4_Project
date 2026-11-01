
package com.conference.util;

import org.mindrot.jbcrypt.BCrypt;

public class PasswordUtil {

    private static final int WORK_FACTOR = 12;

    /**
     * Generate a BCrypt hash from a plain-text password.
     */
    public static String hashPassword(String plainPassword) {

        if (plainPassword == null || plainPassword.isBlank()) {
            throw new IllegalArgumentException(
                    "Password cannot be empty"
            );
        }

        String salt = BCrypt.gensalt(WORK_FACTOR);

        return BCrypt.hashpw(plainPassword, salt);
    }

    /**
     * Verify a plain-text password against a BCrypt hash.
     */
    public static boolean verifyPassword(
            String plainPassword,
            String passwordHash) {

        if (plainPassword == null || passwordHash == null) {
            return false;
        }

        try {
            return BCrypt.checkpw(
                    plainPassword,
                    passwordHash
            );
        } catch (IllegalArgumentException e) {
            return false;
        }
    }
    
    public static void main(String[] args) {

        String password = "AdminDemo123!";

        String hash = PasswordUtil.hashPassword(password);

        System.out.println("Password hash:");
        System.out.println(hash);
    }
}
