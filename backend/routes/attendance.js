/**
 * Attendance Routes
 * Handles attendance marking, reporting, and analytics using Firestore
 */

const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/firebaseAuth');
const { validateAttendanceMarking, validateAttendanceUpdate, handleValidationErrors } = require('../middleware/validation');
const {
  markAttendance,
  getAttendanceReport,
  getStudentAttendanceHistory,
} = require('../services/firestoreService');
const { db } = require('../config/firebase');

/**
 * POST /api/attendance/mark
 * Mark attendance for a student via swipe
 * Status: PRESENT, ABSENT, LATE, EXCUSED
 */
router.post('/mark', authMiddleware, validateAttendanceMarking, handleValidationErrors, async (req, res) => {
  try {
    const { student_id, class_id, status, date, notes } = req.body;

    // Verify class belongs to teacher
    const classDoc = await db.collection('classes').doc(class_id).get();

    if (!classDoc.exists || classDoc.data().teacher_id !== req.user.userId) {
      return res.status(403).json({
        error: 'Unauthorized to mark attendance for this class'
      });
    }

    // Mark attendance
    const attendance = await markAttendance({
      student_id,
      class_id,
      status,
      date,
      notes
    });

    // Update class last attendance date
    await db.collection('classes').doc(class_id).update({
      last_attendance_date: new Date(),
    });

    res.status(201).json({
      success: true,
      message: 'Attendance marked successfully',
      attendance: {
        id: attendance.id,
        student_id,
        class_id,
        status,
        date,
        marked_at: new Date()
      }
    });
  } catch (error) {
    console.error('Error marking attendance:', error);
    res.status(500).json({
      error: 'Failed to mark attendance'
    });
  }
});

/**
 * POST /api/attendance/batch-mark
 * Mark attendance for multiple students at once
 */
router.post('/batch-mark', authMiddleware, async (req, res) => {
  try {
    const { class_id, attendance_data, date } = req.body;

    // Verify class belongs to teacher
    const classDoc = await db.collection('classes').doc(class_id).get();

    if (!classDoc.exists || classDoc.data().teacher_id !== req.user.userId) {
      return res.status(403).json({
        error: 'Unauthorized to mark attendance for this class'
      });
    }

    let markedCount = 0;

    // Process each attendance entry
    for (const entry of attendance_data) {
      const { student_id, status, notes } = entry;

      try {
        await markAttendance({
          student_id,
          class_id,
          status,
          date,
          notes
        });
        markedCount++;
      } catch (error) {
        console.error(`Error marking attendance for student ${student_id}:`, error);
      }
    }

    // Update class last attendance date
    await db.collection('classes').doc(class_id).update({
      last_attendance_date: new Date(),
    });

    res.status(201).json({
      success: true,
      message: 'Batch attendance marked successfully',
      marked_count: markedCount
    });
  } catch (error) {
    console.error('Error in batch marking:', error);
    res.status(500).json({
      error: 'Failed to mark batch attendance'
    });
  }
});

/**
 * PUT /api/attendance/:attendanceId
 * Update attendance record
 */
router.put('/:attendanceId', authMiddleware, validateAttendanceUpdate, handleValidationErrors, async (req, res) => {
  try {
    const { status, notes } = req.body;

    const attendanceDoc = await db.collection('attendance').doc(req.params.attendanceId).get();

    if (!attendanceDoc.exists) {
      return res.status(404).json({
        error: 'Attendance record not found'
      });
    }

    // Verify authorization - check if user is the teacher of the class
    const attendanceData = attendanceDoc.data();
    const classDoc = await db.collection('classes').doc(attendanceData.class_id).get();

    if (!classDoc.exists || classDoc.data().teacher_id !== req.user.userId) {
      return res.status(403).json({
        error: 'Unauthorized to update this attendance'
      });
    }

    // Update attendance
    await db.collection('attendance').doc(req.params.attendanceId).update({
      status,
      notes: notes || null,
      updated_at: new Date(),
    });

    res.status(200).json({
      success: true,
      message: 'Attendance updated successfully',
      attendance: {
        id: req.params.attendanceId,
        status,
        notes
      }
    });
  } catch (error) {
    console.error('Error updating attendance:', error);
    res.status(500).json({
      error: 'Failed to update attendance'
    });
  }
});

/**
 * GET /api/attendance/class/:classId
 * Get attendance report for a class on a specific date
 */
