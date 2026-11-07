-- =======================================================
-- PRM Project Database Schema & Sample Data
-- SQL Server Script
-- =======================================================

USE PRMProject;
GO

-- 1. Drop existing tables in correct order if re-initializing
IF OBJECT_ID('dbo.ConferenceRegistration', 'U') IS NOT NULL DROP TABLE dbo.ConferenceRegistration;
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
IF OBJECT_ID('dbo.Roles', 'U') IS NOT NULL DROP TABLE dbo.Roles;
IF OBJECT_ID('dbo.Conference', 'U') IS NOT NULL DROP TABLE dbo.Conference;
GO

-- 2. Conference Table
CREATE TABLE Conference (
    conference_id INT IDENTITY(1,1) PRIMARY KEY,
    title NVARCHAR(200) NOT NULL,
    location NVARCHAR(200) NOT NULL,
    start_date DATE NOT NULL,
    description NVARCHAR(1000) NULL,
    status NVARCHAR(20) NOT NULL 
        CONSTRAINT DF_Conference_Status DEFAULT 'Upcoming',
    registration_policy NVARCHAR(30) NOT NULL 
        CONSTRAINT DF_Conference_RegistrationPolicy DEFAULT 'Open',
    CONSTRAINT CK_Conference_RegistrationPolicy CHECK (
        registration_policy IN ('Open', 'ApprovalRequired', 'InvitationOnly')
    )
);
GO

-- 3. Roles Table
CREATE TABLE Roles (
    role_id INT IDENTITY(1,1) PRIMARY KEY,
    role_name NVARCHAR(50) NOT NULL UNIQUE
);
GO

-- Insert default system roles
INSERT INTO Roles (role_name)
VALUES
    (N'Admin'),
    (N'Staff'),
    (N'Attendee');
GO

-- 4. Users Table
CREATE TABLE Users (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    full_name NVARCHAR(100) NOT NULL,
    email NVARCHAR(255) NOT NULL UNIQUE,
    password_hash NVARCHAR(255) NOT NULL,
    role_id INT NOT NULL,
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Users_Roles FOREIGN KEY (role_id) REFERENCES Roles(role_id)
);
GO

-- 5. ConferenceRegistration Table (Tickets)
CREATE TABLE ConferenceRegistration (
    registration_id INT IDENTITY(1,1) PRIMARY KEY,
    ticket_id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    conference_id INT NOT NULL,
    user_id INT NOT NULL,
    registered_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    status NVARCHAR(20) NOT NULL DEFAULT 'Valid',
    checked_in_at DATETIME2 NULL, -- Used for Staff QR Check-in attendance
    CONSTRAINT FK_Registration_Conference FOREIGN KEY (conference_id) REFERENCES Conference(conference_id),
    CONSTRAINT FK_Registration_User FOREIGN KEY (user_id) REFERENCES Users(user_id),
    CONSTRAINT UQ_Registration_Ticket UNIQUE (ticket_id),
    CONSTRAINT CK_Registration_Status CHECK (
        status IN ('Valid', 'Used', 'Cancelled', 'Revoked')
    )
);
GO

-- =======================================================
-- 6. SAMPLE DATA INSERTION (DỮ LIỆU MẪU ĐỂ TEST)
-- =======================================================

-- 6.1. Thêm danh sách Hội nghị (Conferences)
INSERT INTO Conference (title, location, start_date, description, status, registration_policy)
VALUES
    (N'Hội nghị Công nghệ AI & Cloud 2026', N'Trung tâm Hội nghị Quốc gia, Hà Nội', '2026-11-20', N'Hội thảo chuyên sâu về các xu hướng Generative AI và Cloud Native mới nhất.', 'Upcoming', 'Open'),
    (N'Diễn đàn Lập trình Di động Flutter & Mobile Summit', N'Hội trường Trống Đồng, TP. Hồ Chí Minh', '2026-12-05', N'Gặp gỡ các chuyên gia hàng đầu về Flutter, Android và iOS.', 'Upcoming', 'Open'),
    (N'Hội thảo An toàn Thông tin & Cybersecurity 2026', N'Đại học FPT, Hà Nội', '2026-12-18', N'Bảo mật thông tin trong thời đại ứng dụng trí tuệ nhân tạo.', 'Upcoming', 'ApprovalRequired');
