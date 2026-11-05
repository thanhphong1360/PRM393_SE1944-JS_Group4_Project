
CREATE TABLE Conference (
    conference_id INT IDENTITY(1,1) PRIMARY KEY,
    title NVARCHAR(200) NOT NULL,
    location NVARCHAR(200) NOT NULL,
    start_date DATE NOT NULL,
    description NVARCHAR(1000) NULL
);

ALTER TABLE Conference
ADD status NVARCHAR(20) NOT NULL
    CONSTRAINT DF_Conference_Status
    DEFAULT 'Upcoming';

ALTER TABLE Conference
ADD registration_policy NVARCHAR(30) NOT NULL
    CONSTRAINT DF_Conference_RegistrationPolicy
    DEFAULT 'Open';

ALTER TABLE Conference
ADD CONSTRAINT CK_Conference_RegistrationPolicy
CHECK (
    registration_policy IN (
        'Open',
        'ApprovalRequired',
        'InvitationOnly'
    )
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

CREATE TABLE ConferenceRegistration (
    registration_id INT IDENTITY(1,1) PRIMARY KEY,

    ticket_id UNIQUEIDENTIFIER NOT NULL
        DEFAULT NEWID(),

    conference_id INT NOT NULL,
    user_id INT NOT NULL,

    registered_at DATETIME2 NOT NULL
        DEFAULT SYSUTCDATETIME(),

    status NVARCHAR(20) NOT NULL
        DEFAULT 'Valid',

    CONSTRAINT FK_Registration_Conference
        FOREIGN KEY (conference_id)
        REFERENCES Conference(conference_id),

    CONSTRAINT FK_Registration_User
        FOREIGN KEY (user_id)
        REFERENCES Users(user_id),

    CONSTRAINT UQ_Registration_Ticket
        UNIQUE (ticket_id),

    CONSTRAINT CK_Registration_Status
        CHECK (status IN (
            'Valid',
            'Used',
            'Cancelled',
            'Revoked'
        ))
);
