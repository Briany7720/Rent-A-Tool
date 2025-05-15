<?php
require_once '../../includes/config.php';
require_once '../../includes/db_connection.php';
require_once '../../includes/header.php';
require_once '../../includes/photo_utils.php';

requireLogin();

if (!isset($_GET['tool_id'])) {
    header('Location: search_tools.php');
    exit();
}


$stmt = $pdo->prepare("
    SELECT t.*, u.FirstName, u.LastName, u.ReputationScore
    FROM Tool t
    JOIN User u ON t.OwnerID = u.UserID
    WHERE t.ToolID = :toolID AND t.AvailabilityStatus = 'Available'
");
$stmt->execute(['toolID' => $_GET['tool_id']]);
$tool = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$tool) {
    header('Location: search_tools.php');
    exit();
}


$photos = getToolPhotos($tool['ToolID']);


if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        
        $startDate = new DateTime($_POST['start_date']);
        $endDate = new DateTime($_POST['end_date']);
        $duration = $startDate->diff($endDate)->days + 1;

        
        $overlapStmt = $pdo->prepare("
            SELECT COUNT(*) FROM Rental
            WHERE ToolID = :toolID
              AND Status NOT IN ('Rejected', 'Cancelled')
              AND (
                (RentalStartDate <= :endDate AND COALESCE(ReturnDate, RentalEndDate) >= :startDate)
              )
        ");
        $overlapStmt->execute([
            'toolID' => $tool['ToolID'],
            'startDate' => $startDate->format('Y-m-d'),
            'endDate' => $endDate->format('Y-m-d')
        ]);
        $overlapCount = $overlapStmt->fetchColumn();

        if ($overlapCount > 0) {
            throw new Exception("The tool is already rented for the selected period. Please choose different dates.");
        }
        
        $basePrice = $tool['PricePerDay'] * $duration;
        $depositFee = $basePrice * 0.5; // 50% deposit
        $serviceFee = $basePrice * 0.1; // 10% service fee
        $totalPrice = $basePrice + $depositFee + $serviceFee;

        
        $pdo->beginTransaction();

        
        $stmt = $pdo->prepare("
            INSERT INTO Rental (
                ToolID, RenterID, RentalStartDate, RentalEndDate,
                BaseRentalPrice, DepositFee, ServiceFee, TotalPrice, Status
            ) VALUES (
                :toolID, :renterID, :startDate, :endDate,
                :basePrice, :depositFee, :serviceFee, :totalPrice, 'Pending'
            )
        ");

        $stmt->execute([
            'toolID' => $tool['ToolID'],
            'renterID' => $_SESSION['user_id'],
            'startDate' => $startDate->format('Y-m-d'),
            'endDate' => $endDate->format('Y-m-d'),
            'basePrice' => $basePrice,
            'depositFee' => $depositFee,
            'serviceFee' => $serviceFee,
            'totalPrice' => $totalPrice
        ]);

        $rentalID = $pdo->lastInsertId();

       
        $stmt = $pdo->prepare("
            INSERT INTO Payment (RentalID, PaymentAmount, PaymentStatus)
            VALUES (:rentalID, :amount, 'Pending')
        ");

        $stmt->execute([
            'rentalID' => $rentalID,
            'amount' => $totalPrice
        ]);

    
        $stmt = $pdo->prepare("
            INSERT INTO Notification (UserID, Message)
            VALUES (:ownerID, :message)
        ");

        $stmt->execute([
            'ownerID' => $tool['OwnerID'],
            'message' => "New rental request for your tool: " . $tool['Name']
        ]);

        $pdo->commit();
        $success = "Rental request submitted successfully!";

    } catch (Exception $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        $error = $e->getMessage() ?: "Error processing rental request. Please try again.";
    }
}


include_once('../../assets/html/renter/rent_tool.html');


?>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        
        document.getElementById('toolName').textContent = '<?php echo htmlspecialchars($tool['Name']); ?>';
        document.getElementById('toolCategory').textContent = '<?php echo htmlspecialchars($tool['Category']); ?>';
        document.getElementById('toolPrice').textContent = '$<?php echo number_format($tool['PricePerDay'], 2); ?>';
        document.getElementById('ownerName').textContent = '<?php echo htmlspecialchars($tool['FirstName'] . ' ' . $tool['LastName']); ?>';
        document.getElementById('ownerRating').textContent = '(Rating: <?php echo number_format($tool['ReputationScore'], 1); ?>★)';
        
        
        document.getElementById('ownerProfileLink').href = '<?php echo BASE_URL; ?>dashboard/shared/user_profile.php?user_id=<?php echo $tool['OwnerID']; ?>';
        
        
        const today = new Date().toISOString().split('T')[0];
        document.getElementById('startDateInput').min = today;
        document.getElementById('endDateInput').min = today;
        
        
        const photosContainer = document.getElementById('photos-container');
        <?php if (!empty($photos)): ?>
            <?php foreach ($photos as $photo): ?>
            const img = document.createElement('img');
            img.src = '<?php echo htmlspecialchars(BASE_URL . $photo['PhotoPath']); ?>';
            img.alt = 'Tool Photo';
            img.className = 'h-32 rounded-md object-cover';
            photosContainer.appendChild(img);
            <?php endforeach; ?>
        <?php else: ?>
            photosContainer.style.display = 'none';
        <?php endif; ?>
        
        
        <?php if (isset($success)): ?>
        const successMsg = document.getElementById('success-message');
        successMsg.style.display = 'block';
        document.getElementById('success-text').innerHTML = '<?php echo $success; ?>';
        <?php endif; ?>
        
        <?php if (isset($error)): ?>
        const errorMsg = document.getElementById('error-message');
        errorMsg.style.display = 'block';
        document.getElementById('error-text').textContent = '<?php echo addslashes($error); ?>';
        <?php endif; ?>
    });
</script>

<?php require_once '../../includes/footer.php'; ?>