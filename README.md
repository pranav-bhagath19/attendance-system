# 📱 Swipe-Based Smart Attendance Management System

A modern, production-ready attendance management application built with Flutter and Node.js. Teachers can mark attendance quickly using intuitive swipe gestures on student cards—just like Tinder!

## ✨ Features

### Core Features
- **Swipe-Based Attendance Marking**
  - Swipe Right → Present (Green) ✓
  - Swipe Left → Absent (Red) ✗
  - Swipe Down → Late (Orange) ⏱
  - Swipe Up → View Details 👆

- **Teacher Authentication**
  - Secure JWT-based login
  - Auto-login with session management
  - Token-based authorization

- **Dashboard**
  - View all assigned classes
  - Class statistics (students, sessions)
  - Quick access to mark attendance

- **Attendance Reporting**
  - Summary view after marking
  - Editable attendance records
  - Status modification capability

- **Analytics & Reporting**
  - Individual student attendance percentage
  - Class-wide statistics
  - Progress indicators
  - Attendance trends

- **Local Caching**
  - Offline marking support
  - Automatic sync when online
  - Pending attendance management

## 🏗️ Project Structure

```
attendance_system/
├── backend/                          # Node.js/Express API
│   ├── models/                       # MongoDB schemas
│   │   ├── Teacher.js               # Teacher model
│   │   ├── Class.js                 # Class model
│   │   ├── Student.js               # Student model
│   │   └── Attendance.js            # Attendance model
│   ├── routes/                      # API endpoints
│   │   ├── auth.js                  # Authentication routes
│   │   ├── teacher.js               # Teacher routes
│   │   └── attendance.js            # Attendance routes
│   ├── middleware/                  # Express middleware
│   │   ├── auth.js                  # JWT verification
│   │   └── validation.js            # Input validation
│   ├── scripts/                     # Utility scripts
│   │   └── seed.js                  # Database seeding
│   ├── server.js                    # Main server file
│   ├── .env                         # Environment variables
│   └── package.json                 # Dependencies
│
├── frontend/                         # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart                # App entry point
│   │   ├── theme/                   # UI theme configuration
│   │   │   └── app_theme.dart
│   │   ├── services/                # API clients
│   │   │   └── api_service.dart
│   │   ├── providers/               # State management
│   │   │   ├── auth_provider.dart
│   │   │   ├── class_provider.dart
│   │   │   └── attendance_provider.dart
│   │   └── screens/                 # UI screens
│   │       ├── splash_screen.dart
│   │       ├── auth/
│   │       │   └── login_screen.dart
│   │       └── home/
│   │           ├── dashboard_screen.dart
│   │           ├── attendance_screen.dart (CORE FEATURE)
│   │           ├── attendance_report_screen.dart
│   │           └── analytics_screen.dart
│   └── pubspec.yaml                 # Dependencies
│
├── database/                         # Database documentation
│   └── schema.md                     # MongoDB schema
│
└── docs/                            # Documentation
    ├── API.md                       # API documentation
    ├── SETUP.md                     # Setup guide
    └── ARCHITECTURE.md              # Architecture docs
```

## 🚀 Quick Start

### Prerequisites
- Node.js v16+ 
- Flutter 3.0+
- MongoDB 4.4+
- Android/iOS emulator or physical device

### Backend Setup

```bash
# 1. Navigate to backend directory
cd backend

# 2. Install dependencies
npm install

# 3. Configure environment
# Edit .env file with your settings
nano .env

# 4. Start MongoDB (if not running)
mongod

# 5. Seed database with sample data
npm run seed

# 6. Start backend server
npm start
# Server runs on http://localhost:5000
```

### Frontend Setup

```bash
# 1. Navigate to frontend directory
cd frontend

# 2. Install dependencies
flutter pub get

# 3. Update API base URL (if needed)
# Edit lib/services/api_service.dart
# Change baseUrl to your backend URL

# 4. Run on Android
flutter run -d emulator

# 5. Run on iOS
flutter run -d iphone
```

## 🔐 Authentication

### Test Credentials (After Seeding)

```
Email: rajesh@school.edu
Password: password123
```

Also available:
- priya@school.edu (password123)
- amit@school.edu (password123)

### Authentication Flow

1. Teacher enters email and password
2. Backend validates and generates JWT token
3. Token stored in SharedPreferences
4. Token included in all API requests
5. Auto-login if valid session exists

## 📡 API Endpoints

### Authentication
```
POST   /api/auth/login              → Login teacher
POST   /api/auth/logout             → Logout
GET    /api/auth/me                 → Get current teacher
POST   /api/auth/verify-token       → Verify token validity
```

### Classes
```
GET    /api/teacher/classes         → Get all classes
GET    /api/teacher/class/:id       → Get class details
GET    /api/teacher/class/:id/students → Get students for swiping
GET    /api/teacher/dashboard       → Get dashboard summary
```

### Attendance
```
POST   /api/attendance/mark         → Mark single attendance
POST   /api/attendance/batch-mark   → Mark multiple attendances
GET    /api/attendance/class/:id    → Get attendance report
PUT    /api/attendance/:id          → Update attendance
GET    /api/attendance/student/:id  → Get student history
GET    /api/attendance/analytics/:id → Get class analytics
```

## 🎨 UI/UX Design

