<?php
require_once '../../includes/config.php';
require_once '../../includes/db_connection.php';
require_once '../../includes/header.php';

requireLogin();

$stmt = $pdo->prepare("
    SELECT r.*, t.Name as ToolName, t.PricePerDay, 
           u.FirstName as OwnerFirstName, u.LastName as OwnerLastName,
           p.PaymentAmount, p.PaymentStatus,
           rev.ReviewID
    FROM Rental r 
    JOIN Tool t ON r.ToolID = t.ToolID 
    JOIN User u ON t.OwnerID = u.UserID 
    LEFT JOIN Payment p ON r.RentalID = p.RentalID
    LEFT JOIN Review rev ON r.ToolID = rev.ReviewedEntityID 
        AND rev.ReviewerID = r.RenterID 
        AND rev.EntityType = 'Tool'
    WHERE r.RenterID = :renterId 
    ORDER BY r.RentalStartDate DESC
");
$stmt->execute(['renterId' => $_SESSION['user_id']]);
$rentals = $stmt->fetchAll(PDO::FETCH_ASSOC);
?>

<div class="container mx-auto my-8">
    <?php if (isset($_SESSION['success_message'])): ?>
        <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
            <?php 
                echo $_SESSION['success_message'];
                unset($_SESSION['success_message']);
            ?>
        </div>
    <?php endif; ?>

    <?php if (isset($_SESSION['error_message'])): ?>
        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
            <?php 
                echo $_SESSION['error_message'];
                unset($_SESSION['error_message']);
            ?>
        </div>
    <?php endif; ?>

    <div class="flex justify-between items-center mb-6">
        <h2 class="text-2xl font-bold">My Rentals</h2>
        <a href="index.php" class="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700">Back to Dashboard</a>
    </div>

    <?php if (empty($rentals)): ?>
        <p class="text-gray-600">No rentals found.</p>
    <?php else: ?>
        <div class="bg-white rounded-lg shadow-md overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Tool</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Owner</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Dates</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Payment</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    <?php foreach ($rentals as $rental): ?>
                        <tr>
                            <td class="px-6 py-4">
                                <div class="text-sm font-medium text-gray-900">
                                    <?php echo htmlspecialchars($rental['ToolName']); ?>
                                </div>
                                <div class="text-sm text-gray-500">
                                    $<?php echo number_format($rental['PricePerDay'], 2); ?> per day
                                </div>
                            </td>
                            <td class="px-6 py-4">
                                <?php echo htmlspecialchars($rental['OwnerFirstName'] . ' ' . $rental['OwnerLastName']); ?>
                            </td>
                            <td class="px-6 py-4">
                                <div class="text-sm">
                                    <?php echo date('M d, Y', strtotime($rental['RentalStartDate'])); ?> - 
                                    <?php echo date('M d, Y', strtotime($rental['RentalEndDate'])); ?>
                                </div>
                            </td>
                            <td class="px-6 py-4">
                                <span class="px-2 py-1 text-sm rounded-full 
                                    <?php 
                                    switch($rental['Status']) {
                                        case 'Pending':
                                            echo 'bg-yellow-100 text-yellow-800';
                                            break;
                                        case 'Approved':
                                            echo 'bg-green-100 text-green-800';
                                            break;
                                        case 'Completed':
                                            echo 'bg-blue-100 text-blue-800';
                                            break;
                                        case 'Rejected':
                                            echo 'bg-red-100 text-red-800';
                                            break;
                                        case 'cancel':
                                        case 'Canceled':
                                            echo 'bg-red-100 text-red-800';
                                            break;
                                        default:
                                            echo 'bg-gray-100 text-gray-800';
                                    }
                                    ?>">
                                    <?php 
                                    if ($rental['Status'] === 'cancel' || $rental['Status'] === 'Canceled') {
                                        echo 'Canceled';
                                    } elseif ($rental['Status'] === 'Rejected') {
                                        echo 'Rejected';
                                    } else {
                                        echo htmlspecialchars($rental['Status']);
                                    }
                                    ?>
                                </span>
                            </td>
                            <td class="px-6 py-4">
                                <?php if ($rental['Status'] === 'Rejected'): ?>
                                    <span class="px-2 py-1 text-sm rounded-full bg-gray-200 text-gray-600">N/A</span>
                                    <div class="text-sm text-gray-500">$0.00</div>
                                <?php else: ?>
                                    <span class="px-2 py-1 text-sm rounded-full 
                                        <?php echo $rental['PaymentStatus'] === 'Completed' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'; ?>">
                                        <?php echo $rental['PaymentStatus'] ?? 'Pending'; ?>
                                    </span>
                                    <div class="text-sm text-gray-500">
                                        $<?php echo number_format($rental['PaymentAmount'], 2); ?>
                                    </div>
                                <?php endif; ?>
                            </td>
                            <td class="px-6 py-4 text-sm">
                                <div class="space-y-2">
                                    <?php if ($rental['Status'] === 'Completed' && !isset($rental['ReviewID'])): ?>
                                        <a href="leave_review.php?rental_id=<?php echo $rental['RentalID']; ?>" 
                                           class="text-blue-600 hover:underline block">Leave Review</a>
                                    <?php endif; ?>
                                    
                                    <?php if ($rental['Status'] === 'Pending'): ?>
                                        <form method="POST" action="cancel_rental.php" 
                                              onsubmit="return confirm('Are you sure you want to cancel this rental request?');">
                                            <input type="hidden" name="rental_id" value="<?php echo $rental['RentalID']; ?>">
                                            <button type="submit" class="text-red-600 hover:underline">Cancel Request</button>
                                        </form>
                                    <?php endif; ?>

                                    <?php if ($rental['Status'] === 'Approved' && ($rental['PaymentStatus'] !== 'Completed')): ?>
                                        <a href="pay_rental.php?rental_id=<?php echo $rental['RentalID']; ?>" 
                                           class="bg-blue-600 text-white px-3 py-1 rounded hover:bg-blue-700 block text-center">Pay Now</a>
                                    <?php endif; ?>

                                    <?php if ($rental['Status'] === 'Completed' && isset($rental['ReviewID'])): ?>
                                        <span class="text-green-600">Review Submitted</span>
                                    <?php endif; ?>
                                </div>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php endif; ?>
</div>
<?php require_once '../../includes/footer.php'; ?>