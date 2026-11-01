
CREATE TABLE Conference (
    conference_id INT IDENTITY(1,1) PRIMARY KEY,
    title NVARCHAR(200) NOT NULL,
    location NVARCHAR(200) NOT NULL,
    start_date DATE NOT NULL,
    description NVARCHAR(1000) NULL
);

CREATE TABLE Roles (
    role_id INT IDENTITY(1,1) PRIMARY KEY,
    role_name NVARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO Roles (role_name)
VALUES
    (N'Admin'),
    (N'Staff'),
    (N'Attendee');

CREATE TABLE Users (
    user_id INT IDENTITY(1,1) PRIMARY KEY,

    full_name NVARCHAR(100) NOT NULL,

    email NVARCHAR(255) NOT NULL UNIQUE,

    password_hash NVARCHAR(255) NOT NULL,

    role_id INT NOT NULL,

    is_active BIT NOT NULL
        DEFAULT 1,

    created_at DATETIME2 NOT NULL
        DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Users_Roles
        FOREIGN KEY (role_id)
        REFERENCES Roles(role_id)
);
