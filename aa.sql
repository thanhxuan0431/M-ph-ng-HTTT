CREATE DATABASE aa;
GO
USE aa;
GO

/* ======================= MASTER TABLES ======================= */

CREATE TABLE dbo.MOVIE 
(
    ID_movie     CHAR(5)         NOT NULL PRIMARY KEY,
    name_movie   NVARCHAR(100)   NOT NULL,
    type_movie   NVARCHAR(50)    NOT NULL,
    main_actor   NVARCHAR(50)        NULL,
    director     NVARCHAR(50)        NULL,
    descript     NVARCHAR(500)       NULL,
    duration     INT             NOT NULL CHECK (duration > 0),
    date_start   DATE            NOT NULL,
    status_movie NVARCHAR(30)    NOT NULL CHECK (status_movie IN (N'Đang chiếu', N'Sắp chiếu'))
);
GO

CREATE TABLE dbo.TYPE_ROOM 
(
    ID_type_room  CHAR(4)      NOT NULL PRIMARY KEY,
    name_type_room VARCHAR(5)  NOT NULL
);
GO

CREATE TABLE dbo.CINEMA_ROOM 
(
    ID_room      CHAR(3)      NOT NULL PRIMARY KEY,
    ID_type_room CHAR(4)      NOT NULL,
    status_room  NVARCHAR(20) NOT NULL,
    CONSTRAINT FK_ROOM_Type FOREIGN KEY (ID_type_room) REFERENCES dbo.TYPE_ROOM(ID_type_room)
);
GO

CREATE TABLE dbo.TYPE_SEAT 
(
    ID_type_seat   CHAR(4)       NOT NULL PRIMARY KEY,
    name_type_seat NVARCHAR(10)  NOT NULL
);
GO

/* Seat: ID_seat là mã duy nhất toàn hệ thống; name_seat là nhãn hiện trên ghế (có thể trùng giữa các phòng) */
CREATE TABLE dbo.SEAT 
(
    ID_seat      CHAR(5)     NOT NULL PRIMARY KEY,
    name_seat    CHAR(3)     NOT NULL,
    ID_room      CHAR(3)     NOT NULL,
    ID_type_seat CHAR(4)     NOT NULL,
    CONSTRAINT UQ_SEAT_Name_Room UNIQUE (name_seat, ID_room),
    CONSTRAINT FK_SEAT_ROOM FOREIGN KEY (ID_room) REFERENCES dbo.CINEMA_ROOM(ID_room),
    CONSTRAINT FK_SEAT_Type FOREIGN KEY (ID_type_seat) REFERENCES dbo.TYPE_SEAT(ID_type_seat)
);
GO

CREATE TABLE dbo.TIME_SLOT 
(
    ID_time_slot   CHAR(4)       NOT NULL PRIMARY KEY,
    name_time_slot NVARCHAR(10)  NOT NULL UNIQUE,
    time_start     TIME          NOT NULL,
    time_end       TIME          NOT NULL
);
GO

CREATE TABLE dbo.SHOWTIME 
(
    ID_showtime  CHAR(4) NOT NULL PRIMARY KEY,
    ID_movie     CHAR(5) NOT NULL,
    ID_room      CHAR(3) NOT NULL,
    ID_time_slot CHAR(4) NOT NULL,
    date_start   DATE    NOT NULL,
    time_start   TIME    NOT NULL,
    time_end     TIME    NOT NULL,
    CONSTRAINT CK_SHOWTIME_TimeRange CHECK (time_start < time_end),
    CONSTRAINT FK_ST_Movie     FOREIGN KEY (ID_movie)     REFERENCES dbo.MOVIE(ID_movie),
    CONSTRAINT FK_ST_Room      FOREIGN KEY (ID_room)      REFERENCES dbo.CINEMA_ROOM(ID_room),
    CONSTRAINT FK_ST_TimeSlot  FOREIGN KEY (ID_time_slot) REFERENCES dbo.TIME_SLOT(ID_time_slot)
);
GO

/* PRICE: bảng giá theo loại phòng, khung giờ, loại ghế */
CREATE TABLE dbo.PRICE 
(
    ID_price     CHAR(4)   NOT NULL PRIMARY KEY,
    ID_type_room CHAR(4)   NOT NULL,
    ID_time_slot CHAR(4)   NOT NULL,
    ID_type_seat CHAR(4)   NOT NULL,
    price_ticket DECIMAL(12,0) NOT NULL,
    date_creat   DATE      NOT NULL,
    CONSTRAINT UQ_PRICE_RoomSlotSeat UNIQUE (ID_type_room, ID_time_slot, ID_type_seat),
    CONSTRAINT FK_PRICE_TypeRoom  FOREIGN KEY (ID_type_room)  REFERENCES dbo.TYPE_ROOM(ID_type_room),
    CONSTRAINT FK_PRICE_TimeSlot  FOREIGN KEY (ID_time_slot)  REFERENCES dbo.TIME_SLOT(ID_time_slot),
    CONSTRAINT FK_PRICE_TypeSeat  FOREIGN KEY (ID_type_seat)  REFERENCES dbo.TYPE_SEAT(ID_type_seat)
);
GO

