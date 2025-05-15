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


$stmt = $pdo->prepare("UPDATE Rental SET Status = 'Approved' WHERE RentalID = :rentalID");
$stmt->execute(['rentalID' => $rentalID]);

header('Location: ' . BASE_URL . 'dashboard/owner/rentals.php');
exit();
?>