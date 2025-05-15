<?php
require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/config.php';
require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/db_connection.php';
require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/header.php';

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
    SELECT r.*, t.Name as ToolName, t.Description as ToolDescription, 
           u.FirstName, u.LastName, u.Email, u.PhoneNumber as Phone, u.ReputationScore
    FROM Rental r
    JOIN Tool t ON r.ToolID = t.ToolID
    JOIN User u ON r.RenterID = u.UserID
    WHERE r.RentalID = :rentalID AND t.OwnerID = :ownerID
");
$stmt->execute(['rentalID' => $rentalID, 'ownerID' => $_SESSION['user_id']]);
$rental = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$rental) {
    header('Location: ' . BASE_URL . 'dashboard/owner/rentals.php');
    exit();
}


$isCompleted = ($rental['Status'] === 'Completed');


$reviewComment = null;
if ($isCompleted) {
    $stmt = $pdo->prepare("SELECT Comment FROM Review WHERE RentalID = :rentalID AND ReviewerID = :ownerID AND EntityType = 'User' LIMIT 1");
    $stmt->execute(['rentalID' => $rentalID, 'ownerID' => $_SESSION['user_id']]);
    $reviewComment = $stmt->fetchColumn();
}

include __DIR__ . '/../../assets/html/owner/rental_detail.html';

require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/footer.php';
?>