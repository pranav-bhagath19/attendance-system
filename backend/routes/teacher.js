/**
 * Teacher Routes
 * Handles teacher dashboard, classes, and student management using Firestore
 */

const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/firebaseAuth');
const {
  getTeacherClasses,
  getClassWithStudents,
  getStudentsByClass,
} = require('../services/firestoreService');
const { db } = require('../config/firebase');

/**
 * GET /api/teacher/classes
 * Get all classes assigned to authenticated teacher
 */
router.get('/classes', authMiddleware, async (req, res) => {
  try {
    const classes = await getTeacherClasses(req.user.userId);

    res.status(200).json({
      success: true,
      count: classes.length,
      classes: classes.map(cls => ({
        id: cls.id,
        name: cls.name,
        subject: cls.subject,
        section: cls.section,
        code: cls.code,
        room_number: cls.room_number,
        student_count: cls.student_count || 0,
        total_sessions: cls.total_sessions || 0,
        last_attendance_date: cls.last_attendance_date,
        is_active: cls.is_active !== false
      }))
    });
  } catch (error) {
    console.error('Error fetching classes:', error);
    res.status(500).json({
      error: 'Failed to fetch classes'
    });
  }
});

/**
 * GET /api/teacher/class/:classId
 * Get specific class details with all students
 */
router.get('/class/:classId', authMiddleware, async (req, res) => {
  try {
    const classData = await getClassWithStudents(req.params.classId);

    if (!classData) {
      return res.status(404).json({
        error: 'Class not found'
      });
    }

    // Verify teacher owns this class
    if (classData.teacher_id !== req.user.userId) {
      return res.status(403).json({
        error: 'Unauthorized access to this class'
      });
    }

    res.status(200).json({
      success: true,
      class: {
        id: classData.id,
        name: classData.name,
        subject: classData.subject,
        section: classData.section,
        code: classData.code,
        room_number: classData.room_number,
        schedule: classData.schedule,
        description: classData.description,
        students: (classData.students || []).map(student => ({
          id: student.id,
          name: student.name,
          roll_no: student.roll_no,
          email: student.email,
          photo: student.photo,
          attendance_percentage: student.attendance_percentage || 0,
          stats: student.attendance_stats || {}
        })),
        total_students: (classData.students || []).length
      }
    });
  } catch (error) {
    console.error('Error fetching class details:', error);
    res.status(500).json({
      error: 'Failed to fetch class details'
    });
  }
});

/**
 * GET /api/teacher/class/:classId/students
 * Get list of students for swipe attendance
 * Returns students optimized for card display
 */
router.get('/class/:classId/students', authMiddleware, async (req, res) => {
  try {
    // Verify teacher owns this class
    const classDoc = await db.collection('classes').doc(req.params.classId).get();
    
    if (!classDoc.exists) {
      return res.status(404).json({
        error: 'Class not found'
      });
    }

    if (classDoc.data().teacher_id !== req.user.userId) {
      return res.status(403).json({
        error: 'Unauthorized access to this class'
      });
    }

    const students = await getStudentsByClass(req.params.classId);

    // Format students for card display
    const formattedStudents = students.map(student => ({
      id: student.id,
      name: student.name,
      roll_no: student.roll_no,
      photo: student.photo,
      email: student.email,
      phone: student.phone,
      attendance_percentage: student.attendance_percentage || 0,
      stats: student.attendance_stats || {}
    }));

    res.status(200).json({
      success: true,
      count: formattedStudents.length,
      students: formattedStudents
    });
  } catch (error) {
    console.error('Error fetching students:', error);
    res.status(500).json({
      error: 'Failed to fetch students'
    });
  }
});

/**
 * GET /api/teacher/dashboard
 * Get teacher dashboard summary
 */
router.get('/dashboard', authMiddleware, async (req, res) => {
  try {
    const classes = await getTeacherClasses(req.user.userId);
    
    // Count total students
    let totalStudents = 0;
    for (const cls of classes) {
      const studentsSnapshot = await db
        .collection('students')
        .where('class_id', '==', cls.id)
        .get();
      totalStudents += studentsSnapshot.size;
    }

    res.status(200).json({
      success: true,
      dashboard: {
        total_classes: classes.length,
        total_students: totalStudents,
        classes: classes.map(c => ({
          id: c.id,
          name: c.name,
          subject: c.subject
        }))
      }
    });
  } catch (error) {
    console.error('Error fetching dashboard:', error);
    res.status(500).json({
      error: 'Failed to fetch dashboard'
    });
  }
});

module.exports = router;
