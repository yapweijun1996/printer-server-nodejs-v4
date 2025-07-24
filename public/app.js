document.addEventListener('DOMContentLoaded', () => {
    const getPrintersBtn = document.getElementById('getPrinters');
    const printerListSelect = document.getElementById('printerList');
    const printBtn = document.getElementById('printButton');
    const htmlContent = document.getElementById('htmlContent');
    const statusDiv = document.getElementById('status');

    const setStatus = (message, type = 'info') => {
        statusDiv.innerHTML = `<p>Status: ${message}</p>`;
        statusDiv.className = 'status-message'; // Reset classes
        if (type) {
            statusDiv.classList.add(type);
        }
    };

    const fetchPrinters = async () => {
        setStatus('Fetching printers...', 'loading');
        try {
            const response = await fetch('/api/printers');
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            const printers = await response.json();
            
            printerListSelect.innerHTML = ''; // Clear existing options
            if (printers.length > 0) {
                printers.forEach(printer => {
                    const option = document.createElement('option');
                    option.value = printer.name;
                    option.textContent = printer.name;
                    printerListSelect.appendChild(option);
                });
                setStatus('Printers loaded successfully.', 'success');
            } else {
                setStatus('No printers found.', 'info');
            }
        } catch (error) {
            console.error('Error fetching printers:', error);
            setStatus(`Error fetching printers: ${error.message}`, 'error');
        }
    };

    const sendPrintJob = async () => {
        const selectedPrinter = printerListSelect.value;
        const content = htmlContent.value;

        if (!selectedPrinter) {
            setStatus('Please select a printer.', 'error');
            return;
        }

        if (!content.trim()) {
            setStatus('Please enter HTML content to print.', 'error');
            return;
        }

        setStatus('Sending print job...', 'loading');
        try {
            const response = await fetch('/api/print-html', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    printerName: selectedPrinter,
                    htmlContent: content,
                }),
            });

            const result = await response.json();

            if (!response.ok) {
                throw new Error(result.message || `HTTP error! status: ${response.status}`);
            }

            setStatus(`Print job sent successfully to ${selectedPrinter}!`, 'success');
        } catch (error) {
            console.error('Error sending print job:', error);
            setStatus(`Failed to send print job: ${error.message}`, 'error');
        }
    };

    getPrintersBtn.addEventListener('click', fetchPrinters);
    printBtn.addEventListener('click', sendPrintJob);

    // Fetch printers on initial page load
    fetchPrinters();
});