router.get('/class/:classId', authMiddleware, async (req, res) => {
  try {
    const { date } = req.query;

    if (!date) {
      return res.status(400).json({
        error: 'Date parameter is required'
      });
    }

    // Verify class belongs to teacher
    const classDoc = await db.collection('classes').doc(req.params.classId).get();

    if (!classDoc.exists || classDoc.data().teacher_id !== req.user.userId) {
      return res.status(404).json({
        error: 'Class not found'
      });
    }

    const classData = classDoc.data();

    // Get students in class
    const studentsSnapshot = await db
      .collection('students')
      .where('class_id', '==', req.params.classId)
      .get();

    const students = [];
    studentsSnapshot.forEach(doc => {
      students.push({ id: doc.id, ...doc.data() });
    });

    // Get attendance records for the date
    const attendanceRecords = await getAttendanceReport(req.params.classId, date);

    // Build attendance map
    const attendanceMap = {};
    attendanceRecords.forEach(record => {
      attendanceMap[record.student_id] = record;
    });

    // Format response
    const attendance = students.map(student => ({
      id: attendanceMap[student.id]?.id || null,
      student_id: student.id,
      student_name: student.name,
      roll_no: student.roll_no,
      status: attendanceMap[student.id]?.status || 'NOT_MARKED',
      marked_at: attendanceMap[student.id]?.created_at || null,
      notes: attendanceMap[student.id]?.notes || null
    }));

    res.status(200).json({
      success: true,
      date,
      class_name: classData.name,
      total_students: students.length,
      attendance
    });
  } catch (error) {
    console.error('Error fetching attendance report:', error);
    res.status(500).json({
      error: 'Failed to fetch attendance report'
    });
  }
});

/**
 * GET /api/attendance/student/:studentId
 * Get attendance history for a specific student
 */
router.get('/student/:studentId', authMiddleware, async (req, res) => {
  try {
    const records = await getStudentAttendanceHistory(req.params.studentId);

    if (!records.length) {
      return res.status(404).json({
        error: 'No attendance records found'
      });
    }

    // Get student info
    const studentDoc = await db.collection('students').doc(req.params.studentId).get();
    const student = studentDoc.exists ? { id: studentDoc.id, ...studentDoc.data() } : null;

    res.status(200).json({
      success: true,
      student,
      attendance_history: records.map(r => ({
        id: r.id,
        date: r.date,
        status: r.status,
        marked_at: r.created_at,
        notes: r.notes
      }))
    });
  } catch (error) {
    console.error('Error fetching student attendance:', error);
    res.status(500).json({
      error: 'Failed to fetch student attendance'
    });
  }
});

/**
 * GET /api/attendance/analytics/:classId
 * Get analytics for a class
 */
router.get('/analytics/:classId', authMiddleware, async (req, res) => {
  try {
    const classDoc = await db.collection('classes').doc(req.params.classId).get();

    if (!classDoc.exists || classDoc.data().teacher_id !== req.user.userId) {
      return res.status(404).json({
        error: 'Class not found'
      });
    }

    const classData = classDoc.data();

    // Get all students in class
    const studentsSnapshot = await db
      .collection('students')
      .where('class_id', '==', req.params.classId)
      .get();

    // Calculate analytics for each student
    const analytics = [];

    for (const studentDoc of studentsSnapshot.docs) {
      const student = { id: studentDoc.id, ...studentDoc.data() };

      const attendanceSnapshot = await db
        .collection('attendance')
        .where('class_id', '==', req.params.classId)
        .get();

      let presentCount = 0;
      let absentCount = 0;

      attendanceSnapshot.forEach(doc => {
        const data = doc.data();
        const records = data.records || [];
        const studentRecord = records.find(r => String(r.student_id) === String(student.id) || String(r.id) === String(student.id));
        if (studentRecord) {
          if (studentRecord.status === 'PRESENT') presentCount++;
          else if (studentRecord.status === 'ABSENT') absentCount++;
        }
      });

      const totalClasses = attendanceSnapshot.size > 0 ? attendanceSnapshot.size : 1;
      const percentage = Math.round((presentCount / totalClasses) * 100);

      analytics.push({
        student_id: student.id,
        student_name: student.name,
        roll_no: student.roll_no,
        total_classes: totalClasses > 0 ? attendanceSnapshot.size : 0,
        present: presentCount,
        absent: absentCount,
        attendance_percentage: attendanceSnapshot.size > 0 ? percentage : 0,
        status: percentage >= 75 ? 'GOOD' : percentage >= 50 ? 'FAIR' : 'POOR'
      });
    }

    res.status(200).json({
      success: true,
      class_name: classData.name,
      analytics: analytics.sort((a, b) => b.attendance_percentage - a.attendance_percentage)
    });
  } catch (error) {
    console.error('Error fetching analytics:', error);
    res.status(500).json({
      error: 'Failed to fetch analytics'
    });
  }
});

module.exports = router;

