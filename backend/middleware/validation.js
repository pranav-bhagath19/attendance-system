/**
 * Validation Middleware
 * Input validation and sanitization utilities
 */

const { body, validationResult } = require('express-validator');

/**
 * Firebase ID Validator
 * Checks if a string is a valid Firebase document ID (20 chars, alphanumeric)
 */
const isValidFirebaseId = (id) => {
  return typeof id === 'string' && /^[a-zA-Z0-9]{20}$/.test(id);
};

/**
 * Validation error handler middleware
 */
exports.handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      error: 'Validation failed',
      details: errors.array()
    });
  }
  next();
};

/**
 * Login validation rules
 */
exports.validateLogin = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('password')
    .trim()
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters')
];

/**
 * Attendance marking validation
 */
exports.validateAttendanceMarking = [
  body('class_id')
    .custom(isValidFirebaseId)
    .withMessage('Invalid class ID'),
  body('student_id')
    .custom(isValidFirebaseId)
    .withMessage('Invalid student ID'),
  body('status')
    .isIn(['PRESENT', 'ABSENT', 'LATE', 'EXCUSED', 'present', 'absent', 'late', 'excused'])
    .withMessage('Invalid attendance status'),
  body('date')
    .isISO8601()
    .withMessage('Invalid date format'),
  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Notes cannot exceed 500 characters')
];

/**
 * Attendance update validation
 */
exports.validateAttendanceUpdate = [
  body('status')
    .custom(value => {
      const validStatuses = ['PRESENT', 'ABSENT', 'LATE', 'EXCUSED'];
      return validStatuses.includes(value.toUpperCase());
    })
    .withMessage('Invalid attendance status'),
  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Notes cannot exceed 500 characters')
];
