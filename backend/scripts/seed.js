/**
 * Database Seed Script
 * Populates MongoDB with sample data for testing
 */

const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Teacher = require('../models/Teacher');
const Class = require('../models/Class');
const Student = require('../models/Student');
const Attendance = require('../models/Attendance');

dotenv.config();

async function seedDatabase() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/attendance_system');
    console.log('Connected to MongoDB');

    // Clear existing data
    await Teacher.deleteMany({});
    await Class.deleteMany({});
    await Student.deleteMany({});
    await Attendance.deleteMany({});
    console.log('Cleared existing data');

    // ============ CREATE TEACHERS ============

    const teachers = await Teacher.create([
      {
        name: 'Dr. Rajesh Kumar',
        email: 'rajesh@school.edu',
        password: 'password123',
        phone: '+91 9876543210',
        department: 'Computer Science'
      },
      {
        name: 'Prof. Priya Singh',
        email: 'priya@school.edu',
        password: 'password123',
        phone: '+91 9876543211',
        department: 'Mathematics'
      },
      {
        name: 'Mr. Amit Patel',
        email: 'amit@school.edu',
        password: 'password123',
        phone: '+91 9876543212',
        department: 'Physics'
      }
    ]);

    console.log(`✓ Created ${teachers.length} teachers`);

    // ============ CREATE CLASSES ============

    const classes = await Class.create([
      {
        name: 'Class 10-A',
        subject: 'Computer Science',
        code: 'CS10A',
        section: 'A',
        semester: '1',
        teacher_id: teachers[0]._id,
        room_number: '101',
        description: 'Fundamentals of Computer Science',
        schedule: {
          day: 'Monday',
          time: '09:00 AM'
        }
      },
      {
        name: 'Class 10-B',
        subject: 'Computer Science',
        code: 'CS10B',
        section: 'B',
        semester: '1',
        teacher_id: teachers[0]._id,
        room_number: '102',
        description: 'Fundamentals of Computer Science'
      },
      {
        name: 'Class 9-A',
        subject: 'Mathematics',
        code: 'MATH9A',
        section: 'A',
        semester: '1',
        teacher_id: teachers[1]._id,
        room_number: '201',
        description: 'Advanced Mathematics'
      },
      {
        name: 'Class 11-A',
        subject: 'Physics',
        code: 'PHY11A',
        section: 'A',
        semester: '1',
        teacher_id: teachers[2]._id,
        room_number: '301',
        description: 'Physics Theory and Lab'
      }
    ]);

    console.log(`✓ Created ${classes.length} classes`);

    // ============ CREATE STUDENTS ============

    const studentNames = [
      { name: 'Arjun Sharma', roll: '001' },
      { name: 'Bhavna Desai', roll: '002' },
      { name: 'Chirag Gupta', roll: '003' },
      { name: 'Diya Verma', roll: '004' },
      { name: 'Eshan Kumar', roll: '005' },
      { name: 'Farah Khan', roll: '006' },
      { name: 'Gaurav Singh', roll: '007' },
      { name: 'Hina Patel', roll: '008' },
      { name: 'Ishaan Reddy', roll: '009' },
      { name: 'Jiya Nair', roll: '010' },
      { name: 'Karan Malhotra', roll: '011' },
      { name: 'Leena Rao', roll: '012' },
      { name: 'Madhav Chopra', roll: '013' },
      { name: 'Neha Saxena', roll: '014' },
      { name: 'Omkar Singh', roll: '015' }
    ];

    const allStudents = [];

    // Create students for each class
    for (const classObj of classes) {
      const classStudents = await Student.create(
        studentNames.map((s, index) => ({
          name: s.name,
          roll_no: s.roll,
          email: `${s.name.toLowerCase().replace(/\s+/g, '.')}@student.edu`,
          phone: `+91 ${9000000000 + index}`,
          class_id: classObj._id,
          date_of_birth: new Date(2008 + Math.floor(index / 5), index % 12, (index % 28) + 1),
          parent_name: s.name.split(' ')[0] + ' Parent',
          parent_phone: `+91 ${8000000000 + index}`,
          attendance_stats: {
            total_classes: 0,
            present_count: 0,
            absent_count: 0,
            late_count: 0
          }
        }))
      );

      allStudents.push(...classStudents);

      // Update class with students
      classObj.students = classStudents.map(s => s._id);
      await classObj.save();
    }

    console.log(`✓ Created ${allStudents.length} students`);

    // ============ UPDATE TEACHERS WITH CLASS ASSIGNMENTS ============

    teachers[0].assigned_classes = [classes[0]._id, classes[1]._id];
    teachers[1].assigned_classes = [classes[2]._id];
    teachers[2].assigned_classes = [classes[3]._id];

    await teachers[0].save();
    await teachers[1].save();
    await teachers[2].save();

    console.log('✓ Updated teacher class assignments');

    // ============ CREATE SAMPLE ATTENDANCE RECORDS ============

    const attendanceStatuses = ['PRESENT', 'ABSENT', 'LATE'];
    const attendanceRecords = [];

    // Create attendance for past 10 days
    for (let dayOffset = 0; dayOffset < 10; dayOffset++) {
      const currentDate = new Date();
      currentDate.setDate(currentDate.getDate() - dayOffset);
      currentDate.setHours(0, 0, 0, 0);

      for (const student of allStudents.slice(0, 30)) {
        // Random status
        const status = attendanceStatuses[Math.floor(Math.random() * attendanceStatuses.length)];

        const attendance = new Attendance({
          class_id: student.class_id,
          teacher_id: student.class_id === classes[0]._id || student.class_id === classes[1]._id 
            ? teachers[0]._id 
            : student.class_id === classes[2]._id 
            ? teachers[1]._id 
            : teachers[2]._id,
          student_id: student._id,
          status,
          date: currentDate,
          marked_by: 'MANUAL'
        });

        attendanceRecords.push(attendance);
      }
    }

    await Attendance.insertMany(attendanceRecords);
    console.log(`✓ Created ${attendanceRecords.length} attendance records`);

    // ============ UPDATE STUDENT STATISTICS ============

    for (const student of allStudents.slice(0, 30)) {
      const records = await Attendance.find({ student_id: student._id });

      let presentCount = 0;
      let absentCount = 0;
      let lateCount = 0;

      records.forEach(record => {
        if (record.status === 'PRESENT') presentCount++;
        else if (record.status === 'ABSENT') absentCount++;
        else if (record.status === 'LATE') lateCount++;
      });

      student.attendance_stats = {
        total_classes: records.length,
        present_count: presentCount,
        absent_count: absentCount,
        late_count: lateCount
      };

      await student.save();
    }

    console.log('✓ Updated student attendance statistics');

    // ============ UPDATE CLASS METADATA ============

    for (const classObj of classes) {
      const sessions = await Attendance.distinct('date', { class_id: classObj._id });
      classObj.total_sessions = sessions.length;
      if (sessions.length > 0) {
        classObj.last_attendance_date = new Date(Math.max(...sessions.map(d => d.getTime())));
      }
      await classObj.save();
    }

    console.log('✓ Updated class metadata');

    // ============ PRINT SUMMARY ============

    console.log(`
╔═════════════════════════════════════════════╗
║        DATABASE SEEDING COMPLETED           ║
╠═════════════════════════════════════════════╣
║ Teachers: ${teachers.length}                           ║
║ Classes: ${classes.length}                            ║
║ Students: ${allStudents.length}                          ║
║ Attendance Records: ${attendanceRecords.length}              ║
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

// Run seeding
seedDatabase();