CREATE TABLE dbo.PROMOTION 
(
    ID_promo     VARCHAR(20)  NOT NULL PRIMARY KEY,
    name_promo   NVARCHAR(50) NOT NULL,
    type_promo   NVARCHAR(15) NOT NULL,
    [condition]  NVARCHAR(100) NOT NULL,
    date_start   DATE         NOT NULL,
    date_end     DATE         NOT NULL,
    status_promo NVARCHAR(15) NOT NULL
);
GO

CREATE TABLE dbo.USERS
(
    ID_user   CHAR(3)       NOT NULL PRIMARY KEY,
    name_user NVARCHAR(50)  NOT NULL,
    position  NVARCHAR(50)  NOT NULL,
    email     VARCHAR(50)   NOT NULL,
    pass      VARCHAR(100)  NOT NULL
);
GO

CREATE TABLE dbo.PAYMENT 
(
    ID_payment   CHAR(4)       NOT NULL PRIMARY KEY,
    type_payment NVARCHAR(30)  NOT NULL
);
GO

CREATE TABLE dbo.RECEIPT 
(
    ID_receipt   CHAR(6)       NOT NULL PRIMARY KEY,
    name_client  NVARCHAR(50)  NOT NULL,
    ID_user      CHAR(3)       NOT NULL,
    ID_payment   CHAR(4)       NOT NULL,
    date_created DATE          NOT NULL,
    CONSTRAINT FK_R_User    FOREIGN KEY (ID_user)    REFERENCES dbo.USERS(ID_user),
    CONSTRAINT FK_R_Payment FOREIGN KEY (ID_payment) REFERENCES dbo.PAYMENT(ID_payment)
);
GO

/* -----Danh sách ghế hợp lệ cho từng suất----------- */
CREATE TABLE dbo.SHOWTIME_SEAT 
(
  ID_showtime CHAR(4) NOT NULL,
  ID_seat     CHAR(5) NOT NULL,
  CONSTRAINT PK_SHOWTIME_SEAT PRIMARY KEY (ID_showtime, ID_seat),
  CONSTRAINT FK_SS_Showtime FOREIGN KEY (ID_showtime) REFERENCES dbo.SHOWTIME(ID_showtime),
  CONSTRAINT FK_SS_Seat     FOREIGN KEY (ID_seat)     REFERENCES dbo.SEAT(ID_seat)
);
GO

/*Trigger để ngăn ghép ghế sai phòng ngay tại bảng cầu */
CREATE TRIGGER dbo.TRG_SS_SeatRoomMatch
ON dbo.SHOWTIME_SEAT
AFTER INSERT, UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (
    SELECT 1
    FROM inserted i
    JOIN dbo.SHOWTIME st ON st.ID_showtime = i.ID_showtime
    JOIN dbo.SEAT     s  ON s.ID_seat      = i.ID_seat
    WHERE s.ID_room <> st.ID_room
  )
  BEGIN
    RAISERROR (N'Ghế không thuộc đúng phòng của suất.', 16, 1);
    ROLLBACK TRAN; RETURN;
  END
END;
GO

CREATE TABLE dbo.RECEIPT_DETAILS
(
    ID_detail   CHAR(5) NOT NULL PRIMARY KEY,
    ID_receipt  CHAR(6)  NOT NULL,
    ID_showtime CHAR(4)  NOT NULL,
    ID_seat     CHAR(5)  NOT NULL,
    ID_promo    VARCHAR(20) NULL,

    CONSTRAINT FK_RD_Receipt      FOREIGN KEY (ID_receipt)            REFERENCES dbo.RECEIPT(ID_receipt),
    CONSTRAINT FK_RD_ShowtimeSeat FOREIGN KEY (ID_showtime, ID_seat)  REFERENCES dbo.SHOWTIME_SEAT(ID_showtime, ID_seat),
    CONSTRAINT FK_RD_Promo        FOREIGN KEY (ID_promo)              REFERENCES dbo.PROMOTION(ID_promo),

    CONSTRAINT UQ_RD_ShowtimeSeat UNIQUE (ID_showtime, ID_seat) 
);
GO

/* ======================= VIEWS (DERIVED) ======================= */

/* Giờ chiếu thực tế kèm tên khung giờ */
CREATE VIEW dbo.vSHOWTIME_TIME AS
SELECT 
  st.ID_showtime,
  st.ID_movie,
  st.ID_room,
  st.date_start,
  st.ID_time_slot,
  ts.name_time_slot,
  st.time_start,
  st.time_end
FROM dbo.SHOWTIME st
JOIN dbo.TIME_SLOT ts ON ts.ID_time_slot = st.ID_time_slot;
GO

/* Giá cơ sở cho từng dòng vé (không lưu bảng) */
CREATE VIEW dbo.vRECEIPT_DETAILS_BASEPRICE
AS
SELECT 
  rd.ID_detail,
  rd.ID_receipt,
  rd.ID_showtime,
  rd.ID_seat,
  st.ID_room,
  st.ID_time_slot,
  cr.ID_type_room,
  s.ID_type_seat,
  p.ID_price,
  p.price_ticket AS base_price
