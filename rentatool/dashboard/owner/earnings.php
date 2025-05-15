<?php
require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/config.php';
require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/db_connection.php';
require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/header.php';

requireLogin(); 

if (getUserType() !== 'Owner') {
    header('Location: ' . BASE_URL . 'dashboard/renter/index.php');
    exit();
}

$stmt = $pdo->prepare("
    SELECT 
        t.Name,
        SUM(
            (DATEDIFF(
                r.RentalEndDate,
                r.RentalStartDate
            ) + 1) * t.PricePerDay
        ) AS earnings
    FROM Tool t
    JOIN Rental r ON t.ToolID = r.ToolID
    WHERE t.OwnerID = :ownerID
      AND r.Status = 'Approved'
    GROUP BY t.ToolID, t.Name
    ORDER BY earnings DESC
");
$stmt->execute([
    'ownerID' => $_SESSION['user_id']
]);
$earningsPerTool = $stmt->fetchAll(PDO::FETCH_ASSOC);

$depositStmt = $pdo->prepare("
    SELECT 
        SUM(DepositFee) as depositEarnings
    FROM Rental r
    JOIN Tool t ON r.ToolID = t.ToolID
    WHERE t.OwnerID = :ownerID
      AND r.Status = 'Completed'
      AND (
        (r.ReturnDate > r.RentalEndDate AND r.ReturnDate IS NOT NULL) OR r.ReturnDate IS NULL
      )
");
$depositStmt->execute([
    'ownerID' => $_SESSION['user_id']
]);
$depositEarnings = $depositStmt->fetchColumn();

?>

<div class="container mx-auto my-8">
    <h2 class="text-2xl font-bold mb-4">Earnings</h2>

    <div class="mb-6">
        <h3 class="text-xl font-semibold mb-2">Total Earnings from Rentals</h3>
        <ul class="list-disc list-inside">
            <?php foreach ($earningsPerTool as $toolEarnings): ?>
                <li><?php echo htmlspecialchars($toolEarnings['Name']); ?>: $<?php echo number_format($toolEarnings['earnings'], 2); ?></li>
            <?php endforeach; ?>
        </ul>
    </div>

    <div>
        <h3 class="text-xl font-semibold mb-2">Earnings from Deposits (Late or Non-Returns)</h3>
        <p class="text-lg font-medium">$<?php echo number_format($depositEarnings ?: 0, 2); ?></p>
    </div>
</div>

<?php require_once $_SERVER['DOCUMENT_ROOT'] . '/rentatool/includes/footer.php'; ?>
