# Setup Guide

Complete step-by-step instructions to get the Attendance Management System running locally.

## Prerequisites

### System Requirements
- Windows/Mac/Linux
- 4GB RAM minimum
- 5GB disk space

### Software Requirements
- **Node.js** v16 or higher ([Download](https://nodejs.org))
- **MongoDB** 4.4 or higher ([Download](https://www.mongodb.com/try/download/community))
- **Flutter** 3.0 or higher ([Download](https://flutter.dev))
- **Git** ([Download](https://git-scm.com))
- **VS Code** or Android Studio (optional but recommended)

---

## Backend Setup

### Step 1: Navigate to Backend Directory

```bash
cd attendance_system/backend
```

### Step 2: Install Dependencies

```bash
npm install
```

This will install all packages listed in `package.json`:
- express
- mongoose
- jsonwebtoken
- bcryptjs
- cors
- and more...

### Step 3: Configure Environment

Create/edit `.env` file in the backend directory:

```env
# Server Configuration
NODE_ENV=development
PORT=5000
FRONTEND_URL=http://localhost:3000

# Database Configuration
MONGODB_URI=mongodb://localhost:27017/attendance_system

# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_change_in_production_12345
JWT_EXPIRE=7d

# File Upload
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=5242880

# Logging
LOG_LEVEL=debug
```

**Important:** Change `JWT_SECRET` in production!

### Step 4: Start MongoDB

#### On Windows:
```bash
# If MongoDB is installed locally
mongod
```

#### On Mac:
```bash
# If installed via Homebrew
brew services start mongodb-community
```

#### On Linux:
```bash
sudo service mongod start
```

#### Using Docker (Alternative):
```bash
docker run -d -p 27017:27017 --name mongodb mongo:latest
```

Verify MongoDB is running:
```bash
mongo
# Should connect without error, then type "exit"
```

### Step 5: Seed Database

This populates MongoDB with sample data (teachers, classes, students, attendance records):

```bash
npm run seed
```

**Output:**
```
✓ MongoDB Connected Successfully
✓ Created 3 teachers
✓ Created 4 classes
✓ Created 60 students
✓ Created 300 attendance records
✓ Updated student attendance statistics
✓ Updated class metadata

╔═════════════════════════════════════════════╗
║        DATABASE SEEDING COMPLETED           ║
╠═════════════════════════════════════════════╣
║ Teachers: 3                                 ║
║ Classes: 4                                  ║
║ Students: 60                                ║
║ Attendance Records: 300                     ║
╠═════════════════════════════════════════════╣
║ TEST CREDENTIALS:                           ║
║ Email: rajesh@school.edu                   ║
║ Password: password123                      ║
╚═════════════════════════════════════════════╝
```

### Step 6: Start Backend Server

```bash
npm start
```

**Output:**
```
╔════════════════════════════════════════╗
║  Attendance Management API             ║
║  Server running on port 5000           ║
║  Environment: development              ║
╚════════════════════════════════════════╝
```

### Step 7: Verify API is Running

In a new terminal:

```bash
curl http://localhost:5000/api/health
```

**Response:**
```json
{
  "status": "API is running",
  "timestamp": "2024-02-23T10:30:00Z",
  "environment": "development"
}
```

---

## Frontend Setup

### Step 1: Navigate to Frontend Directory

```bash
cd attendance_system/frontend
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

This installs all packages from `pubspec.yaml`.

### Step 3: Configure API URL

Edit `lib/services/api_service.dart`:

```dart
class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';  // ← Update this
  // ...
}
```

**For Android Emulator:**
```dart
static const String baseUrl = 'http://10.0.2.2:5000/api';
```

**For Physical Device:**
```dart
// Get your machine IP (Windows: ipconfig, Mac/Linux: ifconfig)
static const String baseUrl = 'http://192.168.x.x:5000/api';
```

### Step 4: Start Emulator/Device

#### Android Emulator:
```bash
flutter emulators --launch emulator-5554
```

#### iOS Simulator:
```bash
open -a Simulator
```

#### Physical Device:
- Connect device via USB
- Enable Developer Mode
- Allow USB debugging

### Step 5: Run Flutter App

```bash
flutter run
```

**For specific device:**
```bash
flutter run -d emulator-5554    # Android
flutter run -d iphone           # iOS
```

**First run takes 2-3 minutes for building.**

### Step 6: Verify App is Running

- See splash screen (3 seconds)
- Login screen appears
- Enter test credentials
- Dashboard loads with classes

---

## Testing the Application

### Test Accounts

Three pre-seeded teacher accounts:

| Email | Password | Class |
|-------|----------|-------|
| rajesh@school.edu | password123 | Class 10-A, 10-B |
| priya@school.edu | password123 | Class 9-A |
| amit@school.edu | password123 | Class 11-A |

### Basic Flow

1. **Login**
   - Open app
   - Enter: rajesh@school.edu
   - Password: password123
   - Tap "Login"

2. **Dashboard**
   - See all assigned classes
   - View student count, sessions
   - Tap on any class to mark attendance

3. **Swipe Attendance**
   - Card appears with student info
   - Swipe right (→) for Present (Green)
   - Swipe left (←) for Absent (Red)
   - Swipe down (↓) for Late (Orange)
   - Swipe up (↑) for Details modal
   - Undo last swipe if needed

4. **Report**
   - After marking all students
   - Review attendance summary
   - Edit any status if needed
   - Submit to backend

5. **Analytics**
   - See class-wide statistics
   - Individual attendance percentages
   - Attendance trends

---

## Troubleshooting

### Issue: MongoDB Connection Error

**Error:**
```
✗ MongoDB Connection Error: connect ECONNREFUSED
```

**Solution:**
1. Verify MongoDB is installed: `mongod --version`
2. Start MongoDB: `mongod`
3. Check port 27017 is not blocked
4. Try with Docker: `docker run -d -p 27017:27017 mongo`

---

### Issue: Port 5000 Already in Use

**Error:**
```
Error: listen EADDRINUSE: address already in use :::5000
```

**Solution:**
```bash
# Find process using port 5000
lsof -i :5000

# Kill the process
kill -9 <PID>

# Or use different port
PORT=5001 npm start
```

---

### Issue: Flutter Build Error

**Error:**
```
error: SDK location not found
```

**Solution:**
```bash
flutter doctor
flutter doctor --android-licenses
flutter config --android-sdk /path/to/android/sdk
```

---

### Issue: API Connection Timeout

**Error:**
```
Connection timeout - cannot reach API
```

**Solution:**
1. Verify backend is running: `curl http://localhost:5000/api/health`
2. Check API URL in `api_service.dart`
3. For emulator, use `10.0.2.2` instead of `localhost`
4. Check firewall isn't blocking port 5000

---

### Issue: Login Failed

**Error:**
```
Invalid email or password
```

**Solution:**
1. Verify seeding completed: `npm run seed`
2. Check database has teachers: `mongo` → `db.teachers.findOne()`
3. Try exact credentials: rajesh@school.edu / password123
4. Check password case-sensitivity

---

### Issue: Student Cards Not Loading

**Error:**
```
No students found
```

**Solution:**
1. Verify class has students in MongoDB
2. Check ClassProvider is fetching correctly
3. Look at network logs in browser DevTools
4. Verify API endpoint: `/api/teacher/class/:id/students`

---

## Database Management

### Access MongoDB CLI

```bash
mongo
```

### Useful Commands

```javascript
// List all databases
show dbs

// Switch to attendance database
use attendance_system

// List all collections
show collections

// Count documents
db.teachers.countDocuments()
db.students.countDocuments()
db.attendance.countDocuments()

// View sample teacher
db.teachers.findOne()

// View all classes
db.classes.find().pretty()

// Delete all attendance for today
db.attendance.deleteMany({ date: { $gte: ISODate("2024-02-23") } })

// Reset database
db.dropDatabase()
```

---

## Advanced Configuration

### Email Notifications (Optional)

To enable email notifications, set in `.env`:

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_specific_password
```

Generate app password at: https://myaccount.google.com/apppasswords

---

### Database Backup

```bash
# Backup database
mongodump --db attendance_system --out ./backup

# Restore database
mongorestore --db attendance_system ./backup/attendance_system
```

---

### Custom Seed Data

Modify `backend/scripts/seed.js` to add more teachers/classes/students, then run:

```bash
npm run seed
```

---

## Performance Tips

1. **Indexing**: Database already has indexes on frequently queried fields
2. **Caching**: Flutter caches images and API responses
3. **Offline Support**: Attendance can be marked offline and synced later
4. **Pagination**: For large student lists, implement pagination

---

## Development Tools

### Recommended Extensions

**VS Code:**
- Dart
- Flutter
- REST Client
- MongoDB for VS Code
- Prettier

**Android Studio:**
- Flutter
- Dart Analyzer
- Firebase Tools (optional)

### Debugging

**Backend:**
```bash
# Enable debug logging
LOG_LEVEL=debug npm start

# Use VS Code debugger with breakpoints
```

**Frontend:**
```bash
# Enable verbose logging
flutter run -v

# Use Flutter DevTools
flutter pub global activate devtools
devtools
```

---

## Next Steps

1. ✅ Setup complete
2. 📱 Test the application
3. 🎨 Customize colors/fonts in `theme/app_theme.dart`
4. 🔐 Change JWT secret before production
5. ☁️ Deploy to cloud (Heroku, AWS, etc.)

---

## Getting Help

- Check error logs carefully
- Read API Documentation: `docs/API.md`
- Review Architecture: `docs/ARCHITECTURE.md`
- GitHub Issues: Open an issue with error details
- Logs Location: `backend/logs/` (once implemented)

---

**Happy Development! 🚀**