GO

-- 6.2. Thêm người dùng (Users)
-- MẬT KHẨU MẶC ĐỊNH CHO TẤT CẢ TÀI KHOẢN LÀ: 123456
-- Chuỗi hash BCrypt hợp lệ chuẩn jBCrypt: $2a$12$f51h3ulGJg/C6hwWWA6Iqeabl6Z0aJMMnJxKhzaFGg4JxGDW8Rq2y
INSERT INTO Users (full_name, email, password_hash, role_id, is_active)
VALUES
    -- Admin (role_id = 1)
    (N'Quản Trị Viên', N'admin@conference.com', N'$2a$12$f51h3ulGJg/C6hwWWA6Iqeabl6Z0aJMMnJxKhzaFGg4JxGDW8Rq2y', 1, 1),
    
    -- Nhân viên điểm danh (role_id = 2)
    (N'Nguyễn Văn Staff', N'staff@conference.com', N'$2a$12$f51h3ulGJg/C6hwWWA6Iqeabl6Z0aJMMnJxKhzaFGg4JxGDW8Rq2y', 2, 1),
    (N'Trần Thị Kiểm Vé', N'staff2@conference.com', N'$2a$12$f51h3ulGJg/C6hwWWA6Iqeabl6Z0aJMMnJxKhzaFGg4JxGDW8Rq2y', 2, 1),

    -- Người tham dự (role_id = 3)
    (N'Nguyễn Văn An', N'an.nguyen@gmail.com', N'$2a$12$f51h3ulGJg/C6hwWWA6Iqeabl6Z0aJMMnJxKhzaFGg4JxGDW8Rq2y', 3, 1),
    (N'Trần Thị Bình', N'binh.tran@gmail.com', N'$2a$12$f51h3ulGJg/C6hwWWA6Iqeabl6Z0aJMMnJxKhzaFGg4JxGDW8Rq2y', 3, 1),
    (N'Lê Hoàng Cường', N'cuong.le@gmail.com', N'$2a$12$f51h3ulGJg/C6hwWWA6Iqeabl6Z0aJMMnJxKhzaFGg4JxGDW8Rq2y', 3, 1),
    (N'Phạm Thu Dung', N'dung.pham@gmail.com', N'$2a$12$f51h3ulGJg/C6hwWWA6Iqeabl6Z0aJMMnJxKhzaFGg4JxGDW8Rq2y', 3, 1);
GO

-- 6.3. Thêm Vé tham dự (ConferenceRegistration)
-- Gán cố định ticket_id UUID để test quét mã QR hoặc nhập thủ công
INSERT INTO ConferenceRegistration (ticket_id, conference_id, user_id, status, registered_at, checked_in_at)
VALUES
    -- [Case 1] Vé HỢP LỆ, CHƯA ĐIỂM DANH (Quét sẽ thành công!)
    ('d3b07384-d113-46fb-a79b-2221b6329e47', 1, 4, 'Valid', '2026-11-01 09:00:00', NULL),

    -- [Case 2] Vé HỢP LỆ thứ 2, CHƯA ĐIỂM DANH (Quét sẽ thành công!)
    ('a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 1, 5, 'Valid', '2026-11-02 10:15:00', NULL),

    -- [Case 3] Vé ĐÃ ĐƯỢC ĐIỂM DANH (Quét sẽ báo cảnh báo vé đã dùng)
    ('e4f5a6b7-c8d9-4e0f-1a2b-3c4d5e6f7a8b', 1, 6, 'Used', '2026-11-03 14:00:00', '2026-11-05 08:30:00'),

    -- [Case 4] Vé ĐÃ BỊ HỦY (Quét sẽ báo lỗi vé không hợp lệ)
    ('f9e8d7c6-b5a4-4321-fedc-ba9876543210', 2, 7, 'Cancelled', '2026-11-04 16:45:00', NULL);
GO
