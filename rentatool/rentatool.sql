-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 11, 2025 at 09:33 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `rentatool`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `CalculateUserWeight` (IN `userId` INT, IN `isOwnerReview` BOOLEAN)   BEGIN
    DECLARE tenureDays INT DEFAULT 0;
    DECLARE reputationScore FLOAT DEFAULT 0;
    DECLARE reviewsGiven INT DEFAULT 0;
    DECLARE avgPastRating FLOAT DEFAULT 0;
    DECLARE newRating FLOAT DEFAULT 0;
    DECLARE deviationFactor FLOAT DEFAULT 1;
    DECLARE behaviorFactor FLOAT DEFAULT 1;
    DECLARE reviewWeight FLOAT DEFAULT 0;
    DECLARE finalReviewWeight FLOAT DEFAULT 0;

    -- Calculate tenure in days since user registration
    SELECT DATEDIFF(CURDATE(), RegistrationDate) INTO tenureDays
    FROM User WHERE UserID = userId;

    -- Get current reputation score and number of reviews given
    SELECT ReputationScore, ReviewCount INTO reputationScore, reviewsGiven
    FROM User WHERE UserID = userId;

    -- Calculate average past rating from reviews given by the user
    SELECT AVG(Rating) INTO avgPastRating
    FROM Review
    WHERE ReviewerID = userId;

    -- For simplicity, assume newRating is the latest review rating given by the user
    SELECT Rating INTO newRating
    FROM Review
    WHERE ReviewerID = userId
    ORDER BY ReviewDate DESC
    LIMIT 1;

    -- Calculate deviation factor
    SET deviationFactor = 1 + (ABS(avgPastRating - newRating) / 5);

    -- Determine behavior factor if user is an owner reviewing a borrower
    IF isOwnerReview THEN
        -- For this example, we assume behaviorFactor = 1 (on-time return)
        -- This can be updated based on rental return status in a more complex implementation
        SET behaviorFactor = 1;
    ELSE
        SET behaviorFactor = 1;
    END IF;

    -- Calculate review weight
    SET reviewWeight = LOG(10, tenureDays + 1) * (5 / NULLIF(reputationScore, 0)) * LOG(10, reviewsGiven + 1) * deviationFactor;

    -- Calculate final review weight
    SET finalReviewWeight = reviewWeight * behaviorFactor;

    -- Update User table with new weighted reputation score (example)
    UPDATE User
    SET ReputationScore = finalReviewWeight
    WHERE UserID = userId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SetPrimaryPhoto` (IN `p_ToolID` INT, IN `p_PhotoID` INT)   BEGIN
    UPDATE ToolPhoto 
    SET IsPrimary = FALSE 
    WHERE ToolID = p_ToolID;
    
    UPDATE ToolPhoto 
    SET IsPrimary = TRUE 
    WHERE PhotoID = p_PhotoID AND ToolID = p_ToolID;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `notification`
--

CREATE TABLE `notification` (
  `NotificationID` int(11) NOT NULL,
  `UserID` int(11) NOT NULL,
  `Message` text NOT NULL,
  `IsRead` tinyint(1) DEFAULT 0,
  `NotificationTimestamp` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `notification`
--

INSERT INTO `notification` (`NotificationID`, `UserID`, `Message`, `IsRead`, `NotificationTimestamp`) VALUES
(1, 3, 'New rental request for your tool: Power Drill', 0, '2025-04-23 18:05:06'),
(2, 3, 'New rental request for your tool: Sander', 0, '2025-04-23 18:13:46'),
(3, 3, 'New rental request for your tool: Sander', 0, '2025-04-23 18:18:06'),
(4, 3, 'New rental request for your tool: Circular Saw', 0, '2025-04-23 18:20:43'),
(5, 3, 'New rental request for your tool: Sander', 0, '2025-04-23 20:14:58'),
(6, 3, 'New rental request for your tool: Sander', 0, '2025-04-23 20:26:24'),
(7, 3, 'New rental request for your tool: Sander', 0, '2025-04-23 22:24:32'),
(8, 3, 'New rental request for your tool: Sander', 0, '2025-04-23 22:35:17'),
(9, 3, 'New rental request for your tool: Sander', 0, '2025-04-23 22:39:35'),
(10, 3, 'New rental request for your tool: Sander', 0, '2025-04-23 22:44:54'),
(11, 3, 'New rental request for your tool: Sander', 0, '2025-04-23 22:45:10'),
(12, 3, 'New rental request for your tool: Sander', 0, '2025-04-23 23:01:57'),
(13, 3, 'New rental request for your tool: Sander', 0, '2025-04-23 23:03:03'),
(14, 3, 'New rental request for your tool: Sander', 0, '2025-04-23 23:08:37'),
(15, 3, 'New rental request for your tool: Sander', 1, '2025-04-23 23:10:10'),
(16, 3, 'New rental request for your tool: Sander', 1, '2025-04-23 23:10:48'),
(17, 3, 'New rental request for your tool: Sander', 1, '2025-04-23 23:11:45'),
(18, 3, 'New rental request for your tool: Sander', 1, '2025-04-23 23:11:54'),
(19, 3, 'New rental request for your tool: Sander', 1, '2025-04-23 23:13:19'),
(20, 3, 'New rental request for your tool: Sander', 1, '2025-04-23 23:32:12'),
(21, 3, 'New rental request for your tool: bit', 1, '2025-04-24 12:42:14'),
(22, 3, 'New rental request for your tool: bit', 1, '2025-04-24 14:00:15'),
(23, 17, 'Payment completed for rental of tool \'Sander\'.', 0, '2025-04-24 14:14:43'),
(24, 3, 'Rental payment received for your tool \'Sander\'.', 1, '2025-04-24 14:14:43'),
(25, 17, 'Payment completed for rental of tool \'bit\'.', 0, '2025-04-24 15:35:45'),
(26, 3, 'Rental payment received for your tool \'bit\'.', 1, '2025-04-24 15:35:45'),
(27, 17, 'Payment completed for rental of tool \'bit\'.', 0, '2025-04-24 15:36:00'),
(28, 3, 'Rental payment received for your tool \'bit\'.', 1, '2025-04-24 15:36:00'),
(29, 17, 'Payment completed for rental of tool \'Sander\'.', 0, '2025-04-24 15:36:19'),
(30, 3, 'Rental payment received for your tool \'Sander\'.', 1, '2025-04-24 15:36:19'),
(31, 3, 'New rental request for your tool: bit', 1, '2025-04-24 16:04:40'),
(32, 17, 'Payment completed for rental of tool \'bit\'.', 0, '2025-04-24 16:05:54'),
(33, 3, 'Rental payment received for your tool \'bit\'.', 1, '2025-04-24 16:05:54'),
(34, 17, 'Payment completed for rental of tool \'bit\'.', 0, '2025-04-24 16:08:19'),
(35, 3, 'Rental payment received for your tool \'bit\'.', 1, '2025-04-24 16:08:19'),
(36, 3, 'New rental request for your tool: bit', 1, '2025-04-24 16:09:37'),
(37, 17, 'Payment completed for rental of tool \'bit\'.', 0, '2025-04-24 16:10:47'),
(38, 3, 'Rental payment received for your tool \'bit\'.', 1, '2025-04-24 16:10:47'),
(39, 17, 'Payment completed for rental of tool \'bit\'.', 0, '2025-04-24 16:12:12'),
(40, 3, 'Rental payment received for your tool \'bit\'.', 0, '2025-04-24 16:12:12'),
(41, 3, 'New rental request for your tool: cat', 0, '2025-04-24 16:23:08'),
(42, 17, 'Payment completed for rental of tool \'cat\'.', 0, '2025-04-24 16:24:17'),
(43, 3, 'Rental payment received for your tool \'cat\'.', 0, '2025-04-24 16:24:17'),
(44, 17, 'Payment completed for rental of tool \'cat\'.', 0, '2025-04-24 16:30:04'),
(45, 3, 'Rental payment received for your tool \'cat\'.', 0, '2025-04-24 16:30:04'),
(46, 3, 'New rental request for your tool: cat', 0, '2025-04-24 16:32:27'),
(47, 17, 'Payment completed for rental of tool \'cat\'.', 0, '2025-04-24 16:33:00'),
(48, 3, 'Rental payment received for your tool \'cat\'.', 1, '2025-04-24 16:33:00'),
(49, 3, 'New rental request for your tool: cat', 0, '2025-04-24 16:49:39'),
(50, 17, 'Payment completed for rental of tool \'cat\'.', 0, '2025-04-24 16:51:06'),
(51, 3, 'Rental payment received for your tool \'cat\'.', 0, '2025-04-24 16:51:06'),
(52, 3, 'New rental request for your tool: cat', 0, '2025-04-24 17:08:56'),
(53, 17, 'Payment completed for rental of tool \'cat\'.', 0, '2025-04-24 17:10:28'),
(54, 3, 'Rental payment received for your tool \'cat\'.', 1, '2025-04-24 17:10:28'),
(55, 3, 'New rental request for your tool: cat', 0, '2025-04-24 21:51:43'),
(56, 3, 'New rental request for your tool: cat', 0, '2025-04-24 21:52:25'),
(57, 17, 'Payment completed for rental of tool \'cat\'.', 0, '2025-04-24 21:53:25'),
(58, 3, 'Rental payment received for your tool \'cat\'.', 0, '2025-04-24 21:53:25'),
(59, 17, 'Payment completed for rental of tool \'cat\'.', 0, '2025-04-24 21:55:42'),
(60, 3, 'Rental payment received for your tool \'cat\'.', 0, '2025-04-24 21:55:42'),
(61, 3, 'New rental request for your tool: cat', 0, '2025-04-25 00:00:57'),
(62, 3, 'New rental request for your tool: cat', 0, '2025-04-25 00:01:41'),
(63, 17, 'Payment completed for rental of tool \'cat\'.', 0, '2025-04-25 00:02:26'),
(64, 3, 'Rental payment received for your tool \'cat\'.', 0, '2025-04-25 00:02:26'),
(65, 17, 'Payment completed for rental of tool \'cat\'.', 0, '2025-04-25 00:03:48'),
(66, 3, 'Rental payment received for your tool \'cat\'.', 0, '2025-04-25 00:03:48'),
(67, 3, 'New rental request for your tool: cat', 0, '2025-04-25 00:05:07'),
(68, 17, 'Payment completed for rental of tool \'cat\'.', 0, '2025-04-25 00:06:01'),
(69, 3, 'Rental payment received for your tool \'cat\'.', 0, '2025-04-25 00:06:01'),
(70, 3, 'New rental request for your tool: cat', 0, '2025-04-25 00:06:58'),
(71, 17, 'Payment completed for rental of tool \'cat\'.', 0, '2025-04-25 00:08:11'),
(72, 3, 'Rental payment received for your tool \'cat\'.', 0, '2025-04-25 00:08:11'),
(73, 3, 'New rental request for your tool: cat', 0, '2025-04-25 00:10:32'),
(74, 17, 'Payment completed for rental of tool \'cat\'.', 0, '2025-04-25 00:12:04'),
(75, 3, 'Rental payment received for your tool \'cat\'.', 0, '2025-04-25 00:12:04'),
(76, 3, 'New rental request for your tool: cat', 0, '2025-04-26 23:05:42'),
(77, 17, 'Payment completed for rental of tool \'cat\'.', 0, '2025-04-26 23:06:29'),
(78, 3, 'Rental payment received for your tool \'cat\'.', 0, '2025-04-26 23:06:29'),
(79, 3, 'New rental request for your tool: cat', 0, '2025-04-26 23:09:45'),
(80, 17, 'Payment completed for rental of tool \'cat\'.', 0, '2025-04-26 23:10:21'),
(81, 3, 'Rental payment received for your tool \'cat\'.', 0, '2025-04-26 23:10:21'),
(82, 3, 'New rental request for your tool: cat', 0, '2025-05-03 09:44:57'),
(83, 3, 'New rental request for your tool: cat', 0, '2025-05-03 11:51:51'),
(84, 3, 'New rental request for your tool: cat', 0, '2025-05-03 12:15:47'),
(85, 3, 'New rental request for your tool: cat', 0, '2025-05-03 12:42:45'),
(86, 3, 'New rental request for your tool: cat', 0, '2025-05-03 14:02:02'),
(87, 3, 'New rental request for your tool: cat', 0, '2025-05-03 14:02:59'),
(88, 3, 'New rental request for your tool: router', 0, '2025-05-03 14:25:03'),
(89, 3, 'New rental request for your tool: router', 0, '2025-05-03 14:59:39'),
(90, 3, 'New rental request for your tool: router', 0, '2025-05-03 15:31:17'),
(91, 16, 'Payment completed for rental of tool \'router\'.', 0, '2025-05-03 15:34:32'),
(92, 3, 'Rental payment received for your tool \'router\'.', 0, '2025-05-03 15:34:32'),
(93, 3, 'New rental request for your tool: router', 0, '2025-05-03 15:44:14'),
(94, 16, 'Payment completed for rental of tool \'router\'.', 0, '2025-05-03 15:46:21'),
(95, 3, 'Rental payment received for your tool \'router\'.', 0, '2025-05-03 15:46:21'),
(96, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-03 16:24:52'),
(97, 6, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-03 16:25:27'),
(98, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-03 16:25:27'),
(99, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-03 16:37:29'),
(100, 6, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-03 16:38:08'),
(101, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-03 16:38:08'),
(102, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-03 17:03:12'),
(103, 6, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-03 17:06:07'),
(104, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-03 17:06:07'),
(105, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-03 17:16:09'),
(106, 6, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-03 17:16:51'),
(107, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-03 17:16:51'),
(108, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-03 19:04:53'),
(109, 6, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-03 19:05:41'),
(110, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-03 19:05:41'),
(111, 3, 'New rental request for your tool: hammer', 0, '2025-05-03 19:21:25'),
(112, 6, 'Payment completed for rental of tool \'hammer\'.', 0, '2025-05-03 19:22:02'),
(113, 3, 'Rental payment received for your tool \'hammer\'.', 0, '2025-05-03 19:22:02'),
(114, 3, 'New rental request for your tool: Sander', 0, '2025-05-03 23:51:41'),
(115, 17, 'Payment completed for rental of tool \'Sander\'.', 0, '2025-05-03 23:52:37'),
(116, 3, 'Rental payment received for your tool \'Sander\'.', 0, '2025-05-03 23:52:37'),
(117, 3, 'New rental request for your tool: cat', 0, '2025-05-03 23:54:54'),
(118, 16, 'Payment completed for rental of tool \'cat\'.', 0, '2025-05-03 23:56:37'),
(119, 3, 'Rental payment received for your tool \'cat\'.', 0, '2025-05-03 23:56:37'),
(120, 3, 'New rental request for your tool: Circular Saw', 0, '2025-05-04 17:50:23'),
(121, 8, 'New rental request for your tool: Nail Gun', 0, '2025-05-04 17:50:57'),
(122, 17, 'Payment completed for rental of tool \'Circular Saw\'.', 0, '2025-05-04 17:52:50'),
(123, 3, 'Rental payment received for your tool \'Circular Saw\'.', 0, '2025-05-04 17:52:50'),
(124, 17, 'Payment completed for rental of tool \'Nail Gun\'.', 0, '2025-05-04 17:52:59'),
(125, 8, 'Rental payment received for your tool \'Nail Gun\'.', 0, '2025-05-04 17:52:59'),
(126, 8, 'New rental request for your tool: Nail Gun', 0, '2025-05-04 18:18:55'),
(127, 17, 'Payment completed for rental of tool \'Nail Gun\'.', 0, '2025-05-04 18:20:01'),
(128, 8, 'Rental payment received for your tool \'Nail Gun\'.', 0, '2025-05-04 18:20:01'),
(129, 8, 'New rental request for your tool: Nail Gun', 0, '2025-05-04 19:19:58'),
(130, 17, 'Payment completed for rental of tool \'Nail Gun\'.', 0, '2025-05-04 19:21:10'),
(131, 8, 'Rental payment received for your tool \'Nail Gun\'.', 0, '2025-05-04 19:21:10'),
(132, 8, 'New rental request for your tool: Cordless Screwdriver', 0, '2025-05-04 19:36:58'),
(133, 17, 'Payment completed for rental of tool \'Cordless Screwdriver\'.', 0, '2025-05-04 19:37:42'),
(134, 8, 'Rental payment received for your tool \'Cordless Screwdriver\'.', 0, '2025-05-04 19:37:42'),
(135, 8, 'New rental request for your tool: Cordless Screwdriver', 0, '2025-05-04 19:47:54'),
(136, 17, 'Payment completed for rental of tool \'Cordless Screwdriver\'.', 0, '2025-05-04 19:48:21'),
(137, 8, 'Rental payment received for your tool \'Cordless Screwdriver\'.', 0, '2025-05-04 19:48:21'),
(138, 8, 'New rental request for your tool: Cordless Screwdriver', 0, '2025-05-04 19:59:48'),
(139, 17, 'Payment completed for rental of tool \'Cordless Screwdriver\'.', 0, '2025-05-04 20:01:01'),
(140, 8, 'Rental payment received for your tool \'Cordless Screwdriver\'.', 0, '2025-05-04 20:01:01'),
(141, 8, 'New rental request for your tool: Cordless Screwdriver', 0, '2025-05-04 20:12:09'),
(142, 17, 'Payment completed for rental of tool \'Cordless Screwdriver\'.', 0, '2025-05-04 20:12:34'),
(143, 8, 'Rental payment received for your tool \'Cordless Screwdriver\'.', 0, '2025-05-04 20:12:34'),
(144, 8, 'New rental request for your tool: Cordless Screwdriver', 0, '2025-05-04 20:44:27'),
(145, 17, 'Payment completed for rental of tool \'Cordless Screwdriver\'.', 0, '2025-05-04 20:45:00'),
(146, 8, 'Rental payment received for your tool \'Cordless Screwdriver\'.', 0, '2025-05-04 20:45:00'),
(147, 8, 'New rental request for your tool: Cordless Screwdriver', 0, '2025-05-04 20:55:52'),
(148, 17, 'Payment completed for rental of tool \'Cordless Screwdriver\'.', 0, '2025-05-04 20:56:38'),
(149, 8, 'Rental payment received for your tool \'Cordless Screwdriver\'.', 0, '2025-05-04 20:56:38'),
(150, 8, 'New rental request for your tool: Cordless Screwdriver', 0, '2025-05-04 21:13:14'),
(151, 17, 'Payment completed for rental of tool \'Cordless Screwdriver\'.', 0, '2025-05-04 21:13:40'),
(152, 8, 'Rental payment received for your tool \'Cordless Screwdriver\'.', 0, '2025-05-04 21:13:40'),
(153, 8, 'New rental request for your tool: Cordless Screwdriver', 0, '2025-05-04 21:22:02'),
(154, 17, 'Payment completed for rental of tool \'Cordless Screwdriver\'.', 0, '2025-05-04 21:22:39'),
(155, 8, 'Rental payment received for your tool \'Cordless Screwdriver\'.', 0, '2025-05-04 21:22:39'),
(156, 8, 'New rental request for your tool: Nail Gun', 0, '2025-05-05 00:41:09'),
(157, 17, 'Payment completed for rental of tool \'Nail Gun\'.', 0, '2025-05-05 00:41:54'),
(158, 8, 'Rental payment received for your tool \'Nail Gun\'.', 0, '2025-05-05 00:41:54'),
(159, 8, 'New rental request for your tool: Nail Gun', 0, '2025-05-05 00:52:41'),
(160, 17, 'Payment completed for rental of tool \'Nail Gun\'.', 0, '2025-05-05 00:53:04'),
(161, 8, 'Rental payment received for your tool \'Nail Gun\'.', 0, '2025-05-05 00:53:04'),
(162, 8, 'New rental request for your tool: Nail Gun', 0, '2025-05-05 02:31:20'),
(163, 17, 'Payment completed for rental of tool \'Nail Gun\'.', 0, '2025-05-05 02:31:56'),
(164, 8, 'Rental payment received for your tool \'Nail Gun\'.', 0, '2025-05-05 02:31:56'),
(165, 8, 'New rental request for your tool: Nail Gun', 0, '2025-05-05 02:43:58'),
(166, 17, 'Payment completed for rental of tool \'Nail Gun\'.', 0, '2025-05-05 02:44:25'),
(167, 8, 'Rental payment received for your tool \'Nail Gun\'.', 0, '2025-05-05 02:44:25'),
(168, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 13:12:59'),
(169, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-05 13:13:31'),
(170, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-05 13:13:31'),
(171, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 13:27:45'),
(172, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-05 13:28:20'),
(173, 3, 'Rental payment received for your tool \'Power Drill\'.', 1, '2025-05-05 13:28:20'),
(174, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 13:32:18'),
(175, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-05 13:32:40'),
(176, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-05 13:32:40'),
(177, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 13:49:45'),
(178, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-05 13:50:23'),
(179, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-05 13:50:23'),
(180, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 15:14:22'),
(181, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-05 15:14:58'),
(182, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-05 15:14:58'),
(183, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 15:41:58'),
(184, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-05 15:42:58'),
(185, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-05 15:42:58'),
(186, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 15:56:28'),
(187, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 16:07:32'),
(188, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-05 16:07:58'),
(189, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-05 16:07:58'),
(190, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 16:16:59'),
(191, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-05 16:18:53'),
(192, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-05 16:18:53'),
(193, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 16:27:40'),
(194, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-05 16:28:26'),
(195, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-05 16:28:26'),
(196, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 16:37:35'),
(197, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-05 16:38:02'),
(198, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-05 16:38:02'),
(199, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 18:07:47'),
(200, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-05 18:08:10'),
(201, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-05 18:08:10'),
(202, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 18:24:09'),
(203, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-05 18:24:33'),
(204, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-05 18:24:33'),
(205, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 18:50:34'),
(206, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-05 18:50:55'),
(207, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-05 18:50:55'),
(208, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 19:28:07'),
(209, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-05 19:28:43'),
(210, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-05 19:28:43'),
(211, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 19:56:04'),
(212, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-05 19:56:52'),
(213, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-05 19:56:52'),
(214, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 20:13:24'),
(215, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-05 20:14:04'),
(216, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-05 20:14:04'),
(217, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 21:00:08'),
(218, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-05 21:00:41'),
(219, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-05 21:00:41'),
(220, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 21:16:38'),
(221, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-05 21:17:03'),
(222, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-05 21:17:03'),
(223, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 21:24:37'),
(224, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-05 21:25:08'),
(225, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-05 21:25:08'),
(226, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 21:39:55'),
(227, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-05 21:40:34'),
(228, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-05 21:40:34'),
(229, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-05 21:54:38'),
(230, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-05 21:54:59'),
(231, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-05 21:54:59'),
(232, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-06 01:12:11'),
(233, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-06 01:12:37'),
(234, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-06 01:12:37'),
(235, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-06 01:40:20'),
(236, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-06 01:41:09'),
(237, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-06 01:41:09'),
(238, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-06 02:54:07'),
(239, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-06 02:54:56'),
(240, 3, 'Rental payment received for your tool \'Power Drill\'.', 0, '2025-05-06 02:54:56'),
(241, 3, 'New rental request for your tool: Power Drill', 0, '2025-05-06 09:28:03'),
(242, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-06 09:28:29'),
(243, 3, 'Rental payment received for your tool \'Power Drill\'.', 1, '2025-05-06 09:28:29'),
(244, 3, 'New rental request for your tool: Power Drill', 1, '2025-05-06 09:39:31'),
(245, 3, 'New rental request for your tool: Power Drill', 1, '2025-05-06 09:39:46'),
(246, 3, 'New rental request for your tool: Power Drill', 1, '2025-05-06 09:40:06'),
(247, 3, 'New rental request for your tool: Power Drill', 1, '2025-05-06 09:40:23'),
(248, 3, 'New rental request for your tool: Power Drill', 1, '2025-05-06 09:40:39'),
(249, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-06 09:41:26'),
(250, 3, 'Rental payment received for your tool \'Power Drill\'.', 1, '2025-05-06 09:41:26'),
(251, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-06 09:41:35'),
(252, 3, 'Rental payment received for your tool \'Power Drill\'.', 1, '2025-05-06 09:41:35'),
(253, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-06 09:41:45'),
(254, 3, 'Rental payment received for your tool \'Power Drill\'.', 1, '2025-05-06 09:41:45'),
(255, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-06 09:41:53'),
(256, 3, 'Rental payment received for your tool \'Power Drill\'.', 1, '2025-05-06 09:41:53'),
(257, 16, 'Payment completed for rental of tool \'Power Drill\'.', 0, '2025-05-06 09:42:03'),
(258, 3, 'Rental payment received for your tool \'Power Drill\'.', 1, '2025-05-06 09:42:03'),
(259, 8, 'New rental request for your tool: Cordless Screwdriver', 0, '2025-05-06 18:03:10'),
(260, 17, 'Payment completed for rental of tool \'Cordless Screwdriver\'.', 0, '2025-05-06 18:04:01'),
(261, 8, 'Rental payment received for your tool \'Cordless Screwdriver\'.', 0, '2025-05-06 18:04:01'),
(262, 8, 'New rental request for your tool: Cordless Screwdriver', 0, '2025-05-06 21:51:46'),
(263, 8, 'New rental request for your tool: Cordless Screwdriver', 0, '2025-05-06 21:51:56'),
(264, 8, 'New rental request for your tool: Cordless Screwdriver', 0, '2025-05-06 21:52:04'),
(265, 8, 'New rental request for your tool: Cordless Screwdriver', 0, '2025-05-06 21:52:12'),
(266, 8, 'New rental request for your tool: Cordless Screwdriver', 0, '2025-05-06 21:53:38'),
(267, 8, 'New rental request for your tool: Cordless Screwdriver', 0, '2025-05-06 21:53:50'),
(268, 16, 'Payment completed for rental of tool \'Cordless Screwdriver\'.', 0, '2025-05-06 21:54:52'),
(269, 8, 'Rental payment received for your tool \'Cordless Screwdriver\'.', 0, '2025-05-06 21:54:52'),
(270, 16, 'Payment completed for rental of tool \'Cordless Screwdriver\'.', 0, '2025-05-06 21:55:07'),
(271, 8, 'Rental payment received for your tool \'Cordless Screwdriver\'.', 0, '2025-05-06 21:55:07'),
(272, 16, 'Payment completed for rental of tool \'Cordless Screwdriver\'.', 0, '2025-05-06 21:55:21'),
(273, 8, 'Rental payment received for your tool \'Cordless Screwdriver\'.', 0, '2025-05-06 21:55:21'),
(274, 16, 'Payment completed for rental of tool \'Cordless Screwdriver\'.', 0, '2025-05-06 21:56:35'),
(275, 8, 'Rental payment received for your tool \'Cordless Screwdriver\'.', 0, '2025-05-06 21:56:35'),
(276, 16, 'Payment completed for rental of tool \'Cordless Screwdriver\'.', 0, '2025-05-06 21:56:47'),
(277, 8, 'Rental payment received for your tool \'Cordless Screwdriver\'.', 0, '2025-05-06 21:56:47'),
(278, 16, 'Payment completed for rental of tool \'Cordless Screwdriver\'.', 0, '2025-05-06 21:57:04'),
(279, 8, 'Rental payment received for your tool \'Cordless Screwdriver\'.', 0, '2025-05-06 21:57:04'),
(280, 3, 'New rental request for your tool: tiller', 1, '2025-05-09 12:28:00'),
(281, 16, 'Payment completed for rental of tool \'tiller\'.', 0, '2025-05-09 12:29:07'),
(282, 3, 'Rental payment received for your tool \'tiller\'.', 1, '2025-05-09 12:29:07'),
(283, 3, 'New rental request for your tool: tiller', 1, '2025-05-09 23:45:00'),
(284, 3, 'New rental request for your tool: tiller', 1, '2025-05-09 23:45:35'),
(285, 16, 'Payment completed for rental of tool \'tiller\'.', 0, '2025-05-10 00:26:39'),
(286, 3, 'Rental payment received for your tool \'tiller\'.', 0, '2025-05-10 00:26:39'),
(287, 16, 'Payment completed for rental of tool \'tiller\'.', 0, '2025-05-10 00:26:52'),
(288, 3, 'Rental payment received for your tool \'tiller\'.', 0, '2025-05-10 00:26:52'),
(289, 3, 'New rental request for your tool: tiller', 0, '2025-05-10 00:28:55'),
(290, 3, 'New rental request for your tool: tiller', 0, '2025-05-10 00:34:24'),
(291, 3, 'New rental request for your tool: tiller', 0, '2025-05-10 00:42:14'),
(292, 3, 'New rental request for your tool: tiller', 0, '2025-05-10 00:44:42'),
(293, 3, 'New rental request for your tool: tiller', 0, '2025-05-10 00:49:15'),
(294, 3, 'New rental request for your tool: tiller', 0, '2025-05-10 00:52:05'),
(295, 4, 'New rental request for your tool: Tape Measure', 0, '2025-05-10 23:08:51'),
(296, 20, 'Payment completed for rental of tool \'Tape Measure\'.', 0, '2025-05-10 23:09:59'),
(297, 4, 'Rental payment received for your tool \'Tape Measure\'.', 0, '2025-05-10 23:09:59'),
(298, 3, 'New rental request for your tool: cat', 0, '2025-05-11 13:59:24'),
(299, 3, 'New rental request for your tool: cat', 0, '2025-05-11 14:00:27'),
(300, 20, 'Payment completed for rental of tool \'cat\'.', 0, '2025-05-11 14:15:54'),
(301, 3, 'Rental payment received for your tool \'cat\'.', 0, '2025-05-11 14:15:54'),
(302, 20, 'Payment completed for rental of tool \'cat\'.', 0, '2025-05-11 14:16:05'),
(303, 3, 'Rental payment received for your tool \'cat\'.', 0, '2025-05-11 14:16:05'),
(304, 20, 'Payment completed for rental of tool \'cat\'.', 0, '2025-05-11 14:16:15'),
(305, 3, 'Rental payment received for your tool \'cat\'.', 0, '2025-05-11 14:16:15'),
(306, 20, 'Payment completed for rental of tool \'cat\'.', 0, '2025-05-11 14:19:25'),
(307, 3, 'Rental payment received for your tool \'cat\'.', 0, '2025-05-11 14:19:25');

-- --------------------------------------------------------

--
-- Table structure for table `passwordresettokens`
--

CREATE TABLE `passwordresettokens` (
  `Token` varchar(64) NOT NULL,
  `UserID` int(11) NOT NULL,
  `ExpiryDate` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `passwordresettokens`
--

INSERT INTO `passwordresettokens` (`Token`, `UserID`, `ExpiryDate`) VALUES
('6555d9b23d9d13c619fb7b90512bb732a301e616e782a0c03b57a672ad0e6047', 19, '2025-05-10 10:26:29');

-- --------------------------------------------------------

--
-- Table structure for table `payment`
--

CREATE TABLE `payment` (
  `PaymentID` int(11) NOT NULL,
  `RentalID` int(11) NOT NULL,
  `PaymentAmount` decimal(10,2) NOT NULL,
  `PaymentDate` datetime DEFAULT current_timestamp(),
  `PaymentStatus` enum('Completed','Failed','Pending') DEFAULT 'Pending'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `payment`
--

INSERT INTO `payment` (`PaymentID`, `RentalID`, `PaymentAmount`, `PaymentDate`, `PaymentStatus`) VALUES
(1, 1, 48.00, '2025-04-23 18:05:06', 'Pending'),
(2, 2, 38.40, '2025-04-23 18:13:46', 'Pending'),
(3, 3, 38.40, '2025-04-23 18:18:06', 'Pending'),
(4, 4, 70.40, '2025-04-23 18:20:43', 'Pending'),
(5, 5, 76.80, '2025-04-23 20:14:58', 'Pending'),
(6, 6, 38.40, '2025-04-23 20:26:24', 'Pending'),
(7, 7, 38.40, '2025-04-23 22:24:32', 'Pending'),
(8, 8, 38.40, '2025-04-24 14:14:43', 'Completed'),
(9, 9, 38.40, '2025-04-23 22:39:35', 'Pending'),
(10, 10, 38.40, '2025-04-24 15:36:19', 'Completed'),
(11, 11, 76.80, '2025-04-23 22:45:10', 'Pending'),
(12, 12, 76.80, '2025-04-23 23:01:57', 'Pending'),
(13, 13, 76.80, '2025-04-23 23:03:03', 'Pending'),
(14, 14, 76.80, '2025-04-23 23:08:37', 'Pending'),
(15, 15, 76.80, '2025-04-23 23:10:10', 'Pending'),
(16, 16, 76.80, '2025-04-23 23:10:48', 'Pending'),
(17, 17, 76.80, '2025-04-23 23:11:45', 'Pending'),
(18, 18, 76.80, '2025-04-23 23:11:54', 'Pending'),
(19, 19, 76.80, '2025-04-23 23:13:19', 'Pending'),
(20, 20, 76.80, '2025-04-23 23:32:12', 'Pending'),
(21, 21, 1600.00, '2025-04-24 16:12:12', 'Completed'),
(22, 22, 1600.00, '2025-04-24 14:00:15', 'Pending'),
(23, 23, 1600.00, '2025-04-24 16:05:54', 'Completed'),
(24, 24, 1600.00, '2025-04-24 16:09:37', 'Pending'),
(25, 25, 640.00, '2025-04-24 16:30:04', 'Completed'),
(26, 26, 640.00, '2025-04-24 16:33:00', 'Completed'),
(27, 27, 640.00, '2025-04-24 16:51:06', 'Completed'),
(28, 28, 640.00, '2025-04-24 17:10:28', 'Completed'),
(29, 29, 640.00, '2025-04-24 21:53:25', 'Completed'),
(30, 30, 640.00, '2025-04-24 21:55:42', 'Completed'),
(31, 31, 320.00, '2025-04-25 00:02:26', 'Completed'),
(32, 32, 320.00, '2025-04-25 00:03:48', 'Completed'),
(33, 33, 320.00, '2025-04-25 00:06:01', 'Completed'),
(34, 34, 640.00, '2025-04-25 00:08:11', 'Completed'),
(35, 35, 320.00, '2025-04-25 00:12:04', 'Completed'),
(36, 36, 640.00, '2025-04-26 23:06:29', 'Completed'),
(37, 37, 960.00, '2025-04-26 23:10:21', 'Completed'),
(38, 38, 1280.00, '2025-05-03 09:44:57', 'Pending'),
(39, 39, 960.00, '2025-05-03 11:51:51', 'Pending'),
(40, 40, 640.00, '2025-05-03 12:15:47', 'Pending'),
(41, 41, 640.00, '2025-05-03 12:42:45', 'Pending'),
(42, 42, 640.00, '2025-05-03 14:02:02', 'Pending'),
(43, 43, 640.00, '2025-05-03 14:02:59', 'Pending'),
(44, 44, 2880.00, '2025-05-03 14:25:03', 'Pending'),
(45, 45, 1920.00, '2025-05-03 14:59:39', 'Pending'),
(46, 46, 1920.00, '2025-05-03 15:34:32', 'Completed'),
(47, 47, 1920.00, '2025-05-03 15:46:21', 'Completed'),
(48, 48, 48.00, '2025-05-03 16:25:27', 'Completed'),
(49, 49, 48.00, '2025-05-03 16:38:08', 'Completed'),
(50, 50, 48.00, '2025-05-03 17:06:07', 'Completed'),
(51, 51, 48.00, '2025-05-03 17:16:51', 'Completed'),
(52, 52, 72.00, '2025-05-03 19:05:41', 'Completed'),
(53, 53, 2400.00, '2025-05-03 19:22:02', 'Completed'),
(54, 54, 38.40, '2025-05-03 23:52:37', 'Completed'),
(55, 55, 640.00, '2025-05-03 23:56:37', 'Completed'),
(56, 56, 70.40, '2025-05-04 17:52:50', 'Completed'),
(57, 57, 80.00, '2025-05-04 17:52:59', 'Completed'),
(58, 58, 40.00, '2025-05-04 18:20:01', 'Completed'),
(59, 59, 80.00, '2025-05-04 19:21:10', 'Completed'),
(60, 60, 41.60, '2025-05-04 19:37:42', 'Completed'),
(61, 61, 41.60, '2025-05-04 19:48:21', 'Completed'),
(62, 62, 41.60, '2025-05-04 20:01:01', 'Completed'),
(63, 63, 41.60, '2025-05-04 20:12:34', 'Completed'),
(64, 64, 41.60, '2025-05-04 20:45:00', 'Completed'),
(65, 65, 41.60, '2025-05-04 20:56:38', 'Completed'),
(66, 66, 41.60, '2025-05-04 21:13:40', 'Completed'),
(67, 67, 41.60, '2025-05-04 21:22:39', 'Completed'),
(68, 68, 80.00, '2025-05-05 00:41:54', 'Completed'),
(69, 69, 80.00, '2025-05-05 00:53:04', 'Completed'),
(70, 70, 80.00, '2025-05-05 02:31:56', 'Completed'),
(71, 71, 80.00, '2025-05-05 02:44:25', 'Completed'),
(72, 72, 48.00, '2025-05-05 13:13:31', 'Completed'),
(73, 73, 48.00, '2025-05-05 13:28:20', 'Completed'),
(74, 74, 48.00, '2025-05-05 13:32:40', 'Completed'),
(75, 75, 48.00, '2025-05-05 13:50:23', 'Completed'),
(76, 76, 48.00, '2025-05-05 15:14:58', 'Completed'),
(77, 77, 48.00, '2025-05-05 15:42:58', 'Completed'),
(78, 78, 48.00, '2025-05-05 15:56:28', 'Pending'),
(79, 79, 48.00, '2025-05-05 16:07:58', 'Completed'),
(80, 80, 48.00, '2025-05-05 16:18:53', 'Completed'),
(81, 81, 48.00, '2025-05-05 16:28:26', 'Completed'),
(82, 82, 48.00, '2025-05-05 16:38:02', 'Completed'),
(83, 83, 48.00, '2025-05-05 18:08:10', 'Completed'),
(84, 84, 48.00, '2025-05-05 18:24:33', 'Completed'),
(85, 85, 48.00, '2025-05-05 18:50:55', 'Completed'),
(86, 86, 48.00, '2025-05-05 19:28:43', 'Completed'),
(87, 87, 48.00, '2025-05-05 19:56:52', 'Completed'),
(88, 88, 48.00, '2025-05-05 20:14:04', 'Completed'),
(89, 89, 48.00, '2025-05-05 21:00:41', 'Completed'),
(90, 90, 48.00, '2025-05-05 21:17:03', 'Completed'),
(91, 91, 48.00, '2025-05-05 21:25:08', 'Completed'),
(92, 92, 48.00, '2025-05-05 21:40:34', 'Completed'),
(93, 93, 48.00, '2025-05-05 21:54:59', 'Completed'),
(94, 94, 48.00, '2025-05-06 01:12:37', 'Completed'),
(95, 95, 768.00, '2025-05-06 01:41:09', 'Completed'),
(96, 96, 48.00, '2025-05-06 02:54:56', 'Completed'),
(97, 97, 48.00, '2025-05-06 09:28:29', 'Completed'),
(98, 98, 48.00, '2025-05-06 09:41:26', 'Completed'),
(99, 99, 48.00, '2025-05-06 09:41:35', 'Completed'),
(100, 100, 48.00, '2025-05-06 09:41:45', 'Completed'),
(101, 101, 48.00, '2025-05-06 09:41:53', 'Completed'),
(102, 102, 48.00, '2025-05-06 09:42:03', 'Completed'),
(103, 103, 41.60, '2025-05-06 18:04:01', 'Completed'),
(104, 104, 41.60, '2025-05-06 21:55:21', 'Completed'),
(105, 105, 41.60, '2025-05-06 21:57:04', 'Completed'),
(106, 106, 41.60, '2025-05-06 21:56:47', 'Completed'),
(107, 107, 41.60, '2025-05-06 21:56:35', 'Completed'),
(108, 108, 41.60, '2025-05-06 21:55:07', 'Completed'),
(109, 109, 41.60, '2025-05-06 21:54:52', 'Completed'),
(110, 110, 6400.00, '2025-05-09 12:29:07', 'Completed'),
(111, 111, 3200.00, '2025-05-10 00:26:39', 'Completed'),
(112, 112, 3200.00, '2025-05-10 00:26:52', 'Completed'),
(113, 113, 6400.00, '2025-05-10 00:28:55', 'Pending'),
(114, 114, 6400.00, '2025-05-10 00:34:24', 'Pending'),
(115, 115, 6400.00, '2025-05-10 00:42:14', 'Pending'),
(116, 116, 6400.00, '2025-05-10 00:44:42', 'Pending'),
(117, 117, 6400.00, '2025-05-10 00:49:15', 'Pending'),
(118, 118, 6400.00, '2025-05-10 00:52:05', 'Pending'),
(119, 119, 12.80, '2025-05-10 23:09:59', 'Completed'),
(120, 120, 640.00, '2025-05-11 13:59:24', 'Pending'),
(121, 121, 640.00, '2025-05-11 14:19:25', 'Completed');

-- --------------------------------------------------------

--
-- Table structure for table `rental`
--

CREATE TABLE `rental` (
  `RentalID` int(11) NOT NULL,
  `ToolID` int(11) NOT NULL,
  `RenterID` int(11) NOT NULL,
  `RentalStartDate` date NOT NULL,
  `RentalEndDate` date NOT NULL,
  `ReturnDate` date DEFAULT NULL,
  `BaseRentalPrice` decimal(10,2) NOT NULL,
  `DepositFee` decimal(10,2) NOT NULL,
  `ServiceFee` decimal(10,2) NOT NULL,
  `TotalPrice` decimal(10,2) NOT NULL,
  `BorrowerFactor` float DEFAULT 1,
  `Status` enum('Pending','Approved','Completed','Returned') DEFAULT 'Pending',
  `DamageReport` text DEFAULT NULL,
  `DamageReported` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Flag indicating if tool was returned damaged',
  `NotReturned` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `rental`
--

INSERT INTO `rental` (`RentalID`, `ToolID`, `RenterID`, `RentalStartDate`, `RentalEndDate`, `ReturnDate`, `BaseRentalPrice`, `DepositFee`, `ServiceFee`, `TotalPrice`, `BorrowerFactor`, `Status`, `DamageReport`, `DamageReported`, `NotReturned`) VALUES
(1, 10, 17, '2025-04-25', '2025-04-26', NULL, 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(2, 12, 17, '2025-04-25', '2025-04-26', NULL, 24.00, 12.00, 2.40, 38.40, 1, '', NULL, 0, 0),
(3, 12, 17, '2025-04-25', '2025-04-26', NULL, 24.00, 12.00, 2.40, 38.40, 1, 'Completed', NULL, 0, 0),
(4, 11, 17, '2025-04-25', '2025-04-26', NULL, 44.00, 22.00, 4.40, 70.40, 1, 'Completed', NULL, 0, 0),
(5, 12, 17, '2025-04-25', '2025-04-28', NULL, 48.00, 24.00, 4.80, 76.80, 1, 'Completed', NULL, 0, 0),
(6, 12, 17, '2025-04-26', '2025-04-27', NULL, 24.00, 12.00, 2.40, 38.40, 1, 'Completed', NULL, 0, 0),
(7, 12, 17, '2025-04-25', '2025-04-26', NULL, 24.00, 12.00, 2.40, 38.40, 1, 'Completed', NULL, 0, 0),
(8, 12, 17, '2025-04-25', '2025-04-26', NULL, 24.00, 12.00, 2.40, 38.40, 1, 'Completed', NULL, 0, 0),
(9, 12, 17, '2025-04-25', '2025-04-26', NULL, 24.00, 12.00, 2.40, 38.40, 1, 'Completed', NULL, 0, 0),
(10, 12, 17, '2025-04-25', '2025-04-26', NULL, 24.00, 12.00, 2.40, 38.40, 1, 'Completed', NULL, 0, 0),
(11, 12, 17, '2025-04-28', '2025-05-01', NULL, 48.00, 24.00, 4.80, 76.80, 1, '', NULL, 0, 0),
(12, 12, 17, '2025-04-28', '2025-05-01', NULL, 48.00, 24.00, 4.80, 76.80, 1, '', NULL, 0, 0),
(13, 12, 17, '2025-04-28', '2025-05-01', NULL, 48.00, 24.00, 4.80, 76.80, 1, '', NULL, 0, 0),
(14, 12, 17, '2025-04-28', '2025-05-01', NULL, 48.00, 24.00, 4.80, 76.80, 1, '', NULL, 0, 0),
(15, 12, 17, '2025-04-28', '2025-05-01', NULL, 48.00, 24.00, 4.80, 76.80, 1, '', NULL, 0, 0),
(16, 12, 17, '2025-04-28', '2025-05-01', NULL, 48.00, 24.00, 4.80, 76.80, 1, '', NULL, 0, 0),
(17, 12, 17, '2025-04-28', '2025-05-01', NULL, 48.00, 24.00, 4.80, 76.80, 1, '', NULL, 0, 0),
(18, 12, 17, '2025-04-28', '2025-05-01', NULL, 48.00, 24.00, 4.80, 76.80, 1, '', NULL, 0, 0),
(19, 12, 17, '2025-04-28', '2025-05-01', NULL, 48.00, 24.00, 4.80, 76.80, 1, '', NULL, 0, 0),
(20, 12, 17, '2025-05-01', '2025-05-04', NULL, 48.00, 24.00, 4.80, 76.80, 1, '', NULL, 0, 0),
(21, 60, 17, '2025-04-25', '2025-04-26', NULL, 1000.00, 500.00, 100.00, 1600.00, 1, 'Completed', NULL, 0, 0),
(22, 59, 17, '2025-04-25', '2025-04-26', NULL, 1000.00, 500.00, 100.00, 1600.00, 1, 'Completed', NULL, 0, 0),
(23, 59, 17, '2025-04-25', '2025-04-26', NULL, 1000.00, 500.00, 100.00, 1600.00, 1, 'Completed', NULL, 0, 0),
(24, 59, 17, '2025-04-25', '2025-04-26', NULL, 1000.00, 500.00, 100.00, 1600.00, 1, 'Completed', NULL, 0, 0),
(25, 61, 17, '2025-04-26', '2025-04-27', NULL, 400.00, 200.00, 40.00, 640.00, 1, 'Completed', NULL, 0, 0),
(26, 61, 17, '2025-04-29', '2025-04-30', NULL, 400.00, 200.00, 40.00, 640.00, 1, 'Completed', NULL, 0, 0),
(27, 61, 17, '2025-04-25', '2025-04-26', NULL, 400.00, 200.00, 40.00, 640.00, 1, 'Completed', NULL, 0, 0),
(28, 62, 17, '2025-04-26', '2025-04-27', NULL, 400.00, 200.00, 40.00, 640.00, 1, 'Completed', NULL, 0, 0),
(29, 61, 17, '2025-04-26', '2025-04-27', NULL, 400.00, 200.00, 40.00, 640.00, 1, 'Completed', NULL, 0, 0),
(30, 61, 17, '2025-04-26', '2025-04-27', NULL, 400.00, 200.00, 40.00, 640.00, 1, 'Completed', NULL, 0, 0),
(31, 61, 17, '2025-04-26', '2025-04-26', NULL, 200.00, 100.00, 20.00, 320.00, 1, 'Completed', NULL, 0, 0),
(32, 61, 17, '2025-04-26', '2025-04-26', NULL, 200.00, 100.00, 20.00, 320.00, 1, 'Completed', NULL, 0, 0),
(33, 61, 17, '2025-04-26', '2025-04-26', NULL, 200.00, 100.00, 20.00, 320.00, 1, 'Completed', NULL, 0, 0),
(34, 61, 17, '2025-04-26', '2025-04-27', NULL, 400.00, 200.00, 40.00, 640.00, 1, 'Completed', NULL, 0, 0),
(35, 61, 17, '2025-04-26', '2025-04-26', NULL, 200.00, 100.00, 20.00, 320.00, 1, 'Completed', NULL, 0, 0),
(36, 61, 17, '2025-05-05', '2025-05-06', NULL, 400.00, 200.00, 40.00, 640.00, 1, 'Completed', NULL, 0, 0),
(37, 61, 17, '2025-05-07', '2025-05-09', NULL, 600.00, 300.00, 60.00, 960.00, 1, 'Completed', NULL, 0, 0),
(38, 61, 16, '2025-05-24', '2025-05-27', NULL, 800.00, 400.00, 80.00, 1280.00, 1, 'Completed', NULL, 0, 0),
(39, 61, 16, '2025-05-29', '2025-05-31', NULL, 600.00, 300.00, 60.00, 960.00, 1, 'Completed', NULL, 0, 0),
(40, 62, 16, '2025-05-05', '2025-05-06', NULL, 400.00, 200.00, 40.00, 640.00, 1, 'Completed', NULL, 0, 0),
(41, 63, 16, '2025-05-08', '2025-05-09', NULL, 400.00, 200.00, 40.00, 640.00, 1, 'Completed', NULL, 0, 0),
(42, 63, 16, '2025-05-05', '2025-05-06', NULL, 400.00, 200.00, 40.00, 640.00, 1, '', NULL, 0, 0),
(43, 63, 16, '2025-05-17', '2025-05-18', NULL, 400.00, 200.00, 40.00, 640.00, 1, 'Completed', NULL, 0, 0),
(44, 65, 16, '2025-05-04', '2025-05-06', NULL, 1800.00, 900.00, 180.00, 2880.00, 1, 'Completed', NULL, 0, 0),
(45, 65, 16, '2025-05-12', '2025-05-13', NULL, 1200.00, 600.00, 120.00, 1920.00, 1, 'Completed', NULL, 0, 0),
(46, 65, 16, '2025-05-21', '2025-05-22', NULL, 1200.00, 600.00, 120.00, 1920.00, 1, 'Completed', NULL, 0, 0),
(47, 65, 16, '2025-05-31', '2025-06-01', '2025-05-11', 1200.00, 600.00, 120.00, 1920.00, 1, 'Completed', NULL, 0, 0),
(48, 10, 6, '2025-05-04', '2025-05-05', NULL, 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(49, 10, 6, '2025-05-07', '2025-05-08', NULL, 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(50, 10, 6, '2025-05-10', '2025-05-11', NULL, 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(51, 10, 6, '2025-05-13', '2025-05-14', NULL, 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(52, 10, 6, '2025-05-15', '2025-05-17', NULL, 45.00, 22.50, 4.50, 72.00, 1, 'Completed', NULL, 0, 0),
(53, 57, 6, '2025-05-05', '2025-05-07', NULL, 1500.00, 750.00, 150.00, 2400.00, 1, 'Completed', NULL, 0, 0),
(54, 12, 17, '2025-05-05', '2025-05-06', NULL, 24.00, 12.00, 2.40, 38.40, 1, 'Returned', NULL, 0, 0),
(55, 63, 16, '2025-05-13', '2025-05-14', '2025-05-05', 400.00, 200.00, 40.00, 640.00, 1, 'Completed', NULL, 0, 0),
(56, 11, 17, '2025-05-06', '2025-05-07', NULL, 44.00, 22.00, 4.40, 70.40, 1, 'Completed', NULL, 0, 0),
(57, 27, 17, '2025-05-06', '2025-05-07', NULL, 50.00, 25.00, 5.00, 80.00, 1, 'Completed', NULL, 0, 0),
(58, 27, 17, '2025-05-08', '2025-05-08', NULL, 25.00, 12.50, 2.50, 40.00, 1, 'Completed', NULL, 0, 0),
(59, 27, 17, '2025-05-09', '2025-05-10', '2025-05-05', 50.00, 25.00, 5.00, 80.00, 1, 'Completed', NULL, 0, 0),
(60, 25, 17, '2025-05-06', '2025-05-07', '2025-05-05', 26.00, 13.00, 2.60, 41.60, 1, 'Completed', NULL, 0, 0),
(61, 25, 17, '2025-05-08', '2025-05-09', '2025-05-05', 26.00, 13.00, 2.60, 41.60, 1, 'Completed', NULL, 0, 0),
(62, 25, 17, '2025-05-10', '2025-05-11', '2025-05-05', 26.00, 13.00, 2.60, 41.60, 1, 'Completed', NULL, 0, 0),
(63, 25, 17, '2025-05-12', '2025-05-13', '2025-05-05', 26.00, 13.00, 2.60, 41.60, 1, 'Completed', NULL, 0, 0),
(64, 25, 17, '2025-05-14', '2025-05-15', '2025-05-05', 26.00, 13.00, 2.60, 41.60, 1, 'Completed', NULL, 0, 0),
(65, 25, 17, '2025-05-30', '2025-05-31', '2025-05-05', 26.00, 13.00, 2.60, 41.60, 1, 'Completed', NULL, 0, 0),
(66, 25, 17, '2025-05-28', '2025-05-29', '2025-05-05', 26.00, 13.00, 2.60, 41.60, 1, 'Completed', NULL, 0, 0),
(67, 25, 17, '2025-05-26', '2025-05-27', '2025-05-05', 26.00, 13.00, 2.60, 41.60, 1, 'Completed', NULL, 0, 0),
(68, 27, 17, '2025-05-12', '2025-05-13', '2025-05-05', 50.00, 25.00, 5.00, 80.00, 1, 'Completed', NULL, 0, 0),
(69, 27, 17, '2025-05-14', '2025-05-15', '2025-05-05', 50.00, 25.00, 5.00, 80.00, 1, 'Completed', NULL, 0, 0),
(70, 27, 17, '2025-05-16', '2025-05-17', '2025-05-05', 50.00, 25.00, 5.00, 80.00, 1, 'Completed', NULL, 0, 0),
(71, 27, 17, '2025-05-17', '2025-05-18', '2025-05-05', 50.00, 25.00, 5.00, 80.00, 1, 'Completed', NULL, 0, 0),
(72, 10, 16, '2025-06-01', '2025-06-02', '2025-05-05', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(73, 10, 16, '2025-06-03', '2025-06-04', '2025-05-05', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(74, 10, 16, '2025-06-06', '2025-06-07', '2025-05-05', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(75, 10, 16, '2025-06-08', '2025-06-09', '2025-05-05', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(76, 10, 16, '2025-06-15', '2025-06-16', '2025-05-05', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(77, 10, 16, '2025-06-10', '2025-06-11', '2025-05-05', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(78, 10, 16, '2025-06-12', '2025-06-13', '2025-05-05', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(79, 10, 16, '2025-06-16', '2025-06-17', '2025-05-05', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(80, 10, 16, '2025-06-17', '2025-06-18', '2025-05-05', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(81, 10, 16, '2025-06-17', '2025-06-18', '2025-05-05', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(82, 10, 16, '2025-06-17', '2025-06-18', '2025-05-05', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(83, 10, 16, '2025-06-18', '2025-06-19', '2025-05-06', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(84, 10, 16, '2025-06-19', '2025-06-20', '2025-05-06', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(85, 10, 16, '2025-06-20', '2025-06-21', '2025-05-06', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(86, 10, 16, '2025-06-22', '2025-06-23', '2025-05-06', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(87, 10, 16, '2025-06-21', '2025-06-22', '2025-05-06', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(88, 10, 16, '2025-06-22', '2025-06-23', '2025-05-06', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(89, 10, 16, '2025-06-23', '2025-06-24', '2025-05-06', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(90, 10, 16, '2025-06-24', '2025-06-25', '2025-05-06', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(91, 10, 16, '2025-06-27', '2025-06-28', '2025-05-06', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(92, 10, 16, '2025-06-28', '2025-06-29', '2025-05-06', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(93, 10, 16, '2025-06-29', '2025-06-30', '2025-05-06', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(94, 10, 16, '2025-06-29', '2025-06-30', '2025-05-06', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(95, 10, 16, '2025-06-29', '2025-07-30', '2025-05-06', 480.00, 240.00, 48.00, 768.00, 1, 'Completed', NULL, 0, 0),
(96, 10, 16, '2025-07-07', '2025-07-08', '2025-05-06', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 1, 0),
(97, 10, 16, '2025-07-02', '2025-07-03', '2025-05-06', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 1, 0),
(98, 10, 16, '2025-07-03', '2025-07-04', '2025-05-06', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 1, 0),
(99, 10, 16, '2025-07-10', '2025-07-11', '2025-05-06', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 1, 0),
(100, 10, 16, '2025-07-12', '2025-07-13', '2025-05-06', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 0, 0),
(101, 10, 16, '2025-07-14', '2025-07-15', '2025-05-06', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 1, 0),
(102, 10, 16, '2025-07-16', '2025-07-17', '2025-05-06', 30.00, 15.00, 3.00, 48.00, 1, 'Completed', NULL, 1, 0),
(103, 25, 17, '2025-05-08', '2025-05-09', '2025-05-07', 26.00, 13.00, 2.60, 41.60, 1, 'Completed', NULL, 0, 0),
(104, 25, 16, '2025-05-19', '2025-05-20', '2025-05-07', 26.00, 13.00, 2.60, 41.60, 1, 'Completed', NULL, 0, 0),
(105, 25, 16, '2025-05-21', '2025-05-22', NULL, 26.00, 13.00, 2.60, 41.60, 1, 'Approved', NULL, 0, 0),
(106, 25, 16, '2025-05-23', '2025-05-24', NULL, 26.00, 13.00, 2.60, 41.60, 1, 'Approved', NULL, 0, 0),
(107, 25, 16, '2025-05-25', '2025-05-26', NULL, 26.00, 13.00, 2.60, 41.60, 1, 'Approved', NULL, 0, 0),
(108, 25, 16, '2025-05-29', '2025-05-30', NULL, 26.00, 13.00, 2.60, 41.60, 1, 'Returned', NULL, 0, 0),
(109, 25, 16, '2025-05-31', '2025-06-01', NULL, 26.00, 13.00, 2.60, 41.60, 1, 'Returned', NULL, 0, 0),
(110, 66, 16, '2025-05-10', '2025-05-11', '2025-05-09', 4000.00, 2000.00, 400.00, 6400.00, 1, 'Completed', NULL, 1, 0),
(111, 66, 16, '2025-05-11', '2025-05-11', NULL, 2000.00, 1000.00, 200.00, 3200.00, 1, 'Approved', NULL, 0, 0),
(112, 66, 16, '2025-05-10', '2025-05-10', NULL, 2000.00, 1000.00, 200.00, 3200.00, 1, 'Approved', NULL, 0, 0),
(113, 66, 16, '2025-05-12', '2025-05-13', '2025-05-10', 4000.00, 2000.00, 400.00, 6400.00, 1, '', NULL, 0, 0),
(114, 66, 16, '2025-05-14', '2025-05-15', '2025-05-10', 4000.00, 2000.00, 400.00, 6400.00, 1, '', NULL, 0, 0),
(115, 66, 16, '2025-05-12', '2025-05-10', NULL, 4000.00, 2000.00, 400.00, 6400.00, 1, '', NULL, 0, 0),
(116, 66, 16, '2025-05-12', '2025-05-10', NULL, 4000.00, 2000.00, 400.00, 6400.00, 1, '', NULL, 0, 0),
(117, 66, 16, '2025-05-12', '2025-05-10', NULL, 4000.00, 2000.00, 400.00, 6400.00, 1, '', NULL, 0, 0),
(118, 66, 16, '2025-05-12', '2025-05-13', '2025-05-10', 4000.00, 2000.00, 400.00, 6400.00, 1, '', NULL, 0, 0),
(119, 13, 20, '2025-05-12', '2025-05-13', '2025-05-11', 8.00, 4.00, 0.80, 12.80, 1, 'Completed', NULL, 0, 0),
(120, 61, 20, '2025-06-30', '2025-07-01', '2025-05-11', 400.00, 200.00, 40.00, 640.00, 1, '', NULL, 0, 0),
(121, 61, 20, '2025-06-30', '2025-07-01', NULL, 400.00, 200.00, 40.00, 640.00, 1, 'Approved', NULL, 0, 0);

-- --------------------------------------------------------

--
-- Table structure for table `review`
--

CREATE TABLE `review` (
  `ReviewID` int(11) NOT NULL,
  `ReviewerID` int(11) NOT NULL,
  `ReviewedEntityID` int(11) NOT NULL,
  `EntityType` enum('Tool','User') NOT NULL,
  `Rating` int(11) NOT NULL CHECK (`Rating` >= 1 and `Rating` <= 5),
  `Comment` text DEFAULT NULL,
  `ReviewDate` datetime DEFAULT current_timestamp(),
  `RentalID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `review`