FROM dbo.RECEIPT_DETAILS rd
JOIN dbo.SHOWTIME       st ON st.ID_showtime   = rd.ID_showtime
JOIN dbo.CINEMA_ROOM    cr ON cr.ID_room       = st.ID_room
JOIN dbo.SEAT            s ON s.ID_seat        = rd.ID_seat
JOIN dbo.PRICE           p ON p.ID_type_room   = cr.ID_type_room
                           AND p.ID_time_slot  = st.ID_time_slot
                           AND p.ID_type_seat  = s.ID_type_seat;
GO

/* Tổng tiền hoá đơn (chưa trừ KM) */
CREATE VIEW dbo.vRECEIPT_TOTALS_BASE
AS
SELECT r.ID_receipt, SUM(v.base_price) AS total_money_base
FROM dbo.RECEIPT r
JOIN dbo.vRECEIPT_DETAILS_BASEPRICE v
  ON v.ID_receipt = r.ID_receipt
GROUP BY r.ID_receipt;
GO

/*-----------Dữ liệu mẫu------------------*/

INSERT INTO dbo.MOVIE (ID_movie, name_movie, type_movie, main_actor, director, descript, duration, date_start, status_movie)
VALUES
('M01', N'Avengers: Endgame', N'Khoa học viễn tưởng', N'Robert Downey Jr.', N'Anthony Russo',
 N'Một cái kết cho loạt phim Avengers, đầy hành động và kịch tính.', 180, CONVERT(date,'26/10/2025',103), N'Đang chiếu'),
('M02', N'Inception', N'Kinh dị tâm lý', N'Leonardo DiCaprio', N'Christopher Nolan',
 N'Một bộ phim kinh dị xoắn não về những giấc mơ trong mơ.', 150, CONVERT(date,'16/11/2025',103), N'Sắp chiếu'),
('M03', N'The Lion King', N'Hoạt hình', N'Donald Glover', N'Jon Favreau',
 N'Bộ phim hoạt hình kinh điển được làm lại cho khán giả hiện đại.', 120, CONVERT(date,'19/11/2025',103), N'Sắp chiếu'),
('M04', N'Joker', N'Kinh dị tâm lý', N'Joaquin Phoenix', N'Todd Phillips',
 N'Một phim kinh dị tâm lý đen tối về sự trỗi dậy của Joker.', 120, CONVERT(date,'04/11/2025',103), N'Đang chiếu'),
('M05', N'Toy Story 4', N'Hoạt hình', N'Tom Hanks', N'Josh Cooley',
 N'Woody và Buzz bắt đầu cuộc phiêu lưu giải cứu Forky.', 100, CONVERT(date,'21/10/2025',103), N'Đang chiếu'),
('M06', N'The Matrix', N'Khoa học viễn tưởng', N'Keanu Reeves', N'Wachowskis',
 N'Một hacker phát hiện ra rằng thực tại anh đang sống là một thế giới mô phỏng.', 130, CONVERT(date,'04/12/2025',103), N'Sắp chiếu'),
('M07', N'The Dark Knight', N'Hành động', N'Christian Bale', N'Christopher Nolan',
 N'Batman đối mặt với Joker, một nhân vật phản diện theo chủ nghĩa vô chính phủ.', 150, CONVERT(date,'18/07/2025',103), N'Đang chiếu'),
('M08', N'Titanic', N'Lãng mạn', N'Leonardo DiCaprio', N'James Cameron',
 N'Một câu chuyện tình yêu lấy bối cảnh chuyến hành trình định mệnh trên tàu Titanic.', 195, CONVERT(date,'24/12/2025',103), N'Sắp chiếu'),
('M09', N'Spider-Man: No Way Home', N'Hành động', N'Tom Holland', N'Jon Watts',
 N'Người Nhện đối mặt với những thử thách mới khi danh tính của anh bị bại lộ.', 150, CONVERT(date,'09/12/2025',103), N'Sắp chiếu'),
('M10', N'Frozen II', N'Hoạt hình', N'Idina Menzel', N'Chris Buck',
 N'Elsa và Anna trở lại trong hành trình khám phá nguồn gốc sức mạnh của Elsa.', 105, CONVERT(date,'02/11/2025',103), N'Đang chiếu');
GO

INSERT INTO dbo.TYPE_ROOM (ID_type_room, name_type_room) VALUES
('TR01', '2D'),
('TR02', '3D'),
('TR03', 'IMAX');
GO

INSERT INTO dbo.CINEMA_ROOM (ID_room, ID_type_room, status_room) VALUES
('R01', 'TR01', N'Đang hoạt động'),
('R02', 'TR02', N'Đang hoạt động'),
('R03', 'TR03', N'Đang hoạt động'),
('R04', 'TR01', N'Đang bảo trì'),
('R05', 'TR01', N'Đang hoạt động'),
('R06', 'TR03', N'Đang hoạt động'),
('R07', 'TR02', N'Đang hoạt động'),
('R08', 'TR01', N'Đang hoạt động'),
('R09', 'TR02', N'Đang hoạt động'),
('R10', 'TR03', N'Đang hoạt động');
GO

