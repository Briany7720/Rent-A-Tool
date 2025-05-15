<?php
require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/config.php';
require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/db_connection.php';
require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/header.php';

requireLogin(); 
if (getUserType() !== 'Owner') {
    header('Location: ' . BASE_URL . 'dashboard/renter/index.php');
    exit();
}




$stmt = $pdo->prepare("SELECT COUNT(*) FROM Tool WHERE OwnerID = :ownerID");
$stmt->execute(['ownerID' => $_SESSION['user_id']]);
$toolCount = $stmt->fetchColumn();

if ($toolCount == 0) {
    $rentalRequests = [];
} else {
  
    try {
        $stmt = $pdo->prepare("
            SELECT r.*, t.Name as ToolName, u.FirstName, u.LastName, u.Email
            FROM Rental r
            JOIN Tool t ON r.ToolID = t.ToolID
            JOIN User u ON r.RenterID = u.UserID
            WHERE t.OwnerID = :ownerID AND r.Status != 'Rejected'
            ORDER BY r.RentalID DESC
        ");
        $stmt->execute(['ownerID' => $_SESSION['user_id']]);
        $rentalRequests = $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        error_log("Database error: " . $e->getMessage());
        $rentalRequests = [];
    }
}

include __DIR__ . '/../../assets/html/owner/rentals.html';

require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/footer.php';
?>