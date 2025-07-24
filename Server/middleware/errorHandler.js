import logger from '../config/logger.js';

// This middleware catches errors thrown from other parts of the application.
export const errorHandler = (err, req, res, next) => {
    logger.error(err.stack); // Log the full error stack for debugging

    // Respond with a generic 500 Internal Server Error
    res.status(500).json({
        error: 'An unexpected error occurred.',
        details: err.message // Provide the error message for context
    });
};