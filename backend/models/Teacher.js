/**
 * Teacher Model
 * Represents teachers in the system with authentication credentials and class assignments
 */

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const teacherSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Teacher name is required'],
      trim: true,
      minlength: [3, 'Name must be at least 3 characters'],
      maxlength: [50, 'Name cannot exceed 50 characters']
    },

    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      match: [/^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/, 'Please provide a valid email']
    },

    password: {
      type: String,
      required: [true, 'Password is required'],
      minlength: [6, 'Password must be at least 6 characters'],
      select: false // Don't return password by default
    },

    phone: {
      type: String,
      default: null
    },

    department: {
      type: String,
      default: null
    },

    assigned_classes: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Class'
      }
    ],

    is_active: {
      type: Boolean,
      default: true
    },

    profile_image: {
      type: String,
      default: null
    },

    last_login: {
      type: Date,
      default: null
    }
  },
  {
    timestamps: true,
    collection: 'teachers'
  }
);

// ============ INDEXES ============

teacherSchema.index({ email: 1 });
teacherSchema.index({ is_active: 1 });

// ============ MIDDLEWARE ============

// Hash password before saving
teacherSchema.pre('save', async function (next) {
  // Only hash password if it's new or modified
  if (!this.isModified('password')) {
    return next();
  }

  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Remove password from JSON response
teacherSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.password;
  return obj;
};

// ============ METHODS ============

/**
 * Compare password for authentication
 * @param {string} enteredPassword - Password entered by user
 * @returns {Promise<boolean>} - True if password matches
 */
teacherSchema.methods.matchPassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

const Teacher = mongoose.model('Teacher', teacherSchema);

module.exports = Teacher;
