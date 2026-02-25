/**
 * Firebase Authentication Middleware
 * Handles Firebase ID Token verification using Firebase Admin SDK
 */

const { admin } = require('../config/firebase');

const authMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'No token provided or invalid format' });
    }

    const token = authHeader.split(' ')[1];

    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }

    // Verify Firebase Auth ID token
    const decodedToken = await admin.auth().verifyIdToken(token);

    // Attach user to req object
    req.user = {
      userId: decodedToken.uid,
      email: decodedToken.email
    };

    // Attach teacherId specifically for route compatibility
    req.teacherId = decodedToken.uid;

    next();
  } catch (error) {
    console.error('Firebase token verification error:', error.message);
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
};

module.exports = {
  authMiddleware,
};