### Design System
- **Color Palette**
  - Primary: #6366F1 (Indigo)
  - Success: #10B981 (Green)
  - Warning: #F59E0B (Amber)
  - Error: #EF4444 (Red)

- **Typography**
  - Font: Poppins
  - Sizes: 12px (body) to 32px (display)

- **Spacing**
  - xs: 4px, sm: 8px, md: 12px, lg: 16px, xl: 24px

- **Shadows**
  - Small, medium, large elevation

## 🎯 Gesture System

### Swipe Gestures

```
PRESENT (Right Swipe)
├─ Threshold: 100px to the right
├─ Color: Green (#10B981)
├─ Animation: Card exits right
└─ Status: PRESENT

ABSENT (Left Swipe)
├─ Threshold: 100px to the left
├─ Color: Red (#EF4444)
├─ Animation: Card exits left
└─ Status: ABSENT

LATE (Down Swipe)
├─ Threshold: 100px downward
├─ Color: Orange (#F59E0B)
├─ Animation: Card slides down
└─ Status: LATE

DETAILS (Up Swipe)
├─ Threshold: 100px upward
├─ Animation: Modal slides up
└─ Shows: Profile panel with action buttons
```

## 💾 Database Schema

### Teachers Collection
```javascript
{
  _id: ObjectId,
  name: String,
  email: String (unique),
  password: String (hashed),
  phone: String,
  department: String,
  assigned_classes: [ObjectId],
  is_active: Boolean,
  last_login: Date,
  createdAt: Date,
  updatedAt: Date
}
```

### Classes Collection
```javascript
{
  _id: ObjectId,
  name: String,
  subject: String,
  code: String (unique),
  teacher_id: ObjectId,
  section: String,
  students: [ObjectId],
  total_sessions: Number,
  last_attendance_date: Date,
  is_active: Boolean,
  createdAt: Date,
  updatedAt: Date
}
```

### Students Collection
```javascript
{
  _id: ObjectId,
  name: String,
  roll_no: String,
  email: String,
  phone: String,
  class_id: ObjectId,
  photo: String,
  attendance_stats: {
    total_classes: Number,
    present_count: Number,
    absent_count: Number,
    late_count: Number
  },
  is_active: Boolean,
  createdAt: Date,
  updatedAt: Date
}
```

### Attendance Collection
```javascript
{
  _id: ObjectId,
  class_id: ObjectId,
  teacher_id: ObjectId,
  student_id: ObjectId,
  status: String (PRESENT|ABSENT|LATE|EXCUSED),
  date: Date,
  marked_at: Date,
  marked_by: String (MANUAL|SWIPE|BIOMETRIC),
  notes: String,
  edited_at: Date,
  edited_by: ObjectId,
  createdAt: Date,
  updatedAt: Date
}
```

## 📊 State Management

Using **Provider Pattern** for state management:

- **AuthProvider**: Manages login, logout, token, teacher data
- **ClassProvider**: Manages classes and students list
- **AttendanceProvider**: Manages attendance marking and reports

## 🔒 Security

- **Password Security**: Bcrypt hashing with 10 salt rounds
- **JWT Tokens**: Signed with HS256, 7-day expiration
- **Input Validation**: Express-validator for all inputs
- **Authorization**: Verified token on protected routes
- **CORS**: Configured for frontend domain
- **Unique Constraints**: Email, class code, attendance records

## 🚀 Deployment

### Backend Deployment (Heroku)
```bash
# Create Heroku app
heroku create attendance-api

# Set environment variables
heroku config:set MONGODB_URI=<your-mongodb-uri>
heroku config:set JWT_SECRET=<your-secret>

# Deploy
git push heroku main
```

### Frontend Deployment (App Stores)
```bash
# Build Android APK
flutter build apk --release

# Build iOS IPA
flutter build ios --release
```

## 📈 Performance Optimization

- **Lazy Loading**: Students loaded on demand
- **Caching**: Network responses cached locally
- **Pagination**: Large lists paginated (future)
- **Image Optimization**: Cached network images
- **Database Indexes**: Composite indexes on frequent queries
- **Offline Support**: Local pending attendance marking

## 🧪 Testing

### Test Accounts
- Teacher 1: rajesh@school.edu (password123)
- Teacher 2: priya@school.edu (password123)
- Teacher 3: amit@school.edu (password123)

### Sample Data
- 4 classes with 15+ students each
- 10 days of attendance history
- 300+ attendance records

## 📚 Documentation

See detailed documentation in:
- `docs/SETUP.md` - Detailed setup instructions
- `docs/API.md` - Complete API reference
- `docs/ARCHITECTURE.md` - System architecture

## 🐛 Troubleshooting

### Connection Issues
```bash
# Check backend is running
curl http://localhost:5000/api/health

# Check MongoDB
mongo
```

### Login Issues
- Verify credentials match seeded data
- Check JWT_SECRET in .env matches
- Clear app cache and login again

### Gesture Not Working
- Ensure card is the active one (top)
- Check threshold values (100px)
- Verify gesture recognizer is enabled

## 📝 License

MIT License - Feel free to use this project

## 👨‍💻 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📞 Support

For issues and questions:
- Check documentation first
- Open GitHub issue
- Email: support@attendance-app.com

---

**Made with ❤️ for efficient attendance management**
