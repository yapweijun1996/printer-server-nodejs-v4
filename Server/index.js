import express from 'express';
import dotenv from 'dotenv';
import cors from 'cors';
import { fileURLToPath } from 'url';
import path from 'path';
import printRoutes from './routes/print.routes.js';
import { errorHandler } from './middleware/errorHandler.js';
import logger from './config/logger.js';

// --- Basic Setup ---
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load environment variables from the .env file located in the 'Server' directory.
// This ensures the configuration is found regardless of the process's working directory.
dotenv.config({ path: path.resolve(__dirname, '.env') });

// --- Initialize Express App ---
const app = express();
const port = process.env.PORT || 3000;

// --- Middleware ---
app.use(cors()); // Enable CORS for all routes
app.use(express.json({ limit: '50mb' })); // Enable support for large JSON payloads

// --- Serve Static UI ---
const publicPath = path.join(__dirname, '..', 'public');
app.use(express.static(publicPath));

// --- API Routes ---
app.use('/api', printRoutes);

// --- Error Handling ---
// This must be the last piece of middleware loaded
app.use(errorHandler);

// --- Global Error Handlers ---
// These handlers catch any errors that are not handled by a try/catch block
// and log them before the process exits.
process.on('uncaughtException', (error) => {
    logger.error(`Uncaught Exception: ${error.message}`, { stack: error.stack });
    process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
    logger.error('Unhandled Rejection at:', { promise, reason });
    process.exit(1);
});

// --- Start the Server ---
app.listen(port, () => {
    logger.info(`Node.js Print Server listening at http://localhost:${port}`);
    logger.info('Endpoints available:');
    logger.info('  - GET /api/printers');
    logger.info('  - POST /api/print-html (High Quality, Selectable Text)');
    logger.info('  - POST /api/print-base64 (Lower Quality, Image-based)');
});
