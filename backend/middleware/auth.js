/**
 * Authentication Middleware
 * Handles JWT token verification and teacher authentication
 */

const jwt = require('jsonwebtoken');
const Teacher = require('../models/Teacher');

/**
 * Verify JWT token and attach teacher to request
 */
exports.authMiddleware = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Authorization header must be Bearer token'
      });
    }
    const token = authHeader.split(' ')[1];

    if (!token) {
      return res.status(401).json({
        error: 'No authentication token provided'
      });
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Fetch teacher from database
    const teacher = await Teacher.findById(decoded.id);

    if (!teacher || !teacher.is_active) {
      return res.status(401).json({
        error: 'Teacher not found or inactive'
      });
    }

    // Attach teacher to request object
    req.teacher = teacher;
    req.teacherId = teacher._id;

    next();
  } catch (error) {
    console.error('Authentication error:', error); // ✅ Log error
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Token has expired'
      });
    }

    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        error: 'Invalid token'
      });
    }

    res.status(401).json({
      error: 'Authentication failed'
    });
  }
};

/**
 * Generate JWT token for teacher
 */
exports.generateToken = (teacherId) => {
  return jwt.sign(
    { id: teacherId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRE || '7d' }
  );
};
