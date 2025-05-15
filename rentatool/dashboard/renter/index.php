<?php
require_once '../../includes/config.php';
require_once '../../includes/db_connection.php';
require_once '../../includes/header.php';

requireLogin(); 


$stmt = $pdo->prepare("
    SELECT 
        u.*,
        DATE_FORMAT(u.RegistrationDate, '%M %Y') as JoinDate,
        COUNT(DISTINCT CASE WHEN r.Status != 'Rejected' THEN r.RentalID END) as TotalRentals,
        u.ReputationScore as AverageRating,
        u.ReviewCount as TotalReviews
    FROM User u
    LEFT JOIN Rental r ON u.UserID = r.RenterID
    WHERE u.UserID = :userId
    GROUP BY u.UserID
");
$stmt->execute(['userId' => $_SESSION['user_id']]);
$userStats = $stmt->fetch(PDO::FETCH_ASSOC);


$notifStmt = $pdo->prepare("
    SELECT NotificationID, Message, NotificationTimestamp 
    FROM Notification 
    WHERE UserID = ? AND IsRead = 0
    ORDER BY NotificationTimestamp DESC
    LIMIT 5
");
$notifStmt->execute([$_SESSION['user_id']]);
$notifications = $notifStmt->fetchAll(PDO::FETCH_ASSOC);


$stmt = $pdo->prepare("
    SELECT r.*, t.Name as ToolName, t.PricePerDay, 
           u.FirstName as OwnerFirstName, u.LastName as OwnerLastName,
           p.PaymentAmount, p.PaymentStatus
    FROM Rental r 
    JOIN Tool t ON r.ToolID = t.ToolID 
    JOIN User u ON t.OwnerID = u.UserID 
    LEFT JOIN Payment p ON r.RentalID = p.RentalID
    WHERE r.RenterID = :renterId AND r.Status IN ('Pending', 'Approved')
    ORDER BY r.RentalStartDate DESC
");
$stmt->execute(['renterId' => $_SESSION['user_id']]);
$activeRentals = $stmt->fetchAll(PDO::FETCH_ASSOC);


$stmt = $pdo->prepare("
    SELECT r.*, t.Name as ToolName, t.PricePerDay, 
           u.FirstName as OwnerFirstName, u.LastName as OwnerLastName,
           p.PaymentAmount, p.PaymentStatus
    FROM Rental r 
    JOIN Tool t ON r.ToolID = t.ToolID 
    JOIN User u ON t.OwnerID = u.UserID 
    LEFT JOIN Payment p ON r.RentalID = p.RentalID
    WHERE r.RenterID = :renterId AND r.Status = 'Completed'
    ORDER BY r.RentalStartDate DESC
");
$stmt->execute(['renterId' => $_SESSION['user_id']]);
$rentalHistory = $stmt->fetchAll(PDO::FETCH_ASSOC);
?>

<div class="container mx-auto my-8">
    
    <div class="bg-white p-6 rounded-lg shadow-md mb-6">
        <div class="flex justify-between items-start">
            <div>
                <h1 class="text-2xl font-bold mb-2">Welcome, <?= htmlspecialchars($userStats['FirstName'] . ' ' . $userStats['LastName']) ?></h1>
                <div class="flex items-center mb-2">
                    <?php 
                    $rating = number_format($userStats['AverageRating'], 1);
                    $fullStars = floor($rating);
                    $emptyStars = 5 - $fullStars;
                    ?>
                    <div class="text-yellow-400 text-xl">
                        <?= str_repeat('★', $fullStars) . str_repeat('☆', $emptyStars) ?>
                    </div>
<span class="ml-2 text-gray-600">(<?= $rating ?> from <?= $userStats['TotalReviews'] ?> reviews)</span>
                </div>
                <p class="text-gray-600">Member since: <?= $userStats['JoinDate'] ? date('F j, Y', strtotime($userStats['RegistrationDate'])) : 'Not available' ?></p>
            </div>
            
            <span class="bg-blue-100 text-blue-800 text-sm font-medium px-2.5 py-0.5 rounded">
                <?= $userStats['TotalRentals'] >= 20 ? 'Expert Renter' : ($userStats['TotalRentals'] >= 10 ? 'Regular Renter' : 'New Renter') ?>
            </span>
        </div>
    </div>
    <div class="flex justify-between items-center mb-8">
        <h2 class="text-2xl font-bold">Renter Dashboard</h2>
        <div class="space-x-4">
            <a href="search_tools.php" class="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700">Search Tools</a>
            <a href="view_rentals.php" class="bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700">View All Rentals</a>
        </div>
    </div>

    
    <div class="bg-white p-6 rounded-lg shadow-md mb-8">
        <h3 class="text-xl font-semibold mb-4">Active Rentals</h3>
        <?php if (empty($activeRentals)): ?>
            <p class="text-gray-600">No active rentals found.</p>
        <?php else: ?>
            <div class="overflow-x-auto">
                <table class="w-full">
                    <thead class="bg-gray-50">
                        <tr>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Tool</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Owner</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Dates</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Time Left</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Total</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-200">
                        <?php foreach ($activeRentals as $rental): ?>
                            <tr>
                                <td class="px-6 py-4"><?php echo htmlspecialchars($rental['ToolName']); ?></td>
                                <td class="px-6 py-4">
                                    <?php echo htmlspecialchars($rental['OwnerFirstName'] . ' ' . $rental['OwnerLastName']); ?>
                                </td>
                                <td class="px-6 py-4">
                                    <?php echo date('M d, Y', strtotime($rental['RentalStartDate'])); ?> - 
                                    <?php echo date('M d, Y', strtotime($rental['RentalEndDate'])); ?>
                                </td>
                                <td class="px-6 py-4">
                                    <span class="countdown-timer" data-starttime="<?php echo htmlspecialchars($rental['RentalStartDate']); ?>" data-endtime="<?php echo htmlspecialchars($rental['RentalEndDate']); ?>"></span>
                                </td>
                                <td class="px-6 py-4">
                                    <span class="px-2 py-1 text-sm rounded-full 
                                        <?php echo $rental['Status'] === 'Approved' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'; ?>">
                                        <?php echo $rental['Status']; ?>
                                    </span>
                                </td>
                                <td class="px-6 py-4">
                                    <?php if (isset($rental['PaymentAmount'])): ?>
                                        $<?php echo number_format($rental['PaymentAmount'], 2); ?>
                                        <span class="ml-2 px-2 py-1 text-xs rounded-full 
                                            <?php echo $rental['PaymentStatus'] === 'Paid' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'; ?>">
                                            <?php echo $rental['PaymentStatus'] ?? 'Pending'; ?>
                                        </span>
                                    <?php else: ?>
                                        Pending
                                    <?php endif; ?>
                                </td>
                                <td class="px-6 py-4">
                                    <?php if ($rental['Status'] === 'Approved'): ?>
                                        <a href="return_tool.php?id=<?php echo $rental['RentalID']; ?>" 
                                           class="inline-block bg-blue-600 text-white px-3 py-1 rounded hover:bg-blue-700">
                                            Mark as Returned
                                        </a>
                                    <?php else: ?>
                                        -
                                    <?php endif; ?>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php endif; ?>
    </div>

    
    <div class="bg-white p-6 rounded-lg shadow-md">
        <h3 class="text-xl font-semibold mb-4">Rental History</h3>
        <?php if (empty($rentalHistory)): ?>
            <p class="text-gray-600">No rental history found.</p>
        <?php else: ?>
            <div class="overflow-x-auto">
                <table class="w-full">
                    <thead class="bg-gray-50">
                        <tr>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Tool</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Owner</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Dates</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Total</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-200">
                        <?php foreach ($rentalHistory as $rental): ?>
                            <tr>
                                <td class="px-6 py-4"><?php echo htmlspecialchars($rental['ToolName']); ?></td>
                                <td class="px-6 py-4">
                                    <?php echo htmlspecialchars($rental['OwnerFirstName'] . ' ' . $rental['OwnerLastName']); ?>
                                </td>
                                <td class="px-6 py-4">
                                    <?php echo date('M d, Y', strtotime($rental['RentalStartDate'])); ?> - 
                                    <?php echo date('M d, Y', strtotime($rental['RentalEndDate'])); ?>
                                </td>
                                <td class="px-6 py-4">
                                    <?php if (isset($rental['PaymentAmount'])): ?>
                                        $<?php echo number_format($rental['PaymentAmount'], 2); ?>
                                        <span class="ml-2 px-2 py-1 text-xs rounded-full 
                                            <?php echo $rental['PaymentStatus'] === 'Paid' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'; ?>">
                                            <?php echo $rental['PaymentStatus'] ?? 'Pending'; ?>
                                        </span>
                                    <?php else: ?>
                                        Pending
                                    <?php endif; ?>
                                </td>
                                <td class="px-6 py-4">
                                    <a href="leave_review.php?rental_id=<?php echo $rental['RentalID']; ?>" 
                                       class="text-blue-600 hover:underline">Leave Review</a>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php endif; ?>
    </div>
</div>

<script src="<?= BASE_URL ?>assets/js/rental_countdown.js"></script>
<?php require_once '../../includes/footer.php'; ?>
