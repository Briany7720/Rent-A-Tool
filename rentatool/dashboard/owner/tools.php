<?php


if (isset($_GET['ajax_action']) && isset($_GET['tool_id'])) {
    require_once '../../includes/config.php';
    require_once '../../includes/db_connection.php';
    require_once '../../includes/photo_utils.php';
    session_start();

    $toolId = (int)$_GET['tool_id'];

    try {
        
        $stmt = $pdo->prepare("SELECT ToolID FROM Tool WHERE ToolID = :toolId AND OwnerID = :ownerId");
        $stmt->execute(['toolId' => $toolId, 'ownerId' => $_SESSION['user_id']]);
        if (!$stmt->fetch()) {
            jsonResponse(false, 'Unauthorized or invalid tool');
        }

        switch ($_GET['ajax_action']) {
            case 'delete_photo':
                if (!isset($_GET['photo_id'])) {
                    throw new Exception('Photo ID missing');
                }
                $photoId = (int)$_GET['photo_id'];
                deleteToolPhoto($toolId, $photoId);
                jsonResponse(true, 'Photo deleted');
                break;

            case 'set_primary':
                if (!isset($_GET['photo_id'])) {
                    throw new Exception('Photo ID missing');
                }
                $photoId = (int)$_GET['photo_id'];
                setPrimaryPhoto($toolId, $photoId);
                jsonResponse(true, 'Primary photo set');
                break;

            case 'delete_tool':
                
                $photos = getToolPhotos($toolId);
                foreach ($photos as $photo) {
                    deleteToolPhoto($toolId, $photo['PhotoID']);
                }
                
                $stmtDelRentals = $pdo->prepare("DELETE FROM Rental WHERE ToolID = :toolId");
                $stmtDelRentals->execute(['toolId' => $toolId]);
                
                $stmtDelTool = $pdo->prepare("DELETE FROM Tool WHERE ToolID = :toolId AND OwnerID = :ownerId");
                $stmtDelTool->execute(['toolId' => $toolId, 'ownerId' => $_SESSION['user_id']]);
                jsonResponse(true, 'Tool deleted');
                break;

            default:
                jsonResponse(false, 'Unknown action');
        }
    } catch (Exception $e) {
        jsonResponse(false, 'Error: ' . $e->getMessage());
    }
    exit();
}

require_once '../../includes/config.php';
require_once '../../includes/db_connection.php';
require_once '../../includes/header.php';
require_once '../../includes/photo_utils.php';

requireLogin();

ob_start();
ob_end_flush();


