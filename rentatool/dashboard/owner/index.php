<?php
header("Cache-Control: no-cache, no-store, must-revalidate");
header("Pragma: no-cache");
header("Expires: 0");

require_once __DIR__ . '/../../includes/config.php';
require_once __DIR__ . '/../../includes/db_connection.php';
require_once __DIR__ . '/../../includes/header.php';

requireLogin(); 


$stmt = $pdo->prepare("
    SELECT 
        u.FirstName, 
        u.LastName,
        u.RegistrationDate,
        u.ReputationScore,
        u.ReviewsReceivedCount,
        COUNT(DISTINCT t.ToolID) as total_tools,
        COUNT(DISTINCT CASE WHEN rent.Status = 'Pending' THEN rent.RentalID END) as pending_requests
    FROM User u
    LEFT JOIN Tool t ON u.UserID = t.OwnerID
    LEFT JOIN Rental rent ON t.ToolID = rent.ToolID
    WHERE u.UserID = ?
    GROUP BY u.UserID, u.FirstName, u.LastName, u.RegistrationDate, u.ReputationScore, u.ReviewsReceivedCount
");
$stmt->execute([$_SESSION['user_id']]);
$userInfo = $stmt->fetch(PDO::FETCH_ASSOC);


$earningsStmt = $pdo->prepare("
    SELECT 
        SUM(
            (DATEDIFF(r.RentalEndDate, r.RentalStartDate) + 1) * t.PricePerDay
        ) + SUM(
            CASE 
                WHEN r.ReturnDate IS NOT NULL AND r.ReturnDate > r.RentalEndDate THEN
                    LEAST(DATEDIFF(r.ReturnDate, r.RentalEndDate) * t.PricePerDay, r.DepositFee)
                WHEN r.ReturnDate IS NULL AND CURDATE() > r.RentalEndDate THEN
                    r.DepositFee
                ELSE 0
            END
        ) AS total_earnings,
        SUM(
            (DATEDIFF(r.RentalEndDate, r.RentalStartDate) + 1) * t.PricePerDay
        ) AS base_earnings,
        SUM(
            CASE 
                WHEN r.ReturnDate IS NOT NULL AND r.ReturnDate > r.RentalEndDate THEN
                    LEAST(DATEDIFF(r.ReturnDate, r.RentalEndDate) * t.PricePerDay, r.DepositFee)
                WHEN r.ReturnDate IS NOT NULL AND r.ReturnDate <= r.RentalEndDate THEN
                    0
                WHEN r.ReturnDate IS NULL AND CURDATE() > r.RentalEndDate THEN
                    r.DepositFee
                ELSE 0
            END
        ) AS deposit_earnings
    FROM Rental r
    JOIN Tool t ON r.ToolID = t.ToolID
    JOIN Payment p ON r.RentalID = p.RentalID
    WHERE t.OwnerID = ? AND r.Status IN ('Approved', 'Completed', 'Returned') AND p.PaymentStatus = 'Completed'
");
$earningsStmt->execute([$_SESSION['user_id']]);
$earningsResult = $earningsStmt->fetch(PDO::FETCH_ASSOC);


$notifStmt = $pdo->prepare("
    SELECT NotificationID, Message, NotificationTimestamp 
    FROM Notification 
    WHERE UserID = ? AND IsRead = 0
    ORDER BY NotificationTimestamp DESC
    LIMIT 5
");
$notifStmt->execute([$_SESSION['user_id']]);
$notifications = $notifStmt->fetchAll(PDO::FETCH_ASSOC);

$joinDate = $userInfo['RegistrationDate'] ? date('F j, Y', strtotime($userInfo['RegistrationDate'])) : 'Not available';

$fullName = htmlspecialchars($userInfo['FirstName'] . ' ' . $userInfo['LastName']);
$rating = number_format($userInfo['ReputationScore'], 1);
$ReviewsReceivedCount = $userInfo['ReviewsReceivedCount'];
$totalTools = $userInfo['total_tools'];
$pendingRequests = $userInfo['pending_requests'];
$totalEarnings = $earningsResult['total_earnings'];


error_log("Owner Earnings Debug - Total: " . $earningsResult['total_earnings'] . 
          ", Base: " . $earningsResult['base_earnings'] . 
          ", Deposit: " . $earningsResult['deposit_earnings']);


$stmt = $pdo->prepare("
    SELECT r.*, t.Name as ToolName, u.FirstName, u.LastName
    FROM Rental r
    JOIN Tool t ON r.ToolID = t.ToolID
    JOIN User u ON r.RenterID = u.UserID
    WHERE t.OwnerID = ?
    ORDER BY r.RentalStartDate DESC
    LIMIT 5
");
$stmt->execute([$_SESSION['user_id']]);
$recentRentals = $stmt->fetchAll(PDO::FETCH_ASSOC);


$viewPath = __DIR__ . '/../../assets/html/owner/index.html';
if (file_exists($viewPath)) {
    include $viewPath;
} else {
    echo "Owner dashboard view file not found.";
}

require_once __DIR__ . '/../../includes/footer.php';
?>
