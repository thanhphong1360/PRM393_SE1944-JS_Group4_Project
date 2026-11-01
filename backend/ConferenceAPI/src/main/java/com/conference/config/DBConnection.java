package com.conference.config;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBConnection {

    private static final String URL
            = "jdbc:sqlserver://DESKTOP-LI8DM67:1433;"
            + "databaseName=ConferenceDB;"
            + "encrypt=true;"
            + "trustServerCertificate=true;";

    public static Connection getConnection() throws SQLException {
        try {
            Class.forName(
                    "com.microsoft.sqlserver.jdbc.SQLServerDriver"
            );
        } catch (ClassNotFoundException e) {
            throw new SQLException(
                    "Microsoft SQL Server JDBC Driver not found", e
            );
        }

        return DriverManager.getConnection(
                URL,
                "sa",
                "123"
        );
    }

}