$stmt = $pdo->prepare("
    SELECT t.*, 
           COUNT(DISTINCT r.RentalID) as rental_count,
           AVG(rev.Rating) as avg_rating
    FROM Tool t
    LEFT JOIN Rental r ON t.ToolID = r.ToolID AND r.Status NOT IN ('Rejected', 'Cancelled')
    LEFT JOIN Review rev ON t.ToolID = rev.ReviewedEntityID AND rev.EntityType = 'Tool'
    WHERE t.OwnerID = :ownerID
    GROUP BY t.ToolID
    ORDER BY t.DateAdded DESC
");
$stmt->execute(['ownerID' => $_SESSION['user_id']]);
$tools = $stmt->fetchAll(PDO::FETCH_ASSOC);

$toolRentals = [];
foreach ($tools as $tool) {
    $stmtRentals = $pdo->prepare("
        SELECT r.RentalID, r.RentalStartDate, r.RentalEndDate, r.Status, u.UserID, u.FirstName, u.LastName
        FROM Rental r
        JOIN User u ON r.RenterID = u.UserID
        WHERE r.ToolID = :toolId AND r.Status NOT IN ('Rejected', 'Cancelled')
        ORDER BY r.RentalStartDate
    ");
    $stmtRentals->execute(['toolId' => $tool['ToolID']]);
    $rentals = $stmtRentals->fetchAll(PDO::FETCH_ASSOC);
    $toolRentals[$tool['ToolID']] = $rentals;
}


$toolBookings = [];
foreach ($tools as $tool) {
    $stmtBookings = $pdo->prepare("
        SELECT RentalStartDate, RentalEndDate
        FROM Rental
        WHERE ToolID = :toolId AND Status NOT IN ('Rejected', 'Cancelled') AND ReturnDate IS NULL
        ORDER BY RentalStartDate
    ");
    $stmtBookings->execute(['toolId' => $tool['ToolID']]);
    $bookings = $stmtBookings->fetchAll(PDO::FETCH_ASSOC);
    $toolBookings[$tool['ToolID']] = $bookings;
}


if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        if (isset($_POST['action'])) {
            if ($_POST['action'] === 'add') {
                $stmt = $pdo->prepare("
                    INSERT INTO Tool (OwnerID, Name, Description, PricePerDay, Category, Location, DeliveryOption, DeliveryPrice)
                    VALUES (:ownerID, :name, :description, :pricePerDay, :category, :location, :deliveryOption, :deliveryPrice)
                ");
                
                $stmt->execute([
                    'ownerID' => $_SESSION['user_id'],
                    'name' => sanitizeInput($_POST['name']),
                    'description' => sanitizeInput($_POST['description']),
                    'pricePerDay' => floatval($_POST['pricePerDay']),
                    'category' => sanitizeInput($_POST['category']),
                    'location' => sanitizeInput($_POST['location']),
                    'deliveryOption' => sanitizeInput($_POST['deliveryOption']),
                    'deliveryPrice' => floatval($_POST['deliveryPrice'])
                ]);

                
                $toolId = $pdo->lastInsertId();

               
                if (isset($_FILES['photos'])) {
                    $allowedTypes = ['image/jpeg', 'image/png', 'image/gif'];
                    $maxSize = 5 * 1024 * 1024; // 5MB

                    foreach ($_FILES['photos']['error'] as $key => $errorCode) {
                        if ($errorCode === UPLOAD_ERR_OK) {
                            $fileType = $_FILES['photos']['type'][$key];
                            $fileSize = $_FILES['photos']['size'][$key];
                            $fileTmpName = $_FILES['photos']['tmp_name'][$key];
                            $fileName = $_FILES['photos']['name'][$key];

                            if (in_array($fileType, $allowedTypes) && $fileSize <= $maxSize) {
                                $fileArray = [
                                    'name' => $fileName,
                                    'type' => $fileType,
                                    'tmp_name' => $fileTmpName,
                                    'error' => $errorCode,
                                    'size' => $fileSize
                                ];
                                uploadToolPhoto($toolId, $fileArray);
                            } else {
                                $error = "Invalid photo - must be JPEG, PNG or GIF under 5MB";
                                break;
                            }
                        }
                    }
                }

                $success = "Tool added successfully!";
                header("Location: tools.php");
                exit();
            } else if ($_POST['action'] === 'edit' && isset($_POST['toolID'])) {
                $toolId = (int)$_POST['toolID'];
                $stmt = $pdo->prepare("
                    UPDATE Tool 
                    SET Name = :name,
                        Description = :description,
                        PricePerDay = :pricePerDay,
                        Category = :category,
                        AvailabilityStatus = :status,
                        Location = :location,
                        DeliveryOption = :deliveryOption,
                        DeliveryPrice = :deliveryPrice
                    WHERE ToolID = :toolID AND OwnerID = :ownerID
                ");

                $stmt->execute([
                    'name' => sanitizeInput($_POST['name']),
                    'description' => sanitizeInput($_POST['description']),
                    'pricePerDay' => floatval($_POST['pricePerDay']),
                    'category' => sanitizeInput($_POST['category']),
                    'status' => sanitizeInput($_POST['status']),
                    'location' => sanitizeInput($_POST['location']),
                    'deliveryOption' => sanitizeInput($_POST['deliveryOption']),
                    'deliveryPrice' => floatval($_POST['deliveryPrice']),
                    'toolID' => $toolId,
                    'ownerID' => $_SESSION['user_id']
                ]);

                
                if (isset($_FILES['photos'])) {
                    $allowedTypes = ['image/jpeg', 'image/png', 'image/gif'];
                    $maxSize = 5 * 1024 * 1024; // 5MB

                    foreach ($_FILES['photos']['error'] as $key => $errorCode) {
                        if ($errorCode === UPLOAD_ERR_OK) {
                            $fileType = $_FILES['photos']['type'][$key];
                            $fileSize = $_FILES['photos']['size'][$key];
                            $fileTmpName = $_FILES['photos']['tmp_name'][$key];
                            $fileName = $_FILES['photos']['name'][$key];

                            if (in_array($fileType, $allowedTypes) && $fileSize <= $maxSize) {
                                $fileArray = [
                                    'name' => $fileName,
                                    'type' => $fileType,
                                    'tmp_name' => $fileTmpName,
                                    'error' => $errorCode,
                                    'size' => $fileSize
                                ];
                                uploadToolPhoto($toolId, $fileArray);
                            } else {
                                $error = "Invalid photo - must be JPEG, PNG or GIF under 5MB";
                                break;
                            }
                        }
                    }
                }

                $success = "Tool updated successfully!";
                header("Location: tools.php");
                exit();
            }
        }
    } catch (Exception $e) {
        $error = "Error processing request: " . $e->getMessage();
    }
}


$toolPhotosMap = [];
foreach ($tools as $tool) {
    $toolPhotosMap[$tool['ToolID']] = getToolPhotos($tool['ToolID']);
}
?>

<div class="container mx-auto my-8">
    <div class="flex justify-between items-center mb-6">
        <h2 class="text-2xl font-bold">Manage Tools</h2>
        <button onclick="showAddToolModal()" 
                class="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700">
            Add New Tool
        </button>
    </div>

    <?php if (isset($success)): ?>
        <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
            <?php echo $success; ?>
        </div>
    <?php endif; ?>

    <?php if (isset($error)): ?>
        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
            <?php echo $error; ?>
        </div>
    <?php endif; ?>

   
    <div class="bg-white rounded-lg shadow overflow-hidden">
        <?php if (empty($tools)): ?>
            <p class="p-6 text-gray-600">No tools listed yet. Add your first tool!</p>
        <?php else: ?>
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Category</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Price/Day</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Rating</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Booked Dates</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    <?php foreach ($tools as $tool): ?>
                        <tr>
                        <td class="px-6 py-4">
                            <div class="text-sm font-medium text-gray-900">
                                <?php echo htmlspecialchars($tool['Name']); ?>
                            </div>
                            <div class="text-sm text-gray-500">
                                <?php echo htmlspecialchars($tool['Description'] ?? ''); ?>
                            </div>
                            <div class="text-sm text-gray-400 mt-1">
                                <?php echo htmlspecialchars($tool['Location'] ?? ''); ?>
                            </div>
                        </td>
                        <td class="px-6 py-4 text-sm text-gray-500">
                            <?php echo htmlspecialchars($tool['Category']); ?>
                        </td>
                        <td class="px-6 py-4 text-sm text-gray-500">
                            $<?php echo number_format($tool['PricePerDay'], 2); ?>
                        </td>
                        <td class="px-6 py-4">
                            <span class="px-2 py-1 text-sm rounded-full 
                                <?php echo $tool['AvailabilityStatus'] === 'Available' ? 
                                    'bg-green-100 text-green-800' : 
                                    ($tool['AvailabilityStatus'] === 'Rented' ? 
                                        'bg-blue-100 text-blue-800' : 
                                        'bg-red-100 text-red-800'); ?>">
                                <?php echo $tool['AvailabilityStatus']; ?>
                            </span>
                        </td>
                        <td class="px-6 py-4 text-sm text-gray-500">
                            <?php 
                                echo $tool['avg_rating'] ? 
                                    number_format($tool['avg_rating'], 1) . ' ★' : 
                                    'No ratings';
                            ?>
                        </td>
                        <td class="px-6 py-4 text-sm text-gray-700 max-w-xs">
                            <?php
                            $bookings = $toolBookings[$tool['ToolID']] ?? [];
                            if (empty($bookings)) {
                                echo 'No bookings';
                            } else {
                                echo '<ul class="list-disc list-inside">';
                                foreach ($bookings as $booking) {
                                    echo '<li>' . date('M d, Y', strtotime($booking['RentalStartDate'])) . ' - ' . date('M d, Y', strtotime($booking['RentalEndDate'])) . '</li>';
                                }
                                echo '</ul>';
                            }
                            ?>
                        </td>
                            <td class="px-6 py-4 text-sm">
                                <button onclick="showRentalDetailsModal(<?php echo $tool['ToolID']; ?>)"
                                        class="text-blue-600 hover:text-blue-900">
                                    View Rentals
                                </button>

                                <button onclick="showEditToolModal(<?php echo $tool['ToolID']; ?>)"
                                        class="ml-2 text-green-600 hover:text-green-900">
                                    Edit Tool
                                </button>
                
                                <button onclick="deleteTool(<?php echo $tool['ToolID']; ?>)"
                                        class="ml-2 text-red-600 hover:text-red-900">
                                    Delete Tool
                                </button>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        <?php endif; ?>
    </div>
</div>


<div id="addToolModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 hidden">
    <div class="flex items-center justify-center min-h-screen">
        <div class="bg-white w-full max-w-md p-6 rounded-lg shadow-xl">
            <h3 class="text-xl font-bold mb-4">Add New Tool</h3>
            <form method="POST" action="" enctype="multipart/form-data" onsubmit="return validateToolForm(this)">
                <input type="hidden" name="action" value="add">
                
                <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-700">Tool Name</label>
                    <input type="text" name="name" required
                           class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200">
                </div>

                <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-700">Description</label>
                    <textarea name="description" required
                              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200"></textarea>
                </div>

                <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-700">Location</label>
                    <input type="text" name="location" required
                           class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200"
                           placeholder="Enter tool location">
                </div>

                <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-700">Delivery Option</label>
                    <select name="deliveryOption" id="deliveryOption" required
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200"
                            onchange="toggleDeliveryPriceInput()">
                        <option value="Pickup Only">Pickup Only</option>
                        <option value="Delivery Available">Delivery Available</option>
                    </select>
                </div>

                <div class="mb-4" id="deliveryPriceContainer" style="display:none;">
                    <label class="block text-sm font-medium text-gray-700">Delivery Price</label>
                    <input type="number" name="deliveryPrice" step="0.01" min="0" value="0"
                           class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200"
                           placeholder="Enter delivery price (optional)">
                </div>

                

                <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-700">Price per Day</label>
                    <input type="number" name="pricePerDay" step="0.01" min="0" required
                           class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200">
                </div>

                <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-700">Category</label>
                    <select name="category" required
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200">
                        <option value="">Select category</option>
                        <option value="Hand Tools">Hand Tools</option>
                        <option value="Power Tools">Power Tools</option>
                        <option value="Garden Tools">Garden Tools</option>
                        <option value="Electronics">Electronics</option>
                        <option value="Other">Other</option>
                    </select>
                </div>

                <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-700">Photos</label>
                    <input type="file" name="photos[]" multiple accept="image/*"
                           class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200">
                </div>

                <div class="flex justify-end gap-4">
                    <button type="button" onclick="hideAddToolModal()"
                            class="px-4 py-2 text-sm font-medium text-gray-700 hover:text-gray-500">
                        Cancel
                    </button>
                    <button type="submit"
                            class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700">
                        Add Tool
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>


<div id="editToolModal" style="z-index: 1000;" class="fixed inset-0 bg-gray-600 bg-opacity-50 hidden overflow-auto">
    <div class="flex items-start justify-center min-h-screen pt-10 px-4">
        <div class="bg-white w-full max-w-3xl p-6 rounded-lg shadow-xl relative">
            <h3 class="text-xl font-bold mb-4">Edit Tool</h3>
            <form method="POST" action="" enctype="multipart/form-data" onsubmit="return validateToolForm(this)">
                <input type="hidden" name="action" value="edit">
                <input type="hidden" name="toolID" id="editToolID">

                <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-700">Tool Name</label>
                    <input type="text" name="name" id="editToolName" required
                           class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200">
                </div>

                <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-700">Description</label>
                    <textarea name="description" id="editToolDescription" required
                              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200"></textarea>
                </div>

                <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-700">Price per Day</label>
                    <input type="number" name="pricePerDay" id="editToolPrice" step="0.01" min="0" required
                           class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200">
                </div>

                <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-700">Category</label>
                    <select name="category" id="editToolCategory" required
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200">
                        <option value="">Select category</option>
                        <option value="Hand Tools">Hand Tools</option>
                        <option value="Power Tools">Power Tools</option>
                        <option value="Garden Tools">Garden Tools</option>
                        <option value="Electronics">Electronics</option>
                        <option value="Other">Other</option>
                    </select>
                </div>

                <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-700">Availability Status</label>
                    <select name="status" id="editToolStatus" required
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200">
                        <option value="Available">Available</option>
                        <option value="Unavailable">Unavailable</option>
                    </select>
                </div>

                
                <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-700">Location</label>
                    <input type="text" name="location" id="editToolLocation" required
                           class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200"
                           placeholder="Enter tool location">
                </div>

                <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-700">Delivery Option</label>
                    <select name="deliveryOption" id="editDeliveryOption" required
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200"
                            onchange="toggleEditDeliveryPriceInput()">
                        <option value="Pickup Only">Pickup Only</option>
                        <option value="Delivery Available">Delivery Available</option>
                    </select>
                </div>

                <div class="mb-4" id="editDeliveryPriceContainer" style="display:none;">
                    <label class="block text-sm font-medium text-gray-700">Delivery Price</label>
                    <input type="number" name="deliveryPrice" id="editDeliveryPrice" step="0.01" min="0" value="0"
                           class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200"
                           placeholder="Enter delivery price (optional)">
                </div>

                
                <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-700 mb-2">Existing Photos</label>
                    <div id="existingPhotos" class="grid grid-cols-3 gap-4">
                    </div>
                </div>

            
                <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-700">Add Photos</label>
                    <input type="file" name="photos[]" multiple accept="image/*"
                           class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200">
                </div>

                <div class="flex justify-end gap-4">
                    <button type="button" onclick="hideEditToolModal()"
                            class="px-4 py-2 text-sm font-medium text-gray-700 hover:text-gray-500">
                        Cancel
                    </button>
                    <button type="submit"
                            class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700">
                        Save Changes
                    </button>
                </div>
            </form>
            <button type="button" onclick="hideEditToolModal()" 
                    class="absolute top-3 right-3 text-gray-500 hover:text-gray-700 text-2xl font-bold">&times;</button>
        </div>
    </div>
</div>


<div id="rentalDetailsModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 hidden overflow-auto">
    <div class="flex items-start justify-center min-h-screen pt-10 px-4">
        <div class="bg-white w-full max-w-3xl p-6 rounded-lg shadow-xl relative">
            <h3 class="text-xl font-bold mb-4">Rentals for <span id="rentalToolNameTitle"></span></h3>
            <button type="button" onclick="hideRentalDetailsModal()" 
                    class="absolute top-3 right-3 text-gray-500 hover:text-gray-700 text-2xl font-bold">&times;</button>
            <div id="rentalDetailsContainer" class="max-h-96 overflow-y-auto">
            </div>
        </div>
    </div>
</div>

<!-- <script>
const toolPhotosMap = <?php echo json_encode($toolPhotosMap); ?>;
const toolRentals = <?php echo json_encode($toolRentals); ?>;
</script> -->




<script src="<?= BASE_URL ?>assets/js/tools.js"></script>

<?php require_once '../../includes/footer.php'; ?>