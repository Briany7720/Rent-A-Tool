<?php
header("Cache-Control: no-cache, no-store, must-revalidate");
header("Pragma: no-cache");
header("Expires: 0");

require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/config.php';
require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/db_connection.php';
require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/header.php';

requireLogin();

if (!isset($_GET['user_id'])) {
    echo "<p>User ID not specified.</p>";
    require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/footer.php';
    exit();
}

$userId = (int)$_GET['user_id'];
$loggedInUserId = $_SESSION['user_id'];


$stmt = $pdo->prepare("
    SELECT u.UserID, u.FirstName, u.LastName, u.Email, u.RegistrationDate,
           u.ReputationScore, u.ReviewCount
    FROM User u
    WHERE u.UserID = :userId
");
$stmt->execute(['userId' => $userId]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$user) {
    echo "<p>User not found.</p>";
    require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/footer.php';
    exit();
}

$stmt = $pdo->prepare("
    SELECT r.Rating, r.Comment, r.ReviewDate, rev.FirstName as ReviewerFirstName, rev.LastName as ReviewerLastName
    FROM Review r
    JOIN User rev ON r.ReviewerID = rev.UserID
    WHERE r.ReviewedEntityID = :userId AND r.EntityType = 'User'
    ORDER BY r.ReviewDate DESC
");
$stmt->execute(['userId' => $userId]);
$reviews = $stmt->fetchAll(PDO::FETCH_ASSOC);


$stmt = $pdo->prepare("SELECT COUNT(*) FROM Tool WHERE OwnerID = :userId");
$stmt->execute(['userId' => $userId]);
$profileUserOwnsTools = $stmt->fetchColumn() > 0;

$stmt = $pdo->prepare("SELECT COUNT(*) FROM Tool WHERE OwnerID = :loggedInUserId");
$stmt->execute(['loggedInUserId' => $loggedInUserId]);
$loggedInUserOwnsTools = $stmt->fetchColumn() > 0;


$showTools = $profileUserOwnsTools && !$loggedInUserOwnsTools;

$tools = [];
$toolBookings = [];

if ($showTools) {
    $stmt = $pdo->prepare("
        SELECT t.ToolID, t.Name, t.Category, t.PricePerDay, t.AvailabilityStatus
        FROM Tool t
        WHERE t.OwnerID = :userId AND t.AvailabilityStatus = 'Available'
    ");
    $stmt->execute(['userId' => $userId]);
    $tools = $stmt->fetchAll(PDO::FETCH_ASSOC);

    
    foreach ($tools as $tool) {
        $stmtBookings = $pdo->prepare("
            SELECT RentalStartDate, COALESCE(ReturnDate, RentalEndDate) AS RentalEndDate
            FROM Rental
            WHERE ToolID = :toolId AND Status NOT IN ('Rejected', 'Cancelled')
            ORDER BY RentalStartDate
        ");
        $stmtBookings->execute(['toolId' => $tool['ToolID']]);
        $bookings = $stmtBookings->fetchAll(PDO::FETCH_ASSOC);
        $toolBookings[$tool['ToolID']] = $bookings;
    }
}

include __DIR__ . '/../../assets/html/shared/user_profile.html';

require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/footer.php';
?>
