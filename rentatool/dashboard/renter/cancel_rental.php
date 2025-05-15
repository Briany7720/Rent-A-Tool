<?php
require_once '../../includes/config.php';
require_once '../../includes/db_connection.php';
require_once '../../includes/header.php';

requireLogin();

$rentalId = 0;
if (isset($_POST['rental_id'])) {
    $rentalId = (int)$_POST['rental_id'];
} elseif (isset($_GET['rental_id'])) {
    $rentalId = (int)$_GET['rental_id'];
}


if (isset($_POST['cancel_confirm'])) {
    $stmt = $pdo->prepare("UPDATE Rental SET Status = 'Canceled', ReturnDate = CURDATE() WHERE RentalID = :rentalId AND RenterID = :renterId");
    $stmt->execute([
        'rentalId' => $rentalId,
        'renterId' => $_SESSION['user_id']
    ]);
    $_SESSION['success_message'] = "Rental request has been cancelled successfully.";
    header('Location: view_rentals.php');
    exit();
}

$stmt = $pdo->prepare("
    SELECT r.*, t.Name as ToolName, t.ToolID,
           u.FirstName as OwnerFirstName, u.LastName as OwnerLastName
    FROM Rental r
    JOIN Tool t ON r.ToolID = t.ToolID
    JOIN User u ON t.OwnerID = u.UserID
    WHERE r.RentalID = :rentalId 
    AND r.RenterID = :renterId
    AND r.Status NOT IN ('cancel', 'Canceled')
");
$stmt->execute([
    'rentalId' => $rentalId,
    'renterId' => $_SESSION['user_id']
]);
$rental = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$rental) {
    header('Location: view_rentals.php');
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && !isset($_POST['cancel_confirm'])) {
}


include_once('cancel_rental.html');

?>
<script>
    document.addEventListener('DOMContentLoaded', function() {
       
        document.getElementById('toolName').textContent = '<?php echo htmlspecialchars($rental['ToolName']); ?>';
        document.getElementById('ownerName').textContent = '<?php echo htmlspecialchars($rental['OwnerFirstName'] . ' ' . $rental['OwnerLastName']); ?>';
        document.getElementById('rentalDates').textContent = '<?php 
            echo date('M d, Y', strtotime($rental['RentalStartDate'])) . ' - ' . 
            date('M d, Y', strtotime($rental['RentalEndDate'])); 
        ?>';
        document.getElementById('rentalId').value = '<?php echo $rentalId; ?>';
    });
</script>

<?php require_once '../../includes/footer.php'; ?>