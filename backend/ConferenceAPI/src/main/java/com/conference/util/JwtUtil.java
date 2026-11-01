
package com.conference.util;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.util.Date;

public class JwtUtil {

    private static final long EXPIRATION_TIME =
            15 * 60 * 1000; // 15 phút

    private static Key getSigningKey() {
        String secret = "ConferenceProjectSecretKey2026-LocalDev-Only-123456";

        if (secret == null || secret.isBlank()) {
            throw new IllegalStateException(
                    "CONFERENCE_JWT_SECRET is not configured"
            );
        }

        byte[] keyBytes = secret.getBytes(StandardCharsets.UTF_8);

        return Keys.hmacShaKeyFor(keyBytes);
    }

    public static String generateToken(
            int userId,
            String email,
            String role) {

        Date now = new Date();
        Date expiration = new Date(
                now.getTime() + EXPIRATION_TIME
        );

        return Jwts.builder()
                .subject(String.valueOf(userId))
                .claim("email", email)
                .claim("role", role)
                .issuedAt(now)
                .expiration(expiration)
                .signWith(getSigningKey())
                .compact();
    }

    public static Claims validateToken(String token) {
        return Jwts.parser()
                .verifyWith(
                        (javax.crypto.SecretKey) getSigningKey()
                )
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
    
    public static void main(String[] args) {
        String key = System.getenv("CONFERENCE_JWT_SECRET");
        System.out.println("key = "+key);
    }
}