--

INSERT INTO `review` (`ReviewID`, `ReviewerID`, `ReviewedEntityID`, `EntityType`, `Rating`, `Comment`, `ReviewDate`, `RentalID`) VALUES
(1, 17, 10, 'Tool', 5, 'i liked it', '2025-04-23 18:34:59', 1),
(2, 17, 3, 'User', 5, 'good interaction', '2025-04-23 18:34:59', 1),
(3, 17, 12, 'Tool', 5, 'useful', '2025-04-23 18:37:02', 3),
(4, 17, 3, 'User', 5, 'love it love it', '2025-04-23 18:37:02', 3),
(5, 3, 17, 'User', 5, 'was good working with her', '2025-04-23 18:38:29', 1),
(6, 17, 11, 'Tool', 5, 'ice ice baby', '2025-04-23 18:41:13', 4),
(7, 17, 3, 'User', 5, 'hot in here', '2025-04-23 18:41:13', 4),
(40, 3, 16, 'User', 1, 'gvsdhbvh', '2025-05-03 11:34:03', 38),
(45, 16, 61, 'Tool', 5, 'jdgkcsj,j', '2025-05-03 12:08:33', 39),
(46, 16, 3, 'User', 5, 'dsgvkhlbc', '2025-05-03 12:08:33', 39),
(47, 16, 62, 'Tool', 5, 'djkfgjhkjlkl.j,mnbznfnmcgmf,h.', '2025-05-03 12:20:52', 40),
(48, 16, 3, 'User', 5, 'znxmc,v.b/j;kl.jk,jmgfnsxcgmvhbjkln', '2025-05-03 12:20:52', 40),
(50, 3, 6, 'User', 3, 'let us see if this is working', '2025-05-03 16:35:24', 48),
(68, 3, 6, 'User', 1, 'Error submitting review: SQLSTATE[23000]: Integrity constraint violation: 1062 Duplicate entry &amp;#039;6&amp;#039; for key &amp;#039;PRIMARY&amp;#039;', '2025-05-03 20:21:18', 52),
(69, 3, 16, 'User', 3, 'the person being r', '2025-05-03 20:29:08', 47),
(70, 3, 16, 'User', 5, 'gjkhglhlhgcghvhjbknl;m,;lkjhgf jghfxchvjbknlm', '2025-05-03 20:49:56', 39),
(72, 6, 3, 'User', 1, 'what now', '2025-05-03 20:58:09', 48),
(73, 3, 17, 'User', 1, 'was late', '2025-05-03 21:08:20', 30),
(74, 3, 16, 'User', 5, 'aye yow, bing bong', '2025-05-03 23:06:10', 46),
(75, 8, 17, 'User', 3, 'she was ok let us see if my weight is gonna be 2.79', '2025-05-04 18:03:31', 57),
(76, 8, 17, 'User', 3, 'let us see what happens now', '2025-05-04 18:21:23', 58),
(77, 8, 17, 'User', 3, 'let us see what now', '2025-05-04 19:22:03', 59),
(78, 8, 17, 'User', 3, 'lets hope it works now', '2025-05-04 19:38:24', 60),
(79, 8, 17, 'User', 3, 'i am hella tired', '2025-05-04 19:49:23', 61),
(80, 8, 17, 'User', 3, 'you know i am tired of this', '2025-05-04 20:02:14', 62),
(81, 8, 17, 'User', 3, 'we are almost there', '2025-05-04 20:13:35', 63),
(82, 8, 17, 'User', 3, 'i am giving it one more go', '2025-05-04 20:45:35', 64),
(83, 8, 17, 'User', 3, 'please work', '2025-05-04 20:58:38', 65),
(84, 8, 17, 'User', 3, 'tired', '2025-05-04 21:15:37', 66),
(85, 8, 17, 'User', 3, 'fed up', '2025-05-04 21:23:20', 67),
(86, 3, 17, 'User', 1, 'let use see what we get', '2025-05-04 23:04:34', 56),
(87, 17, 8, 'User', 4, 'let us see what happens now', '2025-05-04 23:42:18', 65),
(88, 17, 8, 'User', 3, 'bs', '2025-05-04 23:55:54', 66),
(89, 17, 8, 'User', 3, 'ah god', '2025-05-05 00:22:30', 67),
(90, 17, 8, 'User', 3, 'let us see what will change now', '2025-05-05 00:28:29', 64),
(91, 17, 8, 'User', 3, 'again', '2025-05-05 00:35:53', 63),
(92, 8, 17, 'User', 3, 'let us see', '2025-05-05 00:42:42', 68),
(93, 8, 17, 'User', 2, 'what will it become', '2025-05-05 00:54:24', 69),
(94, 8, 17, 'User', 2, 'u see the time?', '2025-05-05 02:32:53', 70),
(95, 8, 17, 'User', 3, 'j', '2025-05-05 02:47:33', 71),
(96, 3, 16, 'User', 5, 'Final Answer:\r\nAlice’s review weight = 4.09\r\nGrace’s updated reputation score = ~4.20', '2025-05-05 12:47:37', 43),
(98, 3, 16, 'User', 5, 'Error submitting review: Failed to update reviewer weight', '2025-05-05 13:20:09', 72),
(99, 3, 16, 'User', 5, 'help mi nuh man', '2025-05-05 13:29:28', 73),
(100, 3, 16, 'User', 5, 'almighty i am tired', '2025-05-05 13:33:45', 74),
(101, 3, 16, 'User', 5, 'Alice’s review weight: approximately 3.743\r\n\r\nGrace’s updated reputation score: approximately 4.028', '2025-05-05 13:51:12', 75),
(102, 3, 16, 'User', 5, 'dear lord u know im tired', '2025-05-05 15:15:37', 76),
(103, 3, 16, 'User', 5, '5 15 3.66', '2025-05-05 15:44:16', 77),
(104, 3, 16, 'User', 5, '5 16 3.75', '2025-05-05 15:59:08', 78),
(105, 3, 16, 'User', 5, '17 3.8235', '2025-05-05 16:09:05', 79),
(106, 3, 16, 'User', 5, '17 3.8235', '2025-05-05 16:19:48', 80),
(107, 3, 16, 'User', 5, 'owner- 19 3.9474\r\nrenter 4.06 14', '2025-05-05 16:30:59', 81),
(108, 3, 16, 'User', 5, 'tired as hell, 20 4', '2025-05-05 16:39:22', 82),
(109, 3, 16, 'User', 5, 'let us see the bull', '2025-05-05 18:08:48', 83),
(110, 3, 16, 'User', 5, 'let us see where the error is', '2025-05-05 18:25:11', 84),
(111, 3, 16, 'User', 5, 'oh god mi belly a hurt mi now', '2025-05-05 18:51:31', 85),
(112, 3, 16, 'User', 5, 'let us see', '2025-05-05 19:29:43', 86),
(113, 3, 16, 'User', 4, 'lord have mercy', '2025-05-05 20:00:09', 87),
(114, 3, 16, 'User', 5, 'let use see now', '2025-05-05 20:14:32', 88),
(115, 3, 16, 'User', 4, 'let it all work out', '2025-05-05 21:03:14', 89),
(116, 3, 16, 'User', 5, 'let us see now', '2025-05-05 21:18:06', 90),
(117, 3, 16, 'User', 5, 'let us hope and pray that this is it. plz 4.44', '2025-05-05 21:29:09', 91),
(118, 3, 16, 'User', 5, 'you know it&#039;s hard out there', '2025-05-05 21:42:52', 92),
(119, 3, 16, 'User', 5, 'i think this might be it', '2025-05-05 21:55:27', 93),
(128, 16, 3, 'User', 1, 'yup', '2025-05-05 23:38:01', 72),
(137, 16, 3, 'User', 1, 'daylight', '2025-05-06 00:07:06', 93),
(138, 16, 3, 'User', 1, 'you know it&#039;s hard out here', '2025-05-06 00:18:51', 92),
(139, 16, 3, 'User', 5, 'sigh', '2025-05-06 00:42:18', 91),
(140, 16, 3, 'User', 5, 'you know it is hard out here', '2025-05-06 00:56:23', 90),
(141, 16, 3, 'User', 5, 'money', '2025-05-06 01:02:25', 89),
(142, 16, 3, 'User', 5, 'rent', '2025-05-06 01:07:16', 86),
(143, 3, 16, 'User', 5, 'let us see if it still works', '2025-05-06 01:13:19', 94),
(144, 3, 16, 'User', 5, 'well', '2025-05-06 01:41:35', 95),
(145, 16, 3, 'User', 5, 'tired.com', '2025-05-06 01:52:31', 95),
(146, 16, 3, 'User', 5, 'money and the rent', '2025-05-06 02:13:31', 94),
(147, 16, 3, 'User', 5, 'my back hurts', '2025-05-06 02:21:57', 88),
(148, 16, 3, 'User', 5, 'let us see', '2025-05-06 02:38:58', 87),
(149, 16, 3, 'User', 5, 'plz work', '2025-05-06 02:45:33', 84),
(150, 3, 16, 'User', 3, 'was damaged', '2025-05-06 02:56:25', 96),
(151, 3, 16, 'User', 3, 'was not in good condition', '2025-05-06 09:29:07', 97),
(152, 3, 16, 'User', 3, 'let us see', '2025-05-06 09:46:11', 98),
(153, 3, 16, 'User', 3, 'lets see', '2025-05-06 10:44:54', 99),
(154, 3, 16, 'User', 3, 'was damaged let us see if it works now', '2025-05-06 11:40:20', 100),
(155, 3, 16, 'User', 3, 'forgot to select damaged', '2025-05-06 11:44:17', 101),
(156, 3, 16, 'User', 3, 'lets us see', '2025-05-06 12:03:41', 102),
(157, 17, 3, 'User', 5, 'ha', '2025-05-06 17:55:21', 6),
(158, 17, 8, 'User', 5, 'cake by the ocean', '2025-05-06 17:59:01', 71),
(159, 8, 17, 'User', 5, 'tomorrow i will look again', '2025-05-06 18:05:28', 103),
(161, 8, 16, 'User', 5, 'Reviewweight', '2025-05-06 22:09:23', 104),
(162, 3, 16, 'User', 5, 'she returned on time, damaged tool.', '2025-05-09 12:32:26', 110),
(163, 4, 20, 'User', 5, 'she was pleasant, returned tool on time and no damages.', '2025-05-10 23:11:33', 119),
(164, 20, 4, 'User', 5, 'he was pleasant, nice tools', '2025-05-10 23:12:28', 119);

