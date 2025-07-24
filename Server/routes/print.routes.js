import express from 'express';
import { printHtml, printBase64, getAvailablePrinters } from '../controllers/print.controller.js';
import { validatePrintHtml, validatePrintBase64 } from '../middleware/validators.js';

const router = express.Router();

// Define API routes and map them to controller functions
router.post('/print-html', validatePrintHtml, printHtml);
router.post('/print-base64', validatePrintBase64, printBase64);
router.get('/printers', getAvailablePrinters);

export default router;