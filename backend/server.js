/**
 * Attendance Management System API Server
 * Main server file with Express configuration, middleware setup, and route handling
 */

const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const compression = require('compression');

// Initialize Firebase Admin
const { db, admin } = require('./config/firebase');

// Load environment variables
dotenv.config();

const app = express();

// ============ MIDDLEWARE SETUP ============

// Response Compression - Reduce response size
app.use(compression());

// CORS Configuration
app.use(cors({
  origin: [
    'http://localhost:3000',
    'http://localhost:8080', 
    'http://10.0.2.2:*', // Allow all ports from emulator
    'http://127.0.0.1:*' // Allow iOS simulator
  ],
  credentials: true,
  optionsSuccessStatus: 200,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS']
}));

// Body Parser with optimized limits
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// Request logging middleware (optional - for debugging)
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    if (duration > 5000) {
      console.warn(`⚠️ Slow API Request: ${req.method} ${req.path} took ${duration}ms`);
    }
  });
  next();
});

// Static Files for uploads
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Make Firestore accessible globally
global.db = db;
global.admin = admin;

// ============ ROUTES ============

// Authentication Routes
app.use('/api/auth', require('./routes/auth'));

// Teacher Routes
app.use('/api/teacher', require('./routes/teacher'));

// Attendance Routes
app.use('/api/attendance', require('./routes/attendance'));
// Root route (for Render health check)
app.get('/', (req, res) => {
  res.json({
    status: 'Attendance API is running',
    message: 'Backend server is operational',
    timestamp: new Date().toISOString(),
  });
});

// Health Check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'API is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Simple test endpoint (no Firestore dependency)
app.get('/api/test', (req, res) => {
  res.json({
    success: true,
    message: 'Backend is reachable',
    platform: req.get('user-agent'),
    timestamp: new Date().toISOString()
  });
});

// Mock login for testing (replace with real implementation later)
app.post('/api/test/login', (req, res) => {
  res.json({
    success: true,
    message: 'Test login successful',
    token: 'test-token-12345',
    teacher: {
      id: 'test-teacher-1',
      name: 'Test Teacher',
      email: 'test@school.edu'
    }
  });
});

// ============ ERROR HANDLING ============

// 404 Error Handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Route not found',
    path: req.path,
    method: req.method
  });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('Error:', err);

  const status = err.status || 500;
  const message = err.message || 'Internal Server Error';

  res.status(status).json({
    error: message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// ============ SERVER START ============

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════╗
║  Attendance Management API             ║
║  Server running on port ${PORT}       ║
║  Environment: ${process.env.NODE_ENV || 'development'}          ║
╚════════════════════════════════════════╝
  `);
});

module.exports = app;