--
-- Triggers `review`
--
DELIMITER $$
CREATE TRIGGER `trg_decrement_reviews_received_count` AFTER DELETE ON `review` FOR EACH ROW BEGIN
    UPDATE User
    SET ReviewsReceivedCount = ReviewsReceivedCount - 1
    WHERE UserID = OLD.ReviewedEntityID AND ReviewsReceivedCount > 0;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_increment_reviews_received_count` AFTER INSERT ON `review` FOR EACH ROW BEGIN
    UPDATE User
    SET ReviewsReceivedCount = ReviewsReceivedCount + 1
    WHERE UserID = NEW.ReviewedEntityID;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `reviewhistory`
--

CREATE TABLE `reviewhistory` (
  `ReviewID` int(11) NOT NULL,
  `ReviewerID` int(11) NOT NULL,
  `RevieweeID` int(11) NOT NULL,
  `Rating` float NOT NULL CHECK (`Rating` >= 1 and `Rating` <= 5),
  `ReviewDate` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `reviewhistory`
--

INSERT INTO `reviewhistory` (`ReviewID`, `ReviewerID`, `RevieweeID`, `Rating`, `ReviewDate`) VALUES
(1, 1, 2, 5, '2022-12-27 00:00:00'),
(2, 1, 2, 5, '2023-01-22 00:00:00'),
(3, 1, 6, 5, '2022-02-26 00:00:00'),
(4, 1, 5, 3.9, '2023-09-23 00:00:00'),
(5, 2, 5, 4.1, '2021-08-09 00:00:00'),
(6, 2, 3, 4.4, '2023-05-22 00:00:00'),
(7, 2, 6, 3.4, '2024-08-10 00:00:00'),
(8, 3, 1, 4.1, '2022-05-12 00:00:00'),
(9, 3, 4, 5, '2023-05-29 00:00:00'),
(10, 3, 4, 4.7, '2022-10-23 00:00:00'),
(11, 4, 2, 2.7, '2023-04-23 00:00:00'),
(12, 4, 2, 3.9, '2023-10-18 00:00:00'),
(13, 4, 6, 4.7, '2024-04-06 00:00:00'),
(14, 4, 5, 3.4, '2023-10-12 00:00:00'),
(15, 5, 1, 4.3, '2024-03-22 00:00:00'),
(16, 5, 3, 4.6, '2023-03-01 00:00:00'),
(17, 6, 1, 3.3, '2025-05-03 00:00:00'),
(18, 6, 1, 3.7, '2025-05-03 00:00:00'),
(19, 6, 3, 2.8, '2025-05-03 00:00:00'),
(20, 1, 2, 4.5, '2024-09-01 00:00:00'),
(21, 1, 3, 5, '2024-09-03 00:00:00'),
(22, 1, 4, 4.8, '2024-09-07 00:00:00'),
(23, 1, 5, 1, '2024-09-10 00:00:00'),
(24, 1, 6, 3, '2024-09-15 00:00:00'),
(25, 2, 1, 5, '2024-10-01 00:00:00'),
(26, 2, 3, 4, '2024-10-04 00:00:00'),
(27, 5, 1, 4, '2024-10-12 00:00:00'),
(28, 5, 2, 3.5, '2024-10-15 00:00:00'),
(29, 6, 1, 2, '2024-11-01 00:00:00'),
(30, 6, 3, 3, '2024-11-03 00:00:00'),
(31, 3, 1, 4, '2024-11-10 00:00:00'),
(32, 3, 5, 4.2, '2024-11-12 00:00:00'),
(68, 3, 6, 1, '2025-05-03 20:21:18'),
(69, 3, 16, 3, '2025-05-03 20:29:08'),
(70, 3, 16, 5, '2025-05-03 20:49:56'),
(73, 3, 17, 1, '2025-05-03 21:08:20'),
(74, 3, 16, 5, '2025-05-03 23:06:10'),
(75, 8, 17, 3, '2025-05-04 18:03:31'),
(76, 8, 17, 3, '2025-05-04 18:21:23'),
(77, 8, 17, 3, '2025-05-04 19:22:03'),
(78, 8, 17, 3, '2025-05-04 19:38:24'),
(79, 8, 17, 3, '2025-05-04 19:49:23'),
(80, 8, 17, 3, '2025-05-04 20:02:14'),
(81, 8, 17, 3, '2025-05-04 20:13:36'),
(82, 8, 17, 3, '2025-05-04 20:45:35'),
(83, 8, 17, 3, '2025-05-04 20:58:38'),
(84, 8, 17, 3, '2025-05-04 21:15:37'),
(85, 8, 17, 3, '2025-05-04 21:23:20'),
(86, 3, 17, 1, '2025-05-04 23:04:34'),
(92, 8, 17, 3, '2025-05-05 00:42:42'),
(93, 8, 17, 2, '2025-05-05 00:54:24'),
(94, 8, 17, 2, '2025-05-05 02:32:53'),
(95, 8, 17, 3, '2025-05-05 02:47:33'),
(96, 3, 16, 5, '2025-05-05 12:47:37'),
(98, 3, 16, 5, '2025-05-05 13:20:09'),
(99, 3, 16, 5, '2025-05-05 13:29:28'),
(100, 3, 16, 5, '2025-05-05 13:33:45'),
(101, 3, 16, 5, '2025-05-05 13:51:12'),
(102, 3, 16, 5, '2025-05-05 15:15:37'),
(103, 3, 16, 5, '2025-05-05 15:44:16'),
(104, 3, 16, 5, '2025-05-05 15:59:08'),
(105, 3, 16, 5, '2025-05-05 16:09:05'),
(106, 3, 16, 5, '2025-05-05 16:19:48'),
(107, 3, 16, 5, '2025-05-05 16:30:59'),
(108, 3, 16, 5, '2025-05-05 16:39:22'),
(109, 3, 16, 5, '2025-05-05 18:08:48'),
(110, 3, 16, 5, '2025-05-05 18:25:11'),
(111, 3, 16, 5, '2025-05-05 18:51:31'),
(112, 3, 16, 5, '2025-05-05 19:29:43'),
(113, 3, 16, 4, '2025-05-05 20:00:09'),
(114, 3, 16, 5, '2025-05-05 20:14:32'),
(115, 3, 16, 4, '2025-05-05 21:03:14'),
(116, 3, 16, 5, '2025-05-05 21:18:06'),
(117, 3, 16, 5, '2025-05-05 21:29:09'),
(118, 3, 16, 5, '2025-05-05 21:42:52'),
(119, 3, 16, 5, '2025-05-05 21:55:27'),
(143, 3, 16, 5, '2025-05-06 01:13:19'),
(144, 3, 16, 5, '2025-05-06 01:41:35'),
(150, 3, 16, 3, '2025-05-06 02:56:25'),
(151, 3, 16, 3, '2025-05-06 09:29:08'),
(152, 3, 16, 3, '2025-05-06 09:46:12'),
(153, 3, 16, 3, '2025-05-06 10:44:54'),
(154, 3, 16, 3, '2025-05-06 11:40:20'),
(155, 3, 16, 3, '2025-05-06 11:44:17'),
(156, 3, 16, 3, '2025-05-06 12:03:41'),
(159, 8, 17, 5, '2025-05-06 18:05:29'),
(161, 8, 16, 5, '2025-05-06 22:09:23'),
(162, 3, 16, 5, '2025-05-09 12:32:26'),
(163, 4, 20, 5, '2025-05-10 23:11:33');

-- --------------------------------------------------------

--
-- Table structure for table `reviewweight`
--

CREATE TABLE `reviewweight` (
  `UserID` int(11) NOT NULL,
  `Weight` decimal(5,2) DEFAULT 1.00,
  `LastCalculated` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `reviewweight`
--

INSERT INTO `reviewweight` (`UserID`, `Weight`, `LastCalculated`) VALUES
(1, 1.00, '2025-04-10 13:42:05'),
(2, 1.00, '2025-04-10 13:42:05'),
(3, 2.00, '2025-05-06 09:46:12'),
(4, 3.99, '2025-04-10 13:52:10'),
(5, 1.00, '2025-04-10 13:52:10'),
(6, 2.34, '2025-04-10 13:52:10'),
(7, 1.00, '2025-04-10 13:52:10'),
(8, 2.14, '2025-05-05 02:47:33'),
(9, 1.00, '2025-04-10 13:52:10'),
(10, 1.00, '2025-04-10 13:52:10'),
(11, 1.00, '2025-04-10 13:52:10'),
(12, 1.00, '2025-04-10 13:52:10'),
(13, 1.00, '2025-04-10 13:52:10'),
(14, 1.00, '2025-04-10 13:52:10'),
(15, 1.00, '2025-04-10 13:52:10'),
(16, 1.67, '2025-05-06 02:45:33'),
(17, 0.30, '2025-05-05 00:35:53'),
(18, 1.00, '2025-05-10 02:14:52'),
(19, 1.00, '2025-05-10 02:25:12'),
(20, 1.00, '2025-05-10 23:05:46');

-- --------------------------------------------------------

--
-- Table structure for table `tool`
--

CREATE TABLE `tool` (
  `ToolID` int(11) NOT NULL,
  `OwnerID` int(11) NOT NULL,
  `Name` varchar(100) NOT NULL,
  `Description` text DEFAULT NULL,
  `Images` text DEFAULT NULL,
  `PricePerDay` decimal(10,2) NOT NULL,
  `WeightedRating` float DEFAULT 0,
  `AvailabilityStatus` enum('Available','Rented','Unavailable') DEFAULT 'Available',
  `Category` enum('Hand Tools','Power Tools','Garden Tools','Electronics','Other') NOT NULL,
  `DateAdded` datetime DEFAULT current_timestamp(),
  `Location` varchar(255) DEFAULT NULL,
  `DeliveryOption` enum('Pickup Only','Delivery Available') NOT NULL DEFAULT 'Pickup Only',
  `DeliveryPrice` decimal(10,2) DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tool`