INSERT INTO dbo.TYPE_SEAT (ID_type_seat, name_type_seat) VALUES
('TS01', N'Thường'),
('TS02', N'VIP'),
('TS03', N'Ghế đôi');
GO

INSERT INTO dbo.SEAT (ID_seat, name_seat, ID_room, ID_type_seat) VALUES
('S0001','A01','R01','TS02'),
('S0002','A01','R05','TS02'),
('S0003','A02','R01','TS02'),
('S0004','A02','R03','TS02'),
('S0005','B03','R02','TS02'),
('S0006','B03','R07','TS01'),
('S0007','C01','R02','TS01'),
('S0008','C01','R06','TS03'),
('S0009','C02','R02','TS01'),
('S0010','C05','R03','TS01'),
('S0011','D01','R03','TS01'),
('S0012','D01','R08','TS01'),
('S0013','D04','R03','TS01'),
('S0014','E02','R10','TS03'),
('S0015','E02','R02','TS03'),
('S0016','E04','R07','TS03'),
('S0017','F01','R01','TS03'),
('S0018','F01','R06','TS01'),
('S0019','F03','R05','TS03'),
('S0020','G02','R09','TS02'),
('S0021','G02','R01','TS01'),
('S0022','H01','R02','TS02'),
('S0023','H05','R02','TS01'),
('S0024','I02','R07','TS03'),
('S0025','J03','R10','TS03');
GO

INSERT INTO dbo.TIME_SLOT (ID_time_slot, name_time_slot, time_start, time_end) VALUES
('SL01', N'Sáng',  '06:00', '10:59'),
('SL02', N'Trưa',  '11:00', '13:59'),
('SL03', N'Chiều', '14:00', '16:59'),
('SL04', N'Tối',   '17:00', '20:59'),
('SL05', N'Khuya', '21:00', '23:59');
GO

INSERT INTO dbo.SHOWTIME (ID_showtime, ID_movie, ID_room, ID_time_slot, date_start, time_start, time_end) VALUES
 ('SH01', 'M01', 'R03', 'SL04', CONVERT(date, '26/11/2025', 103), '17:00','20:00'),
 ('SH02', 'M01', 'R06', 'SL04', CONVERT(date, '26/11/2026', 103), '17:00','20:00'),
 ('SH03', 'M01', 'R10', 'SL04', CONVERT(date, '02/12/2025', 103), '17:00','20:00'),
 ('SH04', 'M04', 'R03', 'SL01', CONVERT(date, '15/12/2025', 103), '08:00','10:00'),
 ('SH05', 'M04', 'R06', 'SL02', CONVERT(date, '04/12/2025', 103), '11:00','13:00'),
 ('SH06', 'M04', 'R10', 'SL04', CONVERT(date, '07/12/2025', 103), '17:00','19:00'),
 ('SH07', 'M05', 'R02', 'SL04', CONVERT(date, '21/11/2025', 103), '17:30','19:10'),
 ('SH08', 'M05', 'R07', 'SL03', CONVERT(date, '30/11/2025', 103), '14:00','15:40'),
 ('SH09', 'M05', 'R09', 'SL01', CONVERT(date, '05/12/2025', 103), '09:00','10:40'),
 ('SH10', 'M07', 'R07', 'SL04', CONVERT(date, '01/12/2025', 103), '17:30','20:00'),
 ('SH11', 'M07', 'R09', 'SL05', CONVERT(date, '04/12/2025', 103), '21:00','23:30'),
 ('SH12', 'M07', 'R02', 'SL04', CONVERT(date, '20/11/2025', 103), '17:30','20:00'),
 ('SH13', 'M10', 'R01', 'SL04', CONVERT(date, '15/11/2025', 103), '18:00','19:45'),
 ('SH14', 'M10', 'R02', 'SL01', CONVERT(date, '20/11/2025', 103), '09:00','10:45'),
 ('SH15', 'M10', 'R09', 'SL03', CONVERT(date, '04/12/2025', 103), '14:00','15:45');
GO

