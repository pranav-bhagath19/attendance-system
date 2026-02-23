/**
 * Attendance Model
 * Records attendance marks for each student in each class session
 */

const mongoose = require('mongoose');

const attendanceSchema = new mongoose.Schema(
  {
    class_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Class',
      required: [true, 'Class is required'],
      index: true
    },

    teacher_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Teacher',
      required: [true, 'Teacher is required'],
      index: true
    },

    student_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Student',
      required: [true, 'Student is required']
    },

    status: {
      type: String,
      enum: ['PRESENT', 'ABSENT', 'LATE', 'EXCUSED'],
      required: [true, 'Status is required'],
      uppercase: true
    },

    date: {
      type: Date,
      required: [true, 'Attendance date is required'],
      index: true,
      validate: {
        validator: function(value) {
          return value <= new Date(); // ✅ No future dates
        },
        message: 'Date cannot be in the future'
      }
    },

    marked_at: {
      type: Date,
      default: Date.now
    },

    marked_by: {
      type: String,
      enum: ['MANUAL', 'SWIPE', 'BIOMETRIC'],
      default: 'SWIPE'
    },

    notes: {
      type: String,
      default: null,
      maxlength: [500, 'Notes cannot exceed 500 characters']
    },

    edited_at: {
      type: Date,
      default: null
    },

    edited_by: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Teacher',
      default: null
    }
  },
  {
    timestamps: true,
    collection: 'attendance'
  }
);

// ============ INDEXES ============

// Composite index for fast queries
attendanceSchema.index({ class_id: 1, date: 1 });
attendanceSchema.index({ student_id: 1, date: 1 });
attendanceSchema.index({ teacher_id: 1, date: 1 });

// Unique index to prevent duplicate attendance marks
attendanceSchema.index({ class_id: 1, student_id: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('Attendance', attendanceSchema);
