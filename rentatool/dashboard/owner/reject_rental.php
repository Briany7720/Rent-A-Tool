<?php
require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/config.php';
require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/db_connection.php';

requireLogin(); 
if (getUserType() !== 'Owner') {
    header('Location: ' . BASE_URL . 'dashboard/renter/index.php');
    exit();
}

if (!isset($_GET['id'])) {
    header('Location: ' . BASE_URL . 'dashboard/owner/rentals.php');
    exit();
}

$rentalID = $_GET['id'];


$stmt = $pdo->prepare("
    SELECT r.* FROM Rental r
    JOIN Tool t ON r.ToolID = t.ToolID
    WHERE r.RentalID = :rentalID AND t.OwnerID = :ownerID
");
$stmt->execute(['rentalID' => $rentalID, 'ownerID' => $_SESSION['user_id']]);
$rental = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$rental) {
    header('Location: ' . BASE_URL . 'dashboard/owner/rentals.php');
    exit();
}

if ($rental['Status'] !== 'Rejected') {
    $stmt = $pdo->prepare("UPDATE Rental SET Status = 'Rejected', ReturnDate = CURDATE() WHERE RentalID = :rentalID");
    if (!$stmt->execute(['rentalID' => $rentalID])) {
        error_log("Failed to update ReturnDate for rejected rental ID: $rentalID");
    }
}

header('Location: ' . BASE_URL . 'dashboard/owner/rentals.php');
exit();
?>