INSERT INTO dbo.PRICE (ID_price, ID_type_room, ID_time_slot, ID_type_seat, price_ticket, date_creat) VALUES
 ('PC01','TR01','SL01','TS01',  90000, CONVERT(date,'01/01/2023',103)),
 ('PC02','TR01','SL01','TS02', 110000, CONVERT(date,'01/01/2023',103)),
 ('PC03','TR01','SL01','TS03', 180000, CONVERT(date,'01/01/2023',103)),
 ('PC04','TR01','SL02','TS01',  95000, CONVERT(date,'01/01/2023',103)),
 ('PC05','TR01','SL02','TS02', 115000, CONVERT(date,'01/01/2023',103)),
 ('PC06','TR01','SL02','TS03', 190000, CONVERT(date,'01/01/2023',103)),
 ('PC07','TR01','SL03','TS01', 100000, CONVERT(date,'01/01/2023',103)),
 ('PC08','TR01','SL03','TS02', 120000, CONVERT(date,'01/01/2023',103)),
 ('PC09','TR01','SL03','TS03', 200000, CONVERT(date,'01/01/2023',103)),
 ('PC10','TR01','SL04','TS01', 120000, CONVERT(date,'01/01/2023',103)),
 ('PC11','TR01','SL04','TS02', 140000, CONVERT(date,'01/01/2023',103)),
 ('PC12','TR01','SL04','TS03', 240000, CONVERT(date,'01/01/2023',103)),
 ('PC13','TR01','SL05','TS01', 130000, CONVERT(date,'01/01/2023',103)),
 ('PC14','TR01','SL05','TS02', 150000, CONVERT(date,'01/01/2023',103)),
 ('PC15','TR01','SL05','TS03', 260000, CONVERT(date,'01/01/2023',103)),

 ('PC16','TR02','SL01','TS01', 120000, CONVERT(date,'01/01/2023',103)),
 ('PC17','TR02','SL01','TS02', 140000, CONVERT(date,'01/01/2023',103)),
 ('PC18','TR02','SL01','TS03', 240000, CONVERT(date,'01/01/2023',103)),
 ('PC19','TR02','SL02','TS01', 125000, CONVERT(date,'01/01/2023',103)),
 ('PC20','TR02','SL02','TS02', 145000, CONVERT(date,'01/01/2023',103)),
 ('PC21','TR02','SL02','TS03', 250000, CONVERT(date,'01/01/2023',103)),
 ('PC22','TR02','SL03','TS01', 130000, CONVERT(date,'01/01/2023',103)),
 ('PC23','TR02','SL03','TS02', 150000, CONVERT(date,'01/01/2023',103)),
 ('PC24','TR02','SL03','TS03', 260000, CONVERT(date,'01/01/2023',103)),
 ('PC25','TR02','SL04','TS01', 160000, CONVERT(date,'01/01/2023',103)),
 ('PC26','TR02','SL04','TS02', 180000, CONVERT(date,'01/01/2023',103)),
 ('PC27','TR02','SL04','TS03', 320000, CONVERT(date,'01/01/2023',103)),
 ('PC28','TR02','SL05','TS01', 170000, CONVERT(date,'01/01/2023',103)),
 ('PC29','TR02','SL05','TS02', 190000, CONVERT(date,'01/01/2023',103)),
 ('PC30','TR02','SL05','TS03', 340000, CONVERT(date,'01/01/2023',103)),

 ('PC31','TR03','SL01','TS01', 150000, CONVERT(date,'01/01/2023',103)),
 ('PC32','TR03','SL01','TS02', 170000, CONVERT(date,'01/01/2023',103)),
 ('PC33','TR03','SL01','TS03', 300000, CONVERT(date,'01/01/2023',103)),
 ('PC34','TR03','SL02','TS01', 155000, CONVERT(date,'01/01/2023',103)),
 ('PC35','TR03','SL02','TS02', 175000, CONVERT(date,'01/01/2023',103)),
 ('PC36','TR03','SL02','TS03', 310000, CONVERT(date,'01/01/2023',103)),
 ('PC37','TR03','SL03','TS01', 160000, CONVERT(date,'01/01/2023',103)),
 ('PC38','TR03','SL03','TS02', 180000, CONVERT(date,'01/01/2023',103)),
 ('PC39','TR03','SL03','TS03', 320000, CONVERT(date,'01/01/2023',103)),
 ('PC40','TR03','SL04','TS01', 190000, CONVERT(date,'01/01/2023',103)),
 ('PC41','TR03','SL04','TS02', 210000, CONVERT(date,'01/01/2023',103)),
 ('PC42','TR03','SL04','TS03', 350000, CONVERT(date,'01/01/2023',103)),
 ('PC43','TR03','SL05','TS01', 200000, CONVERT(date,'01/01/2023',103)),
 ('PC44','TR03','SL05','TS02', 220000, CONVERT(date,'01/01/2023',103)),
 ('PC45','TR03','SL05','TS03', 400000, CONVERT(date,'01/01/2023',103));
GO

INSERT INTO dbo.USERS (ID_user, name_user, position, email, pass) VALUES
 ('U01', N'Trần Văn Trí', N'Quản lý', 'tritv@gmail.com', 'password123'),
 ('U02', N'Phạm Mai Linh', N'Thu ngân', 'linhpm@gmail.com', 'password456'),
 ('U03', N'Nguyễn Đức Thắng', N'Thu ngân', 'thangnd@gmail.com', 'password789'),
 ('U04', N'Trịnh Thu Mai',  N'Thu ngân', 'maitt@gmail.com', 'password321'),
 ('U05', N'Nguyễn Thành Trung', N'Quản trị viên hệ thống', 'trungnt@gmail.com', 'password654');
GO

