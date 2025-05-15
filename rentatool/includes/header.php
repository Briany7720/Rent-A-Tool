<?php
require_once 'config.php';
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rent-a-Tool Dashboard</title>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
</head>
<body>
    <header class="bg-blue-600 text-white p-4">
        <div class="container mx-auto flex justify-between items-center">
            <h1 class="text-2xl font-bold">Rent-a-Tool</h1>
            <nav>
                <ul class="flex space-x-4">
                    <?php if (isLoggedIn()): ?>
                        <?php if (getUserType() === 'Owner'): ?>
                            <li><a href="<?php echo BASE_URL; ?>dashboard/owner/index.php" class="hover:underline">Dashboard</a></li>
                        <?php else: ?>
                            <li><a href="<?php echo BASE_URL; ?>dashboard/renter/index.php" class="hover:underline">Dashboard</a></li>
                        <?php endif; ?>
                        <li><a href="<?php echo BASE_URL; ?>auth/logout.php" class="hover:underline">Logout</a></li>
                    <?php else: ?>
                        <li><a href="<?php echo BASE_URL; ?>auth/login.php" class="hover:underline">Login</a></li>
                        <li><a href="<?php echo BASE_URL; ?>auth/register.php" class="hover:underline">Register</a></li>
                    <?php endif; ?>
                </ul>
            </nav>
        </div>
    </header>
    <main class="container mx-auto my-4">
