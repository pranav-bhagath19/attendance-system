/**
 * Class Model
 * Represents classes with associated teacher and students
 */

const mongoose = require('mongoose');

const classSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Class name is required'],
      trim: true,
      maxlength: [50, 'Class name cannot exceed 50 characters']
    },

    subject: {
      type: String,
      required: [true, 'Subject is required'],
      trim: true,
      maxlength: [50, 'Subject cannot exceed 50 characters']
    },

    code: {
      type: String,
      unique: true,
      sparse: true,
      uppercase: true
    },

    teacher_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Teacher',
      required: [true, 'Class must be assigned to a teacher']
    },

    section: {
      type: String,
      default: 'A'
    },

    semester: {
      type: String,
      default: null
    },

    students: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Student'
      }
    ],

    description: {
      type: String,
      default: null
    },

    room_number: {
      type: String,
      default: null
    },

    schedule: {
      day: {
        type: String,
        enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
        default: null
      },
      time: {
        type: String,
        default: null
      }
    },

    is_active: {
      type: Boolean,
      default: true
    },

    total_sessions: {
      type: Number,
      default: 0
    },

    last_attendance_date: {
      type: Date,
      default: null
    }
  },
  {
    timestamps: true,
    collection: 'classes'
  }
);

// ============ INDEXES ============

classSchema.index({ teacher_id: 1 });
classSchema.index({ code: 1 });
classSchema.index({ is_active: 1 });

// ============ VIRTUAL FIELDS ============

classSchema.virtual('student_count').get(function () {
  return this.students ? this.students.length : 0;
});

module.exports = mongoose.model('Class', classSchema);