INSERT INTO dbo.PROMOTION (ID_promo, name_promo, type_promo, condition, date_start, date_end, status_promo) 
VALUES
 ('CHRISTMAS2025', N'Christmas Discount', N'Phần trăm', N'Giảm 10% cho tất cả các vé',
  CONVERT(date,'01/11/2025',103), CONVERT(date,'25/12/2025',103), N'Hoạt động'),
 ('NEWYEAR2024',  N'New Year Offer', N'Số lượng', N'Giảm 50,000 VND cho ghế VIP',
  CONVERT(date,'31/12/2024',103), CONVERT(date,'01/01/2025',103), N'Đã dừng'),
 ('SUMMER2025',   N'Summer Sale', N'Combo', N'Mua 2 vé tặng 1 vé',
  CONVERT(date,'01/06/2025',103), CONVERT(date,'01/08/2025',103), N'Đã dừng'),
 ('HALLOWEEN2025',N'Halloween Special', N'Phần trăm', N'Giảm 20% cho các vé phim kinh dị',
  CONVERT(date,'15/10/2025',103), CONVERT(date,'31/10/2025',103), N'Đã dừng'),
 ('BFRIDAY', N'Black Friday Deals', N'Số lượng', N'Giảm 10,0000VND cho tất cả các vé đặt trong thứ 6',
  CONVERT(date,'25/10/2025',103), CONVERT(date,'25/11/2025',103), N'Hoạt động'),
 ('VIPMEM', N'VIP Member Exclusive', N'Phần trăm', N'Giảm 10% cho khách hàng VIP',
  CONVERT(date,'01/06/2025',103), CONVERT(date,'31/12/2025',103), N'Hoạt động'),
 ('FAMILY', N'Family Pack', N'Combo', N'Gói gia đình giảm 15% tổng tiền vé',
  CONVERT(date,'01/01/2025',103), CONVERT(date,'01/01/2026',103), N'Hoạt động'),
 ('SCHOOL2025', N'Back to School Offer', N'Số lượng', N'Giảm 30,000 VND cho khách hàng học sinh, sinh viên',
  CONVERT(date,'01/08/2025',103), CONVERT(date,'31/08/2025',103), N'Đã dừng'),
 ('VALENTINE2025', N'Valentine Day Special', N'Phần trăm', N'Giảm 15% cho các cặp đôi',
  CONVERT(date,'14/02/2025',103), CONVERT(date,'15/02/2025',103), N'Đã dừng'),
 ('WEEKEND', N'Weekend Madness', N'Combo', N'Mua 1 vé tặng 1 bồng ngô size M cho tất cả các vé đặt vào CN',
  CONVERT(date,'15/10/2025',103), CONVERT(date,'30/11/2025',103), N'Hoạt động');
GO

INSERT INTO dbo.PAYMENT (ID_payment, type_payment) VALUES
 ('P101', N'Tiền mặt'),
 ('P102', N'Chuyển khoản'),
 ('P103', N'Thẻ');
GO

INSERT INTO dbo.RECEIPT (ID_receipt, name_client, ID_user, ID_payment, date_created)
VALUES
  (N'RC5493', N'Ngô Đức Long',       'U02', 'P102', CAST('2025-11-07' AS date)),
  (N'RC3756', N'Dương Đức Thịnh',    'U03', 'P103', CAST('2025-11-15' AS date)),
  (N'RC6825', N'Lý Thanh Tâm',       'U03', 'P102', CAST('2025-11-15' AS date)),
  (N'RC6256', N'Châu Bảo Ngọc',      'U03', 'P101', CAST('2025-10-26' AS date)),
  (N'RC6642', N'Lý Thanh Tâm',       'U04', 'P102', CAST('2025-10-26' AS date)),
  (N'RC5390', N'Đinh Quốc Bảo',      'U02', 'P103', CAST('2025-11-04' AS date)),
  (N'RC8835', N'Phan Quốc Huy',      'U02', 'P103', CAST('2025-10-29' AS date)),
  (N'RC3720', N'Đỗ Hải Yến',         'U03', 'P102', CAST('2025-10-29' AS date)),
  (N'RC2383', N'Phạm Thu Hà',        'U04', 'P102', CAST('2025-11-01' AS date)),
  (N'RC8052', N'Kiều Minh Nhật',     'U03', 'P102', CAST('2025-11-03' AS date)),
  (N'RC4749', N'Trương Thùy Dương',  'U02', 'P101', CAST('2025-11-07' AS date)),
  (N'RC8321', N'Tạ Phương Linh',     'U04', 'P102', CAST('2025-11-10' AS date)),
  (N'RC4628', N'Hoàng Thu Trang',    'U03', 'P103', CAST('2025-10-26' AS date)),
  (N'RC4542', N'Dương Đức Thịnh',    'U03', 'P101', CAST('2025-11-04' AS date)),
  (N'RC6071', N'Trần Thị Bích',      'U04', 'P102', CAST('2025-11-04' AS date)),
  (N'RC2659', N'Tạ Phương Linh',     'U02', 'P103', CAST('2025-11-15' AS date)),
  (N'RC1384', N'Châu Bảo Ngọc',      'U04', 'P102', CAST('2025-10-26' AS date)),
  (N'RC4358', N'Phan Quốc Huy',      'U04', 'P102', CAST('2025-10-26' AS date)),
  (N'RC8699', N'Bùi Anh Khoa',       'U03', 'P102', CAST('2025-11-04' AS date)),
  (N'RC5002', N'Đặng Thị Hương',     'U03', 'P103', CAST('2025-11-05' AS date));
