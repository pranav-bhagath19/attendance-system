/**
 * Firestore Service
 * Handles all Firestore database operations
 */

const { db, admin } = require('../config/firebase');
const bcrypt = require('bcryptjs');

// ============ TEACHER OPERATIONS ============

// Create or update teacher
const createTeacher = async (teacherData) => {
  try {
    const { email, password, name, phone, department } = teacherData;

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Check if teacher already exists
    const existingTeacher = await db
      .collection('teachers')
      .where('email', '==', email)
      .get();

    if (!existingTeacher.empty) {
      throw new Error('Teacher with this email already exists');
    }

    // Create teacher document
    const teacherRef = db.collection('teachers').doc();
    const newTeacher = {
      id: teacherRef.id,
      email,
      password: hashedPassword,
      name,
      phone: phone || null,
      department: department || null,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    await teacherRef.set(newTeacher);
    return { id: teacherRef.id, email, name, phone, department };
  } catch (error) {
    throw error;
  }
};

// Get teacher by email
const getTeacherByEmail = async (email) => {
  try {
    const snapshot = await db
      .collection('teachers')
      .where('email', '==', email)
      .get();

    if (snapshot.empty) {
      return null;
    }

    const doc = snapshot.docs[0];
    return { id: doc.id, ...doc.data() };
  } catch (error) {
    throw error;
  }
};

// Get teacher by ID
const getTeacherById = async (teacherId) => {
  try {
    const doc = await db.collection('teachers').doc(teacherId).get();

    if (!doc.exists) {
      return null;
    }

    return { id: doc.id, ...doc.data() };
  } catch (error) {
    throw error;
  }
};

// ============ CLASS OPERATIONS ============

// Get all classes for a teacher
const getTeacherClasses = async (teacherId) => {
  try {
    const snapshot = await db
      .collection('classes')
      .where('teacher_id', '==', teacherId)
      .get();

    const classes = [];
    snapshot.forEach((doc) => {
      classes.push({ id: doc.id, ...doc.data() });
    });

    return classes;
  } catch (error) {
    throw error;
  }
};

// Get class details with students
const getClassWithStudents = async (class_id) => {
  try {
    const classDoc = await db.collection('classes').doc(class_id).get();

    if (!classDoc.exists) {
      return null;
    }

    // Get students in class
    const studentsSnapshot = await db
      .collection('students')
      .where('class_id', '==', class_id)
      .get();

    const students = [];
    studentsSnapshot.forEach((doc) => {
      students.push({ id: doc.id, ...doc.data() });
    });

    return {
      id: classDoc.id,
      ...classDoc.data(),
      students,
    };
  } catch (error) {
    throw error;
  }
};

// ============ STUDENT OPERATIONS ============

// Get all students in a class
const getStudentsByClass = async (class_id) => {
  try {
    const snapshot = await db
      .collection('students')
      .where('class_id', '==', class_id)
      .orderBy('roll_no')
      .get();

    const students = [];
    snapshot.forEach((doc) => {
      students.push({ id: doc.id, ...doc.data() });
    });

    return students;
  } catch (error) {
    throw error;
  }
};

// Get student by ID
const getStudentById = async (studentId) => {
  try {
    const doc = await db.collection('students').doc(studentId).get();

    if (!doc.exists) {
      return null;
    }

    return { id: doc.id, ...doc.data() };
  } catch (error) {
    throw error;
  }
};

// ============ ATTENDANCE OPERATIONS ============

// Mark attendance
const markAttendance = async (attendanceData) => {
  try {
    const { student_id, class_id, status, date, notes } = attendanceData;

    // Check if attendance already exists for this student on this date
    const existingSnapshot = await db
      .collection('attendance')
      .where('student_id', '==', student_id)
      .where('class_id', '==', class_id)
      .where('date', '==', date)
      .get();

    if (!existingSnapshot.empty) {
      // Update existing attendance
      const doc = existingSnapshot.docs[0];
      await doc.ref.update({
        status,
        notes: notes || null,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      return { id: doc.id, ...doc.data() };
    }

    // Create new attendance record
    const attendanceRef = db.collection('attendance').doc();
    const attendanceRecord = {
      id: attendanceRef.id,
      student_id,
      class_id,
      status,
      date,
      notes: notes || null,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    await attendanceRef.set(attendanceRecord);
    return attendanceRecord;
  } catch (error) {
    throw error;
  }
};

// Get attendance report for a class on a specific date
const getAttendanceReport = async (class_id, date) => {
  try {
    const snapshot = await db
      .collection('attendance')
      .where('class_id', '==', class_id)
      .where('date', '==', date)
      .get();

    const attendance = [];
    snapshot.forEach((doc) => {
      attendance.push({ id: doc.id, ...doc.data() });
    });

    return attendance;
  } catch (error) {
    throw error;
  }
};

// Get student attendance history
const getStudentAttendanceHistory = async (studentId) => {
  try {
    const snapshot = await db
      .collection('attendance')
      .where('student_id', '==', studentId)
      .orderBy('date', 'desc')
      .get();

    const attendance = [];
    snapshot.forEach((doc) => {
      attendance.push({ id: doc.id, ...doc.data() });
    });

    return attendance;
  } catch (error) {
    throw error;
  }
};

module.exports = {
  createTeacher,
  getTeacherByEmail,
  getTeacherById,
  getTeacherClasses,
  getClassWithStudents,
  getStudentsByClass,
  getStudentById,
  markAttendance,
  getAttendanceReport,
  getStudentAttendanceHistory,
};
