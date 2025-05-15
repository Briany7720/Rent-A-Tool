</main>
    <footer class="bg-gray-800 text-white p-4 mt-8">
        <div class="container mx-auto">
            <div class="flex justify-between items-center">
                <div>
                    <h3 class="text-lg font-bold">Rent-a-Tool</h3>
                    <p class="text-sm">Your trusted tool rental platform</p>
                </div>
                <div>
                    <p class="text-sm">&copy; <?php echo date('Y'); ?> Rent-a-Tool. All rights reserved.</p>
                </div>
            </div>
        </div>
    </footer>
    <script>
        function showAlert(message, type = 'success') {
            const alertDiv = document.createElement('div');
            alertDiv.className = `fixed top-4 right-4 p-4 rounded-lg ${
                type === 'success' ? 'bg-green-500' : 'bg-red-500'
            } text-white`;
            alertDiv.textContent = message;
            document.body.appendChild(alertDiv);
            setTimeout(() => alertDiv.remove(), 3000);
        }

        function validateForm(form) {
            let isValid = true;
            form.querySelectorAll('[required]').forEach(input => {
                if (!input.value.trim()) {
                    isValid = false;
                    input.classList.add('border-red-500');
                } else {
                    input.classList.remove('border-red-500');
                }
            });
            return isValid;
        }
    </script>
</body>
</html>