--

INSERT INTO `tool` (`ToolID`, `OwnerID`, `Name`, `Description`, `Images`, `PricePerDay`, `WeightedRating`, `AvailabilityStatus`, `Category`, `DateAdded`, `Location`, `DeliveryOption`, `DeliveryPrice`) VALUES
(1, 1, 'Cordless Drill', '18V Lithium-ion cordless drill with 2 batteries', NULL, 15.99, 0, 'Available', 'Power Tools', '2025-04-10 13:42:05', NULL, 'Pickup Only', 0.00),
(2, 1, 'Circular Saw', '7-1/4 inch circular saw with laser guide', NULL, 22.50, 0, 'Available', 'Power Tools', '2025-04-10 13:42:05', NULL, 'Pickup Only', 0.00),
(3, 1, 'Tool Set', '65-piece home tool set with case', NULL, 12.75, 0, 'Available', 'Hand Tools', '2025-04-10 13:42:05', NULL, 'Pickup Only', 0.00),
(4, 1, 'Hammer', 'Standard claw hammer', NULL, 5.00, 0, 'Available', 'Hand Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(5, 1, 'Screwdriver Set', 'Set of 6 screwdrivers', NULL, 7.50, 0, 'Available', 'Hand Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(6, 1, 'Wrench', 'Adjustable wrench', NULL, 6.00, 0, 'Available', 'Hand Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(7, 2, 'Lawn Mower', 'Electric lawn mower', NULL, 20.00, 0, 'Available', 'Garden Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(8, 2, 'Leaf Blower', 'Cordless leaf blower', NULL, 15.00, 0, 'Available', 'Garden Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(9, 2, 'Hedge Trimmer', 'Electric hedge trimmer', NULL, 18.00, 0, 'Available', 'Garden Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(10, 3, 'Power Drill', 'Cordless power drill', NULL, 15.00, 0, 'Available', 'Power Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(11, 3, 'Circular Saw', '7-inch circular saw', NULL, 22.00, 0, 'Available', 'Power Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(12, 3, 'Sander', 'Electric sander', NULL, 12.00, 0, 'Available', 'Power Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(13, 4, 'Tape Measure', '25-foot tape measure', NULL, 4.00, 0, 'Available', 'Hand Tools', '2025-04-23 17:38:12', 'mona', 'Pickup Only', 0.00),
(14, 4, 'Level', '24-inch level', NULL, 6.00, 0, 'Available', 'Hand Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(15, 4, 'Chisel Set', 'Set of 3 chisels', NULL, 8.00, 0, 'Available', 'Hand Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(16, 5, 'Extension Cord', '50-foot extension cord', NULL, 10.00, 0, 'Available', 'Electronics', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(17, 5, 'Work Light', 'LED work light', NULL, 14.00, 0, 'Available', 'Electronics', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(18, 5, 'Battery Charger', 'Multi-device battery charger', NULL, 9.00, 0, 'Available', 'Electronics', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(19, 6, 'Garden Hose', '100-foot garden hose', NULL, 12.00, 0, 'Available', 'Garden Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(20, 6, 'Sprinkler', 'Rotating sprinkler', NULL, 7.00, 0, 'Available', 'Garden Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(21, 6, 'Pruning Shears', 'Sharp pruning shears', NULL, 5.50, 0, 'Available', 'Garden Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(22, 7, 'Paint Roller', '9-inch paint roller', NULL, 6.00, 0, 'Available', 'Hand Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(23, 7, 'Paint Brush Set', 'Set of 3 brushes', NULL, 7.50, 0, 'Available', 'Hand Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(24, 7, 'Putty Knife', '3-inch putty knife', NULL, 4.50, 0, 'Available', 'Hand Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(25, 8, 'Cordless Screwdriver', 'Battery powered screwdriver', NULL, 13.00, 0, 'Available', 'Power Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(27, 8, 'Nail Gun', 'Pneumatic nail gun', NULL, 25.00, 0, 'Available', 'Power Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(28, 9, 'Chainsaw', 'Gas powered chainsaw', NULL, 30.00, 0, 'Available', 'Power Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(29, 9, 'Leaf Vacuum', 'Electric leaf vacuum', NULL, 15.00, 0, 'Available', 'Garden Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(30, 9, 'Wheelbarrow', 'Steel wheelbarrow', NULL, 20.00, 0, 'Available', 'Garden Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(31, 10, 'Air Compressor', 'Portable air compressor', NULL, 40.00, 0, 'Available', 'Power Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(32, 10, 'Angle Grinder', 'Electric angle grinder', NULL, 22.00, 0, 'Available', 'Power Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(33, 10, 'Heat Gun', 'Electric heat gun', NULL, 18.00, 0, 'Available', 'Power Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(34, 11, 'Toolbox', 'Metal toolbox', NULL, 15.00, 0, 'Available', 'Hand Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(35, 11, 'Safety Glasses', 'Protective eyewear', NULL, 5.00, 0, 'Available', 'Other', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(36, 11, 'Work Gloves', 'Pair of work gloves', NULL, 6.00, 0, 'Available', 'Other', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(37, 12, 'Ladder', '6-foot step ladder', NULL, 25.00, 0, 'Available', 'Other', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(38, 12, 'Flashlight', 'LED flashlight', NULL, 8.00, 0, 'Available', 'Electronics', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(39, 12, 'Measuring Wheel', 'Distance measuring wheel', NULL, 12.00, 0, 'Available', 'Hand Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(40, 13, 'Chainsaw Safety Gear', 'Helmet and gloves', NULL, 20.00, 0, 'Available', 'Other', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(41, 13, 'Garden Fork', 'Steel garden fork', NULL, 10.00, 0, 'Available', 'Garden Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(42, 13, 'Rake', 'Leaf rake', NULL, 7.00, 0, 'Available', 'Garden Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(43, 14, 'Power Washer', 'Electric power washer', NULL, 35.00, 0, 'Available', 'Power Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(44, 14, 'Shovel', 'Steel shovel', NULL, 10.00, 0, 'Available', 'Garden Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(45, 14, 'Wheel Chocks', 'Set of 4 wheel chocks', NULL, 8.00, 0, 'Available', 'Other', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(46, 15, 'Concrete Mixer', 'Portable concrete mixer', NULL, 50.00, 0, 'Available', 'Power Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(47, 15, 'Trowel', 'Masonry trowel', NULL, 7.00, 0, 'Available', 'Hand Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(48, 15, 'Safety Helmet', 'Construction helmet', NULL, 12.00, 0, 'Available', 'Other', '0000-00-00 00:00:00', NULL, 'Pickup Only', 0.00),
(49, 16, 'Electric Drill', 'Cordless electric drill', NULL, 15.00, 0, 'Available', 'Power Tools', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(50, 16, 'Tool Belt', 'Leather tool belt', NULL, 10.00, 0, 'Available', 'Other', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(51, 16, 'Stud Finder', 'Electronic stud finder', NULL, 8.00, 0, 'Available', 'Electronics', '2025-04-23 17:38:12', NULL, 'Pickup Only', 0.00),
(57, 3, 'hammer', 'ham', NULL, 500.00, 0, 'Available', 'Hand Tools', '2025-04-24 12:23:49', NULL, 'Pickup Only', 0.00),
(59, 3, 'bit', 'bit', NULL, 500.00, 0, 'Available', 'Hand Tools', '2025-04-24 12:37:42', NULL, 'Pickup Only', 0.00),
(60, 3, 'bit', 'bit', NULL, 500.00, 0, 'Unavailable', 'Hand Tools', '2025-04-24 12:37:50', NULL, 'Pickup Only', 0.00),
(61, 3, 'cat', 'catty', NULL, 200.00, 0, 'Available', 'Hand Tools', '2025-04-24 12:58:56', 'crossroads', 'Pickup Only', 0.00),
(62, 3, 'cat', 'catty', NULL, 200.00, 0, 'Available', 'Hand Tools', '2025-04-24 12:59:01', 'mona', 'Delivery Available', 900.00),
(63, 3, 'cat', 'catty', NULL, 200.00, 0, 'Available', 'Hand Tools', '2025-04-24 12:59:05', 'crossroads', 'Delivery Available', 800.00),
(65, 3, 'router', 'rotate', NULL, 600.00, 0, 'Available', 'Power Tools', '2025-04-24 13:25:48', 'mona', 'Delivery Available', 0.00),
(66, 3, 'tiller', 'tills the soil', NULL, 2000.00, 0, 'Available', 'Garden Tools', '2025-05-09 12:27:18', NULL, 'Pickup Only', 0.00);

-- --------------------------------------------------------

--
-- Table structure for table `toolphoto`
--

CREATE TABLE `toolphoto` (
  `PhotoID` int(11) NOT NULL,
  `ToolID` int(11) NOT NULL,
  `PhotoPath` varchar(255) NOT NULL,
  `UploadedAt` datetime DEFAULT current_timestamp(),
  `IsPrimary` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `toolphoto`
--

INSERT INTO `toolphoto` (`PhotoID`, `ToolID`, `PhotoPath`, `UploadedAt`, `IsPrimary`) VALUES
(4, 59, 'uploads/tools/tool_59_680a76e6261a7.png', '2025-04-24 12:37:42', 1),
(5, 59, 'uploads/tools/tool_59_680a76e62b980.png', '2025-04-24 12:37:42', 0),
(6, 59, 'uploads/tools/tool_59_680a76e62c438.png', '2025-04-24 12:37:42', 0),
(10, 61, 'uploads/tools/tool_61_680a7be051ade.png', '2025-04-24 12:58:56', 1),
(11, 62, 'uploads/tools/tool_62_680a7be5b75d5.png', '2025-04-24 12:59:01', 1),
(12, 63, 'uploads/tools/tool_63_680a7be9d3551.png', '2025-04-24 12:59:05', 1),
(14, 65, 'uploads/tools/tool_65_680a822ccb316.png', '2025-04-24 13:25:48', 0),
(15, 65, 'uploads/tools/tool_65_680a822cd37f4.png', '2025-04-24 13:25:48', 1),
(16, 65, 'uploads/tools/tool_65_680a822cd4636.png', '2025-04-24 13:25:48', 0),
(20, 12, 'uploads/tools/tool_12_680a8666df677.jpg', '2025-04-24 13:43:50', 0),
(21, 12, 'uploads/tools/tool_12_680a8666e10e9.jpg', '2025-04-24 13:43:50', 0),
(22, 12, 'uploads/tools/tool_12_680a8666e211c.jpg', '2025-04-24 13:43:50', 1),
(28, 66, 'uploads/tools/tool_66_681ed981dadb7.png', '2025-05-09 23:43:45', 1),
(29, 66, 'uploads/tools/tool_66_681ed981e2df2.png', '2025-05-09 23:43:45', 0),
(30, 66, 'uploads/tools/tool_66_681ed981e630d.jpg', '2025-05-09 23:43:45', 0),
(31, 13, 'uploads/tools/tool_13_6820229d91ccb.jpg', '2025-05-10 23:07:57', 1);

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

CREATE TABLE `user` (
  `UserID` int(11) NOT NULL,
  `FirstName` varchar(50) NOT NULL,
  `LastName` varchar(50) NOT NULL,
  `PhoneNumber` varchar(15) DEFAULT NULL,
  `ProfilePhoto` text DEFAULT NULL,
  `IdentificationDocument` text DEFAULT NULL,
  `ProofOfAddress` text DEFAULT NULL,
  `Email` varchar(100) NOT NULL,
  `Password` varchar(255) NOT NULL,
  `UserType` enum('Owner','Renter','Admin') NOT NULL,
  `ReputationScore` float DEFAULT 0,
  `ReviewCount` int(11) DEFAULT 0,
  `RegistrationDate` datetime DEFAULT current_timestamp(),
  `CreatedAt` datetime DEFAULT current_timestamp(),
  `AvgRatingGiven` float DEFAULT 3,
  `ReviewsReceivedCount` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user`
--

INSERT INTO `user` (`UserID`, `FirstName`, `LastName`, `PhoneNumber`, `ProfilePhoto`, `IdentificationDocument`, `ProofOfAddress`, `Email`, `Password`, `UserType`, `ReputationScore`, `ReviewCount`, `RegistrationDate`, `CreatedAt`, `AvgRatingGiven`, `ReviewsReceivedCount`) VALUES
(1, 'Michael', 'Johnson', '555-0201', '/profile_photos/michael.jpg', '/docs/michael_id.pdf', '/docs/michael_address.pdf', 'michael.j@example.com', '$2a$10$9b8m5V04A3Jf3oP1YQdZ3uJ7Kv2WxY8LpNq1RsTtUvWXyZ3HsYIOP', 'Owner', 4.5, 3, '2025-04-10 13:42:05', '2025-04-10 13:42:05', 4.133, 3),
(2, 'Emily', 'Davis', '555-0301', NULL, NULL, NULL, 'emily.d@example.com', '$2a$10$3b2nV54D9kLm4OpQrXsZ.uH8vW3Yx9LpNq2StUvWXyZ1AbCdEfGhI', 'Renter', 0, 0, '2024-01-15 09:30:00', '2025-04-10 13:42:05', 4.18, 0),
(3, 'Alice', 'Smith', '555-1001', '/profile_photos/alice.jpg', '/docs/alice_id.pdf', '/docs/alice_address.pdf', 'alice.smith@example.com', '$2y$10$updcg.kxHGompHerIgQs9O8ySaV605Sjg1NWozketuzlLz4DU7Xe2', 'Owner', 2.34959, 42, '2020-04-11 00:00:00', '2025-04-10 13:52:10', 4.1429, 223),
(4, 'Bob', 'Johnson', '555-1002', '/profile_photos/bob.jpg', '/docs/bob_id.pdf', '/docs/bob_address.pdf', 'bob.johnson@example.com', '$2y$10$hc9ByCBuvO2pqyUidNEvSOf0EFlJC1DYMD/Xje1JWFyBdpXi0Vag2', 'Owner', 4.5, 1, '2024-04-10 00:00:00', '2025-04-10 13:52:10', 5, 51),
(5, 'Carol', 'Williams', '555-1003', '/profile_photos/carol.jpg', '/docs/carol_id.pdf', '/docs/carol_address.pdf', 'carol.williams@example.com', '$2y$10$lYX4yGQErq6S2Jau1.W/buDmeEggrS3UFH2uShtExBdcvTrPO2QR', 'Renter', 3.9, 10, '2024-11-11 00:00:00', '2025-04-10 13:52:10', 4.1, 10),
(6, 'Dave', 'Brown', '555-1004', '/profile_photos/dave.jpg', '/docs/dave_id.pdf', '/docs/dave_address.pdf', 'dave.brown@example.com', '$2y$10$WQBSFWzjQb96juBCjdU9ReDr7rhYbCmp6MeVwEBSzG/QLmLVDxQ0u', 'Renter', 1.5, 2, '2024-12-11 00:00:00', '2025-04-10 13:52:10', 2.96, 2),
(7, 'Eve', 'Davis', '555-1005', '/profile_photos/eve.jpg', '/docs/eve_id.pdf', '/docs/eve_address.pdf', 'eve.davis@example.com', '$2y$10$Ls8hxvVfQBiWiE2J6nifhOagdWEtswzaIoOZ5bsl57sCsah8B6JQe', 'Renter', 5, 8, '2024-09-22 00:00:00', '2025-04-10 13:52:10', 3, 8),
(8, 'Frank', 'Miller', '555-1006', '/profile_photos/frank.jpg', '/docs/frank_id.pdf', '/docs/frank_address.pdf', 'frank.miller@example.com', '$2y$10$sitMWaWag6kBee6Xci6zbeHlr/vrymcwq4HS06iRHCsRsUeH5nZiq', 'Owner', 3.2, 17, '2023-11-27 00:00:00', '2025-04-10 13:52:10', 3.1176, 36),
(9, 'Grace', 'Taylor', '555-1007', '/profile_photos/grace.jpg', '/docs/grace_id.pdf', '/docs/grace_address.pdf', 'grace.taylor@example.com', '$2y$10$5gZbaNqWCO0ThnzHNjDTlubODXugLx0NeqHY5RHK2HUX.upw5ea1G', 'Renter', 4, 15, '2024-06-14 00:00:00', '2025-04-10 13:52:10', 3, 15),
(10, 'Alice1', 'Smith', '555-1001', '/profile_photos/alice.jpg', '/docs/alice_id.pdf', '/docs/alice_address.pdf', 'alice1.smith@example.com', '$2y$10$MhzdWdwcKgYTSvTkdAX8MeQ/baf2zsWRRT1DgRluFG0wK7HSE.tQe', 'Owner', 4.8, 200, '2020-04-11 00:00:00', '2025-04-10 13:52:10', 3, 200),
(11, 'Bob1', 'Johnson', '555-1002', '/profile_photos/bob.jpg', '/docs/bob_id.pdf', '/docs/bob_address.pdf', 'bob1.johnson@example.com', '$2y$10$R2kZnW1Q8Dd8k/HwEnub3uii011odpGY3.zsV.biozaa0RkkhfEza', 'Owner', 4.5, 50, '2024-04-10 00:00:00', '2025-04-10 13:52:10', 3, 50),
(12, 'Carol1', 'Williams', '555-1003', '/profile_photos/carol.jpg', '/docs/carol_id.pdf', '/docs/carol_address.pdf', 'carol1.williams@example.com', '$2y$10$9NqOzTTkX0QTzIL6.mRpTuFrum.S8isVZGse2vTrWczBSO1jgrBsa', 'Renter', 3.9, 10, '2024-11-11 00:00:00', '2025-04-10 13:52:10', 3, 10),
(13, 'Dave1', 'Brown', '555-1004', '/profile_photos/dave.jpg', '/docs/dave_id.pdf', '/docs/dave_address.pdf', 'dave1.brown@example.com', '$2y$10$JRyPAKn/0.69WPm9fc8C8ugyUG1Ixi5wnyQg6xaFmDEJO0bzqOaQO', 'Renter', 3.2, 5, '2024-12-11 00:00:00', '2025-04-10 13:52:10', 3, 5),
(14, 'Eve1', 'Davis', '555-1005', '/profile_photos/eve.jpg', '/docs/eve_id.pdf', '/docs/eve_address.pdf', 'eve1.davis@example.com', '$2y$10$O/p11BGR5ArwCO4O6gZzmOkYvn8ZqD09ZyhQ78V.JW2UVvB/SdT/i', 'Renter', 5, 8, '2024-09-22 00:00:00', '2025-04-10 13:52:10', 3, 8),
(15, 'Frank1', 'Miller', '555-1006', '/profile_photos/frank.jpg', '/docs/frank_id.pdf', '/docs/frank_address.pdf', 'frank1.miller@example.com', '$2y$10$f1g6t8zDosXMa01xttFzCOoNnRsEfUKFEUqNexKle0LzoIwRg1eui', 'Owner', 4.2, 30, '2023-11-27 00:00:00', '2025-04-10 13:52:10', 3, 30),
(16, 'Grace1', 'Taylor', '555-1007', '/profile_photos/grace.jpg', '/docs/grace_id.pdf', '/docs/grace_address.pdf', 'grace1.taylor@example.com', '$2y$10$J95ekb5SeYmAPqaAsFYDjeSBkXflAEvEZf3hw83OtR9E.U4hsBz9.', 'Renter', 3.39543, 16, '2024-06-14 00:00:00', '2025-04-10 13:52:10', 4.1429, 38),
(17, 'brittany', 'taylor', '84151645', NULL, NULL, NULL, 'brittanytaylor.7720@gmail.com', '$2y$10$6bM5t8tAhnvyuYK3WxwrTeJBOPhtmyAjozYaRRPS7p/v8PTjYapcm', 'Renter', 2.68126, 13, '2025-04-23 17:23:23', '2025-04-23 17:23:23', 4.1, 19),
(19, 'brittany', 'taylor', '12345678', NULL, NULL, NULL, 'briany.taylor7720@gmail.com', '$2y$10$W5s7Yip/ufn4OPV71sYgXuVAfZiVuDuHdlhakFftL1RstK7liiMR2', 'Owner', 0, 0, '2025-05-10 02:25:12', '2025-05-10 02:25:12', 3, 0),
(20, 'April', 'Kepner', '12345678', NULL, NULL, NULL, 'ak@gmail.com', '$2y$10$EGmf/WJX8RqVwpezBJVO1eUPezctclN17rE2wfkxNQpgo1IdLoQ7q', 'Renter', 4.59937, 1, '2025-05-10 23:05:46', '2025-05-10 23:05:46', 5, 1);

--
-- Triggers `user`
--
DELIMITER $$
CREATE TRIGGER `after_user_insert` AFTER INSERT ON `user` FOR EACH ROW BEGIN
    INSERT INTO ReviewWeight (UserID) VALUES (NEW.UserID);
END
$$
DELIMITER ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `notification`
--
ALTER TABLE `notification`
  ADD PRIMARY KEY (`NotificationID`),
  ADD KEY `UserID` (`UserID`),
  ADD KEY `NotificationID` (`NotificationID`),
  ADD KEY `UserID_2` (`UserID`),
  ADD KEY `NotificationID_2` (`NotificationID`),
  ADD KEY `UserID_3` (`UserID`),
  ADD KEY `NotificationID_3` (`NotificationID`),
  ADD KEY `UserID_4` (`UserID`),
  ADD KEY `NotificationID_4` (`NotificationID`),
  ADD KEY `UserID_5` (`UserID`);

--
-- Indexes for table `passwordresettokens`
--
ALTER TABLE `passwordresettokens`
  ADD PRIMARY KEY (`Token`),
  ADD KEY `UserID` (`UserID`);

--
-- Indexes for table `payment`
--
ALTER TABLE `payment`
  ADD PRIMARY KEY (`PaymentID`),
  ADD KEY `RentalID` (`RentalID`),
  ADD KEY `PaymentID` (`PaymentID`),
  ADD KEY `RentalID_2` (`RentalID`),
  ADD KEY `PaymentID_2` (`PaymentID`),
  ADD KEY `RentalID_3` (`RentalID`);

--
-- Indexes for table `rental`
--
ALTER TABLE `rental`
  ADD PRIMARY KEY (`RentalID`),
  ADD KEY `ToolID` (`ToolID`),
  ADD KEY `RenterID` (`RenterID`),
  ADD KEY `ToolID_2` (`ToolID`),
  ADD KEY `RenterID_2` (`RenterID`);

--
-- Indexes for table `review`
--
ALTER TABLE `review`
  ADD PRIMARY KEY (`ReviewID`),
  ADD UNIQUE KEY `unique_rental_review` (`RentalID`,`ReviewerID`,`EntityType`),
  ADD KEY `ReviewerID` (`ReviewerID`);

--
-- Indexes for table `reviewhistory`
--
ALTER TABLE `reviewhistory`
  ADD PRIMARY KEY (`ReviewID`),
  ADD KEY `ReviewerID` (`ReviewerID`),
  ADD KEY `RevieweeID` (`RevieweeID`);

--
-- Indexes for table `reviewweight`
--
ALTER TABLE `reviewweight`
  ADD PRIMARY KEY (`UserID`);

--
-- Indexes for table `tool`
--
ALTER TABLE `tool`
  ADD PRIMARY KEY (`ToolID`),
  ADD KEY `OwnerID` (`OwnerID`);

--
-- Indexes for table `toolphoto`
--
ALTER TABLE `toolphoto`
  ADD PRIMARY KEY (`PhotoID`),
  ADD KEY `idx_tool_photos` (`ToolID`);

--
-- Indexes for table `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`UserID`),
  ADD UNIQUE KEY `Email` (`Email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `notification`
--
ALTER TABLE `notification`
  MODIFY `NotificationID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=308;

--
-- AUTO_INCREMENT for table `payment`
--
ALTER TABLE `payment`
  MODIFY `PaymentID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=122;

--
-- AUTO_INCREMENT for table `rental`
--
ALTER TABLE `rental`
  MODIFY `RentalID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=122;

--
-- AUTO_INCREMENT for table `review`
--
ALTER TABLE `review`
  MODIFY `ReviewID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=165;

--
-- AUTO_INCREMENT for table `reviewhistory`
--
ALTER TABLE `reviewhistory`
  MODIFY `ReviewID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=164;

--
-- AUTO_INCREMENT for table `tool`
--
ALTER TABLE `tool`
  MODIFY `ToolID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=69;

--
-- AUTO_INCREMENT for table `toolphoto`
--
ALTER TABLE `toolphoto`
  MODIFY `PhotoID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT for table `user`
--
ALTER TABLE `user`
  MODIFY `UserID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `notification`
--
ALTER TABLE `notification`
  ADD CONSTRAINT `notification_ibfk_1` FOREIGN KEY (`UserID`) REFERENCES `user` (`UserID`);

--
-- Constraints for table `passwordresettokens`
--
ALTER TABLE `passwordresettokens`
  ADD CONSTRAINT `passwordresettokens_ibfk_1` FOREIGN KEY (`UserID`) REFERENCES `user` (`UserID`) ON DELETE CASCADE;

--
-- Constraints for table `payment`
--
ALTER TABLE `payment`
  ADD CONSTRAINT `payment_ibfk_1` FOREIGN KEY (`RentalID`) REFERENCES `rental` (`RentalID`);

--
-- Constraints for table `rental`
--
ALTER TABLE `rental`
  ADD CONSTRAINT `rental_ibfk_1` FOREIGN KEY (`ToolID`) REFERENCES `tool` (`ToolID`) ON DELETE CASCADE,
  ADD CONSTRAINT `rental_ibfk_2` FOREIGN KEY (`RenterID`) REFERENCES `user` (`UserID`) ON DELETE CASCADE;

--
-- Constraints for table `reviewhistory`
--
ALTER TABLE `reviewhistory`
  ADD CONSTRAINT `reviewhistory_ibfk_1` FOREIGN KEY (`ReviewerID`) REFERENCES `user` (`UserID`) ON DELETE CASCADE,
  ADD CONSTRAINT `reviewhistory_ibfk_2` FOREIGN KEY (`RevieweeID`) REFERENCES `user` (`UserID`) ON DELETE CASCADE;

--
-- Constraints for table `tool`
--
ALTER TABLE `tool`
  ADD CONSTRAINT `tool_ibfk_1` FOREIGN KEY (`OwnerID`) REFERENCES `user` (`UserID`);

--
-- Constraints for table `toolphoto`
--
ALTER TABLE `toolphoto`
  ADD CONSTRAINT `toolphoto_ibfk_1` FOREIGN KEY (`ToolID`) REFERENCES `tool` (`ToolID`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
