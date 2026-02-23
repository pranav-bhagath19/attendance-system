/**
 * Student Model
 * Represents students enrolled in classes
 */

const mongoose = require('mongoose');

const studentSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Student name is required'],
      trim: true,
      minlength: [3, 'Name must be at least 3 characters'],
      maxlength: [50, 'Name cannot exceed 50 characters']
    },

    roll_no: {
      type: String,
      required: [true, 'Roll number is required'],
      trim: true
    },

    email: {
      type: String,
      default: null,
      match: [/^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/, 'Please provide a valid email']
    },

    phone: {
      type: String,
      default: null
    },

    class_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Class',
      required: [true, 'Student must be assigned to a class']
    },

    photo: {
      type: String,
      default: null // File path to uploaded image
    },

    date_of_birth: {
      type: Date,
      default: null
    },

    address: {
      type: String,
      default: null
    },

    parent_name: {
      type: String,
      default: null
    },

    parent_phone: {
      type: String,
      default: null
    },

    enrollment_date: {
      type: Date,
      default: Date.now
    },

    is_active: {
      type: Boolean,
      default: true
    },

    attendance_stats: {
      total_classes: {
        type: Number,
        default: 0
      },
      present_count: {
        type: Number,
        default: 0
      },
      absent_count: {
        type: Number,
        default: 0
      },
      late_count: {
        type: Number,
        default: 0
      }
    }
  },
  {
    timestamps: true,
    collection: 'students'
  }
);

// ============ INDEXES ============

studentSchema.index({ roll_no: 1, class_id: 1 });
studentSchema.index({ class_id: 1 });
studentSchema.index({ is_active: 1 });

// ============ VIRTUAL FIELDS ============

studentSchema.virtual('attendance_percentage').get(function () {
  const total = this.attendance_stats.total_classes || 1;
  const present = this.attendance_stats.present_count || 0;
  return Math.round((present / total) * 100);
});

module.exports = mongoose.model('Student', studentSchema);
