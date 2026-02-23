/**
 * Authentication Routes
 * Handles teacher login, logout, and session management using Firebase & Firestore
 */

const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const {
  authMiddleware,
  generateToken,
} = require('../middleware/firebaseAuth');
const { validateLogin, handleValidationErrors } = require('../middleware/validation');
const {
  getTeacherByEmail,
  getTeacherById,
  getTeacherClasses,
} = require('../services/firestoreService');
const { db } = require('../config/firebase');

/**
 * POST /api/auth/login
 * Login teacher with email and password
 * Returns JWT token for authentication
 */
router.post('/login', validateLogin, handleValidationErrors, async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find teacher by email in Firestore
    const teacher = await getTeacherByEmail(email);

    if (!teacher) {
      return res.status(401).json({
        error: 'Invalid email or password'
      });
    }

    // Compare password
    const isPasswordValid = await bcrypt.compare(password, teacher.password);

    if (!isPasswordValid) {
      return res.status(401).json({
        error: 'Invalid email or password'
      });
    }

    // Update last login
    await db.collection('teachers').doc(teacher.id).update({
      last_login: new Date(),
    });

    // Generate JWT token
    const token = generateToken(teacher.id, teacher.email);

    // Fetch teacher's assigned classes
    const classes = await getTeacherClasses(teacher.id);

    res.status(200).json({
      success: true,
      message: 'Login successful',
      token,
      teacher: {
        id: teacher.id,
        name: teacher.name,
        email: teacher.email,
        phone: teacher.phone,
        department: teacher.department,
        assigned_classes: classes
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      error: 'Login failed'
    });
  }
});

/**
 * POST /api/auth/logout
 * Logout teacher (token becomes invalid on frontend)
 */
router.post('/logout', authMiddleware, (req, res) => {
  // Token invalidation happens on frontend by clearing storage
  res.status(200).json({
    success: true,
    message: 'Logout successful'
  });
});

/**
 * GET /api/auth/me
 * Get current authenticated teacher profile
 */
router.get('/me', authMiddleware, async (req, res) => {
  try {
    const teacher = await getTeacherById(req.user.userId);

    if (!teacher) {
      return res.status(404).json({
        error: 'Teacher not found'
      });
    }

    const classes = await getTeacherClasses(teacher.id);

    res.status(200).json({
      success: true,
      teacher: {
        id: teacher.id,
        name: teacher.name,
        email: teacher.email,
        phone: teacher.phone,
        department: teacher.department,
        assigned_classes: classes
      }
    });
  } catch (error) {
    res.status(500).json({
      error: 'Failed to fetch teacher profile'
    });
  }
});

/**
 * POST /api/auth/verify-token
 * Verify if JWT token is still valid
 */
router.post('/verify-token', authMiddleware, (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Token is valid',
    teacher_id: req.user.userId
  });
});

module.exports = router;
