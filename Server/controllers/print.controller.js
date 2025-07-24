import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import puppeteer from 'puppeteer';
import { v4 as uuidv4 } from 'uuid';
import pkg from 'pdf-to-printer';
import logger from '../config/logger.js';
const { print, getPrinters } = pkg;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

let sharedBrowser;
async function getSharedBrowser() {
    if (!sharedBrowser) {
        sharedBrowser = await puppeteer.launch({ headless: true });
        process.on('exit', () => sharedBrowser && sharedBrowser.close());
    }
    return sharedBrowser;
}

export const printHtml = async (req, res, next) => {
    logger.info(`Processing /api/print-html request from ${req.ip}`);
    
    // Log the entire request body for debugging dynamic content issues.
    logger.info({
        message: 'Received data for /api/print-html',
        body: req.body,
    });

    const { htmlContent, paperSize = 'a4', printerName, printerOptions = {} } = req.body;

    let page;
    let tempFilePath;
    try {
        const browser = await getSharedBrowser();
        page = await browser.newPage();

        let viewportWidth = 1200, viewportHeight = 1600;
        if (Array.isArray(paperSize)) {
            viewportWidth = Math.ceil(Number(paperSize[0]) * 3.7795);
            viewportHeight = Math.ceil(Number(paperSize[1]) * 3.7795);
        }
        await page.setViewport({
            width: viewportWidth,
            height: viewportHeight,
        });

        await page.setContent(htmlContent, { waitUntil: 'networkidle0' });
        await page.emulateMediaType('print');

        let pdfOptions = {
            printBackground: true,
            margin: { top: '0mm', right: '0mm', bottom: '0mm', left: '0mm' },
        };
        if (Array.isArray(paperSize)) {
            pdfOptions.width = `${paperSize[0]}mm`;
            pdfOptions.height = `${paperSize[1]}mm`;
        } else {
            pdfOptions.format = paperSize || 'a4';
        }

        const pdfBuffer = await page.pdf(pdfOptions);
        
        tempFilePath = path.join(__dirname, `temp_print_${uuidv4()}.pdf`);
        await fs.promises.writeFile(tempFilePath, pdfBuffer);

        const options = {
            printer: printerName || undefined,
            ...printerOptions,
            win32: ['-print-settings "high"', '-print-dpi 600'],
        };
        await print(tempFilePath, options);

        logger.info(`Successfully processed print job for ${printerName || 'default'}.`);
        res.status(200).json({ message: 'High-quality print job sent successfully!' });
    } catch (error) {
        logger.error({
            message: 'Error during Puppeteer printing',
            error: error.message,
            stack: error.stack
        });
        return next(error); // Pass error to the centralized handler
    } finally {
        if (page) await page.close();
        if (tempFilePath) await fs.promises.unlink(tempFilePath).catch(err => logger.error(`Failed to delete temp file ${tempFilePath}: ${err.message}`));
    }
};

export const printBase64 = async (req, res, next) => {
    const { base64Data, printerName, printerOptions = {} } = req.body;
    
    let tempFilePath;
    try {
        tempFilePath = path.join(__dirname, `temp_print_${uuidv4()}.pdf`);
        await fs.promises.writeFile(tempFilePath, Buffer.from(base64Data, 'base64'));

        const options = {
            printer: printerName || undefined,
            ...printerOptions,
        };
        await print(tempFilePath, options);
        
        logger.info(`Successfully processed base64 print job for ${printerName || 'default'}.`);
        res.status(200).json({ message: 'Base64 print job sent successfully!' });
    } catch (error) {
        logger.error({
            message: 'Error during Base64 printing',
            error: error.message,
            stack: error.stack
        });
        return next(error); // Pass error to the centralized handler
    } finally {
        if (tempFilePath) await fs.promises.unlink(tempFilePath).catch(err => logger.error(`Failed to delete temp file ${tempFilePath}: ${err.message}`));
    }
};

export const getAvailablePrinters = async (req, res, next) => {
    try {
        const printers = await getPrinters();
        logger.info('Successfully retrieved printer list.');
        res.status(200).json(printers);
    } catch (error) {
        logger.error({
            message: 'Error getting printers',
            error: error.message,
            stack: error.stack
        });
        return next(error); // Pass error to the centralized handler
    }
};