GO

INSERT INTO dbo.SHOWTIME_SEAT (ID_showtime, ID_seat)
SELECT st.ID_showtime, s.ID_seat
FROM dbo.SHOWTIME st
JOIN dbo.SEAT s ON s.ID_room = st.ID_room;
GO

INSERT INTO dbo.RECEIPT_DETAILS (ID_detail, ID_receipt, ID_showtime, ID_seat, ID_promo)
VALUES
  ('D0001', 'RC5493', 'SH12', 'S0005', 'BFRIDAY'),
  ('D0002', 'RC3756', 'SH14', 'S0007', 'WEEKEND'),
  ('D0003', 'RC6825', 'SH14', 'S0015', NULL),
  ('D0004', 'RC6256', 'SH01', 'S0010', 'CHRISTMAS2025'),
  ('D0005', 'RC6642', 'SH01', 'S0004', 'VIPMEM'),
  ('D0006', 'RC5390', 'SH04', 'S0004', NULL),
  ('D0007', 'RC8835', 'SH07', 'S0007', NULL),
  ('D0008', 'RC8835', 'SH07', 'S0009', NULL),
  ('D0009', 'RC3720', 'SH07', 'S0005', NULL),
  ('D0010', 'RC3720', 'SH07', 'S0022', NULL),
  ('D0011', 'RC2383', 'SH09', 'S0020', NULL),
  ('D0012', 'RC8052', 'SH10', 'S0016', NULL),
  ('D0013', 'RC8052', 'SH10', 'S0024', NULL),
  ('D0014', 'RC4749', 'SH12', 'S0007', NULL),
  ('D0015', 'RC4749', 'SH12', 'S0009', NULL),
  ('D0016', 'RC8321', 'SH13', 'S0021', NULL),
  ('D0017', 'RC4628', 'SH03', 'S0014', NULL),
  ('D0018', 'RC4628', 'SH03', 'S0025', NULL),
  ('D0019', 'RC4542', 'SH04', 'S0010', NULL),
  ('D0020', 'RC6071', 'SH05', 'S0018', NULL),
  ('D0021', 'RC2659', 'SH14', 'S0009', NULL),
  ('D0022', 'RC2659', 'SH14', 'S0023', NULL),
  ('D0023', 'RC1384', 'SH01', 'S0011', NULL),
  ('D0024', 'RC4358', 'SH02', 'S0008', NULL),
  ('D0025', 'RC8699', 'SH05', 'S0008', NULL),
  ('D0026', 'RC5002', 'SH11', 'S0020', NULL);
  GO

/*----------TRUY VẤN DỮ LIỆU----------*/
-----------1) Lịch chiếu chi tiết trong một ngày (kèm phòng, khung giờ)--------
DECLARE @ngay DATE = '2025-11-20';

SELECT st.ID_showtime, mv.name_movie, st.ID_room, ts.name_time_slot,
       st.date_start, st.time_start, st.time_end
FROM SHOWTIME st
JOIN MOVIE mv     ON mv.ID_movie = st.ID_movie
JOIN TIME_SLOT ts ON ts.ID_time_slot = st.ID_time_slot
WHERE st.date_start = @ngay
ORDER BY st.time_start;
GO

---------2) Danh sách ghế trống của một suất chiếu----------
DECLARE @showtime CHAR(4) = 'SH12';

SELECT s.ID_seat, s.name_seat, s.ID_room, ts.name_type_seat
FROM SHOWTIME_SEAT ss
JOIN SEAT s          ON s.ID_seat = ss.ID_seat
JOIN TYPE_SEAT ts    ON ts.ID_type_seat = s.ID_type_seat
LEFT JOIN RECEIPT_DETAILS rd
       ON rd.ID_showtime = ss.ID_showtime
      AND rd.ID_seat     = ss.ID_seat
WHERE ss.ID_showtime = @showtime
  AND rd.ID_seat IS NULL     -- chưa bán
ORDER BY s.name_seat;
GO

-----------3) Danh sách ghế đã bán của một suất chiếu (kèm số hóa đơn, khuyến mãi)------------
DECLARE @showtime CHAR(4) = 'SH12';

SELECT rd.ID_detail, rd.ID_receipt, r.name_client,
       rd.ID_seat, s.name_seat, rd.ID_promo
FROM RECEIPT_DETAILS rd
JOIN RECEIPT r ON r.ID_receipt = rd.ID_receipt
JOIN SEAT s    ON s.ID_seat    = rd.ID_seat
WHERE rd.ID_showtime = @showtime
ORDER BY rd.ID_detail;
GO

---------4) Giá cơ sở từng dòng vé (không áp khuyến mãi) cho một suất--------------

