<?php
require_once '../../includes/config.php';
require_once '../../includes/db_connection.php';
require_once '../../includes/header.php';

requireLogin();

if (!isset($_GET['rental_id'])) {
    header('Location: view_rentals.php');
    exit();
}

$rentalId = (int)$_GET['rental_id'];

// Fetch rental details with payment info
$stmt = $pdo->prepare("
    SELECT r.*, t.Name as ToolName, t.PricePerDay, 
           u.FirstName as OwnerFirstName, u.LastName as OwnerLastName,
           p.PaymentAmount, p.PaymentStatus
    FROM Rental r
    JOIN Tool t ON r.ToolID = t.ToolID
    JOIN User u ON t.OwnerID = u.UserID
    LEFT JOIN Payment p ON r.RentalID = p.RentalID
    WHERE r.RentalID = :rentalId
      AND r.RenterID = :renterId
      AND r.Status = 'Approved'
");
$stmt->execute([
    'rentalId' => $rentalId,
    'renterId' => $_SESSION['user_id']
]);
$rental = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$rental) {
    $_SESSION['error_message'] = "Rental not found or not approved.";
    header('Location: view_rentals.php');
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Simulate payment processing
    try {
        $pdo->beginTransaction();

        // Update or insert payment record
        $stmt = $pdo->prepare("SELECT PaymentID FROM Payment WHERE RentalID = :rentalId");
        $stmt->execute(['rentalId' => $rentalId]);
        $payment = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($payment) {
            $stmt = $pdo->prepare("
                UPDATE Payment 
                SET PaymentStatus = 'Completed', PaymentDate = NOW()
                WHERE PaymentID = :paymentId
            ");
            $stmt->execute(['paymentId' => $payment['PaymentID']]);
        } else {
            $stmt = $pdo->prepare("
                INSERT INTO Payment (RentalID, PaymentAmount, PaymentStatus, PaymentDate)
                VALUES (:rentalId, :amount, 'Completed', NOW())
            ");
            $stmt->execute([
                'rentalId' => $rentalId,
                'amount' => $rental['TotalPrice']
            ]);
        }

        // Optionally update Rental status to 'Paid' or keep as 'Approved'
        // For now, keep as 'Approved' to allow further processing

        // Insert notifications for renter and owner
        $renterId = $_SESSION['user_id'];
        $ownerIdStmt = $pdo->prepare("SELECT OwnerID FROM Tool WHERE ToolID = :toolId");
        $ownerIdStmt->execute(['toolId' => $rental['ToolID']]);
        $ownerId = $ownerIdStmt->fetchColumn();

        $notificationStmt = $pdo->prepare("
            INSERT INTO Notification (UserID, Message) VALUES (:userId, :message)
        ");

        $notificationStmt->execute([
            'userId' => $renterId,
            'message' => "Payment completed for rental of tool '{$rental['ToolName']}'."
        ]);

        $notificationStmt->execute([
            'userId' => $ownerId,
            'message' => "Rental payment received for your tool '{$rental['ToolName']}'."
        ]);

        $pdo->commit();

        $_SESSION['success_message'] = "Payment completed successfully!";
        header('Location: view_rentals.php');
        exit();

    } catch (Exception $e) {
        $pdo->rollBack();
        $error = "Payment failed: " . $e->getMessage();
    }
}


include_once('pay_rental.html');


?>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        document.getElementById('toolName').textContent = '<?php echo htmlspecialchars($rental['ToolName']); ?>';
        document.getElementById('ownerName').textContent = '<?php echo htmlspecialchars($rental['OwnerFirstName'] . ' ' . $rental['OwnerLastName']); ?>';
        document.getElementById('rentalDates').textContent = '<?php 
            echo date('M d, Y', strtotime($rental['RentalStartDate'])) . ' - ' . 
            date('M d, Y', strtotime($rental['RentalEndDate'])); 
        ?>';
        document.getElementById('totalPrice').textContent = '<?php echo number_format($rental['TotalPrice'], 2); ?>';
        document.getElementById('paymentStatus').textContent = '<?php echo htmlspecialchars($rental['PaymentStatus'] ?? 'Pending'); ?>';
        
        
        <?php if (isset($error)): ?>
        const errorMsg = document.getElementById('error-message');
        errorMsg.style.display = 'block';
        document.getElementById('error-text').textContent = '<?php echo addslashes($error); ?>';
        <?php endif; ?>
    });
</script>

<?php require_once '../../includes/footer.php'; ?>