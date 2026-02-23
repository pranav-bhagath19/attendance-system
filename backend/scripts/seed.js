const admin = require('firebase-admin');
const bcrypt = require('bcryptjs');
const dotenv = require('dotenv');

dotenv.config();

const { db } = require('../config/firebase');

async function seedDatabase() {
  try {
    console.log('Starting Firebase seeding...');

    // Create teachers
    const teachers = [];
    const teacherData = [
      {
        name: 'Dr. Rajesh Kumar',
        email: 'rajesh@school.edu',
        password: await bcrypt.hash('password123', 10),
        phone: '+91 9876543210',
        department: 'Computer Science',
        is_active: true,
      },
      {
        name: 'Prof. Priya Singh',
        email: 'priya@school.edu',
        password: await bcrypt.hash('password123', 10),
        phone: '+91 9876543211',
        department: 'Mathematics',
        is_active: true,
      },
      {
        name: 'Mr. Amit Patel',
        email: 'amit@school.edu',
        password: await bcrypt.hash('password123', 10),
        phone: '+91 9876543212',
        department: 'Physics',
        is_active: true,
      },
    ];

    for (const teacher of teacherData) {
      const docRef = await db.collection('teachers').add(teacher);
      teachers.push({ id: docRef.id, ...teacher });
    }
    console.log(`✓ Created ${teachers.length} teachers`);

    // Create classes
    const classes = [];
    const classData = [
      {
        name: 'Class 10-A',
        subject: 'Computer Science',
        code: 'CS10A',
        section: 'A',
        teacher_id: teachers[0].id,
        room_number: '101',
        is_active: true,
        total_sessions: 0,
      },
      {
        name: 'Class 10-B',
        subject: 'Computer Science',
        code: 'CS10B',
        section: 'B',
        teacher_id: teachers[0].id,
        room_number: '102',
        is_active: true,
        total_sessions: 0,
      },
      {
        name: 'Class 9-A',
        subject: 'Mathematics',
        code: 'MATH9A',
        section: 'A',
        teacher_id: teachers[1].id,
        room_number: '201',
        is_active: true,
        total_sessions: 0,
      },
      {
        name: 'Class 11-A',
        subject: 'Physics',
        code: 'PHY11A',
        section: 'A',
        teacher_id: teachers[2].id,
        room_number: '301',
        is_active: true,
        total_sessions: 0,
      },
    ];

    for (const classItem of classData) {
      const docRef = await db.collection('classes').add(classItem);
      classes.push({ id: docRef.id, ...classItem });
    }
    console.log(`✓ Created ${classes.length} classes`);

    // Create students
    const studentNames = [
      'Arjun Sharma', 'Bhavna Desai', 'Chirag Gupta', 'Diya Verma', 'Eshan Kumar',
      'Farah Khan', 'Gaurav Singh', 'Hina Patel', 'Ishaan Reddy', 'Jiya Nair',
      'Karan Malhotra', 'Leena Rao', 'Madhav Chopra', 'Neha Saxena', 'Omkar Singh',
    ];

    let totalStudents = 0;

    for (const classItem of classes) {
      for (let i = 0; i < studentNames.length; i++) {
        await db.collection('students').add({
          name: studentNames[i],
          roll_no: String(i + 1).padStart(3, '0'),
          email: `${studentNames[i].toLowerCase().replace(/\s/g, '.')}@student.edu`,
          phone: `+91 ${9000000000 + i}`,
          class_id: classItem.id,
          is_active: true,
          attendance_stats: {
            total_classes: 0,
            present_count: 0,
            absent_count: 0,
            late_count: 0,
          },
        });
        totalStudents++;
      }
    }
    console.log(`✓ Created ${totalStudents} students`);

    // Create sample attendance
    let attendanceCount = 0;
    const statuses = ['PRESENT', 'ABSENT', 'LATE'];

    for (let dayOffset = 0; dayOffset < 10; dayOffset++) {
      const currentDate = new Date();
      currentDate.setDate(currentDate.getDate() - dayOffset);

      const studentsSnapshot = await db.collection('students').limit(30).get();

      for (const studentDoc of studentsSnapshot.docs) {
        const status = statuses[Math.floor(Math.random() * statuses.length)];
        await db.collection('attendance').add({
          student_id: studentDoc.id,
          class_id: studentDoc.data().class_id,
          teacher_id: classes[0].teacher_id,
          status,
          date: currentDate,
          marked_by: 'MANUAL',
          marked_at: new Date(),
        });
        attendanceCount++;
      }
    }
    console.log(`✓ Created ${attendanceCount} attendance records`);

    console.log(`
╔═════════════════════════════════════════════╗
║   FIREBASE SEEDING COMPLETED ✓              ║
╠═════════════════════════════════════════════╣
║ Teachers: ${teachers.length}                                 ║
║ Classes: ${classes.length}                              ║
║ Students: ${totalStudents}                          ║
║ Attendance Records: ${attendanceCount}              ║
╠═════════════════════════════════════════════╣
║ TEST CREDENTIALS:                           ║
║ Email: rajesh@school.edu                   ║
║ Password: password123                      ║
╚═════════════════════════════════════════════╝
    `);

    process.exit(0);
  } catch (error) {
    console.error('Seeding failed:', error);
    process.exit(1);
  }
}

seedDatabase();