---view vRECEIPT_DETAILS_BASEPRICE

DECLARE @showtime CHAR(4) = 'SH12';

SELECT v.ID_detail, v.ID_receipt, v.ID_seat, v.base_price
FROM vRECEIPT_DETAILS_BASEPRICE v
WHERE v.ID_showtime = @showtime
ORDER BY v.ID_detail;
GO

-------------5) Doanh thu cơ sở theo hóa đơn--------------
SELECT r.ID_receipt, r.name_client, r.date_created,
       SUM(v.base_price) AS total_money_base
FROM RECEIPT r
JOIN vRECEIPT_DETAILS_BASEPRICE v
  ON v.ID_receipt = r.ID_receipt
GROUP BY r.ID_receipt, r.name_client, r.date_created
ORDER BY r.date_created, r.ID_receipt;

------------6) Doanh thu cơ sở theo phim trong khoảng ngày-----------------
DECLARE @d1 DATE = '2025-11-01', @d2 DATE = '2025-11-30';

SELECT mv.ID_movie, mv.name_movie,
       SUM(v.base_price) AS revenue_base, COUNT(*) AS tickets
FROM vRECEIPT_DETAILS_BASEPRICE v
JOIN SHOWTIME st ON st.ID_showtime = v.ID_showtime
JOIN MOVIE mv    ON mv.ID_movie    = st.ID_movie
JOIN RECEIPT r   ON r.ID_receipt   = v.ID_receipt
WHERE r.date_created >= @d1 AND r.date_created < DATEADD(DAY,1,@d2)
GROUP BY mv.ID_movie, mv.name_movie
ORDER BY revenue_base DESC;
GO

----------7) Top 5 phim bán chạy (theo số vé)--------------
SELECT TOP (5) mv.ID_movie, mv.name_movie, COUNT(*) AS tickets
FROM vRECEIPT_DETAILS_BASEPRICE v
JOIN SHOWTIME st ON st.ID_showtime = v.ID_showtime
JOIN MOVIE mv    ON mv.ID_movie    = st.ID_movie
GROUP BY mv.ID_movie, mv.name_movie
ORDER BY tickets DESC;

----------8) Tỷ lệ lấp đầy theo từng suất chiếu----------
SELECT st.ID_showtime, mv.name_movie, st.ID_room,
       COUNT(ss.ID_seat) AS total_seats_in_showtime,
       SUM(CASE WHEN rd.ID_seat IS NOT NULL THEN 1 ELSE 0 END) AS sold,
       CAST(100.0 * SUM(CASE WHEN rd.ID_seat IS NOT NULL THEN 1 ELSE 0 END) 
                 / NULLIF(COUNT(ss.ID_seat),0) AS DECIMAL(5,2)) AS occupancy_pct
FROM SHOWTIME st
JOIN MOVIE mv        ON mv.ID_movie = st.ID_movie
JOIN SHOWTIME_SEAT ss ON ss.ID_showtime = st.ID_showtime
LEFT JOIN RECEIPT_DETAILS rd
       ON rd.ID_showtime = ss.ID_showtime
      AND rd.ID_seat     = ss.ID_seat
GROUP BY st.ID_showtime, mv.name_movie, st.ID_room
ORDER BY occupancy_pct DESC;
GO

--------------9) Thống kê theo khung giờ (time slot): số vé & doanh thu cơ sở-------------
DECLARE @d1 DATE = '2025-11-01', @d2 DATE = '2025-11-30';

SELECT ts.ID_time_slot, ts.name_time_slot,
       COUNT(v.ID_detail) AS tickets,
       SUM(v.base_price)  AS revenue_base
FROM vRECEIPT_DETAILS_BASEPRICE v
JOIN SHOWTIME st ON st.ID_showtime = v.ID_showtime
JOIN TIME_SLOT ts ON ts.ID_time_slot = st.ID_time_slot
JOIN RECEIPT r ON r.ID_receipt = v.ID_receipt
WHERE r.date_created >= @d1 AND r.date_created < DATEADD(DAY,1,@d2)
GROUP BY ts.ID_time_slot, ts.name_time_slot
ORDER BY revenue_base DESC;
GO

------------10) Năng suất thu ngân (số vé & doanh thu cơ sở theo nhân viên/ngày)--------------
DECLARE @d1 DATE = '2025-11-01', @d2 DATE = '2025-11-30';

SELECT u.ID_user, u.name_user,
       CAST(r.date_created AS DATE) AS sales_date,
       COUNT(v.ID_detail) AS tickets,
       SUM(v.base_price)  AS revenue_base
FROM RECEIPT r
JOIN USERS u  ON u.ID_user = r.ID_user
JOIN vRECEIPT_DETAILS_BASEPRICE v ON v.ID_receipt = r.ID_receipt
WHERE r.date_created >= @d1 AND r.date_created < DATEADD(DAY,1,@d2)
GROUP BY u.ID_user, u.name_user, CAST(r.date_created AS DATE)
ORDER BY u.name_user, sales_date;
GO
