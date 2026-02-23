# Quick Reference Guide

## 🚀 Quick Start (5 minutes)

```bash
# Terminal 1: Backend
cd backend
npm install
npm run seed
npm start

# Terminal 2: Frontend
cd frontend
flutter pub get
flutter run

# Browser: Test API
curl http://localhost:5000/api/health
```

---

## 📱 Common Commands

### Backend Commands

```bash
# Install dependencies
npm install

# Seed database
npm run seed

# Start server
npm start

# Reset database
npm run seed

# MongoDB shell
mongo

# Check if running
curl http://localhost:5000/api/health
```

### Frontend Commands

```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Run on specific device
flutter run -d emulator-5554

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release

# Clean and rebuild
flutter clean && flutter pub get && flutter run

# Format code
flutter format lib/

# Analyze code
flutter analyze
```

---

## 🔑 Test Accounts

```
Teacher 1:
  Email: rajesh@school.edu
  Password: password123
  Classes: 10-A, 10-B

Teacher 2:
  Email: priya@school.edu
  Password: password123
  Classes: 9-A

Teacher 3:
  Email: amit@school.edu
  Password: password123
  Classes: 11-A
```

---

## 🎨 Key Files to Customize

### Colors & Theme
```
lib/theme/app_theme.dart

Lines to modify:
- Line 20-30: Primary color (currently #6366F1)
- Line 31-34: Success, warning, error colors
- Line 35-45: Text colors
```

### API Base URL
```
lib/services/api_service.dart

Line 9:
static const String baseUrl = 'http://localhost:5000/api';

For emulator:
static const String baseUrl = 'http://10.0.2.2:5000/api';
```

### Backend Port
```
backend/.env

Line 3:
PORT=5000
```

### Database URL
```
backend/.env

Line 6:
MONGODB_URI=mongodb://localhost:27017/attendance_system
```

---

## 📊 Database Quick Queries

```javascript
// MongoDB shell commands

// Count records
db.teachers.countDocuments()
db.classes.countDocuments()
db.students.countDocuments()
db.attendance.countDocuments()

// Find specific teacher
db.teachers.findOne({ email: "rajesh@school.edu" })

// Find teacher's classes
db.classes.find({ teacher_id: ObjectId("...") })

// Get attendance for a student
db.attendance.find({ student_id: ObjectId("...") }).sort({ date: -1 }).limit(10)

// Count by status
db.attendance.countDocuments({ status: "PRESENT" })
db.attendance.countDocuments({ status: "ABSENT" })
db.attendance.countDocuments({ status: "LATE" })

// Get today's attendance
db.attendance.find({ date: { $gte: new Date("2024-02-23") } })

// Update status
db.attendance.updateOne(
  { _id: ObjectId("...") },
  { $set: { status: "LATE" } }
)

// Delete all records
db.attendance.deleteMany({})
db.students.deleteMany({})
db.classes.deleteMany({})
db.teachers.deleteMany({})
```

---

## 🔐 Authentication Flow

```
1. User enters email & password
2. App sends: POST /api/auth/login
3. Backend verifies credentials against database
4. If valid: Generate JWT token
5. Token sent back to app
6. App saves token in SharedPreferences
7. All future requests include: Authorization: Bearer {token}
8. Backend verifies token on each request
9. If invalid: Return 401 Unauthorized
```

---

## 💾 Offline Attendance Marking

```
Feature (Currently stores locally):
1. User marks attendance while offline
2. App stores in memory (AttendanceProvider.pendingAttendance)
3. Shows "Pending: 15/20" indicator
4. When online, shows "Sync" button
5. Tap sync → Sends batch to server
6. Server processes → Updates database
7. App clears pending queue
```

---

## 🎯 Gesture System Quick Reference

```
Direction          Gesture         Status      Color     Threshold
───────────────────────────────────────────────────────────────────
Right              →               PRESENT     Green     > 100px
Left               ←               ABSENT      Red       < -100px
Down               ↓               LATE        Orange    > 100px
Up                 ↑               DETAILS     Blue      < -100px
```

---

## 🔧 Troubleshooting Commands

```bash
# Check all services running
curl http://localhost:5000/api/health
mongo --eval "db.version()"
flutter doctor

# Check MongoDB
mongod --version
mongo
  > show dbs
  > use attendance_system
  > show collections
  > exit

# Check Node.js
node --version
npm --version

# Clear Flutter cache
flutter clean
rm pubspec.lock
flutter pub get

# Kill hanging processes (Port 5000)
lsof -i :5000
kill -9 <PID>

# Check logs (if available)
tail -f backend/logs/app.log
```

---

## 📈 Performance Monitoring

### Frontend
- Open DevTools: `flutter run -v`
- Check frame times: Shift+P in app
- Monitor memory: `flutter run --profile`

### Backend
- Response times in terminal
- Check slow queries: Enable MongoDB profiling
- Monitor memory: `ps aux | grep node`

### Database
```javascript
// Enable profiling
db.setProfilingLevel(1)

// View slow operations
db.system.profile.find({ millis: { $gt: 100 } }).limit(5)
```

---

## 📦 Project File Sizes

```
Backend:
- server.js: 2 KB
- All models: 12 KB
- All routes: 15 KB
- Total code: ~30 KB

Frontend:
- main.dart: 1 KB
- All screens: 25 KB
- All providers: 12 KB
- Services: 5 KB
- Total code: ~50 KB

Database:
- Sample data: ~2 MB
- Indexes: ~1 MB
```

---

## 🚀 Deployment Checklist

- [ ] Change JWT_SECRET in .env
- [ ] Set NODE_ENV=production
- [ ] Configure database connection (MongoDB Atlas)
- [ ] Update FRONTEND_URL
- [ ] Enable HTTPS
- [ ] Configure CORS properly
- [ ] Set up monitoring & logging
- [ ] Create backups strategy
- [ ] Test all endpoints
- [ ] Run security audit
- [ ] Load testing
- [ ] Document environment variables

---

## 📚 Important Files

```
README.md              ← Start here
SETUP.md              ← Installation guide
API.md                ← API reference
ARCHITECTURE.md       ← System design

Backend:
server.js             ← Entry point
models/               ← Database schemas
routes/               ← API endpoints
middleware/           ← Auth, validation

Frontend:
main.dart             ← App entry
services/             ← API calls
providers/            ← State management
screens/              ← UI screens
theme/                ← Design system
```

---

## 🔗 Useful Links

**Documentation:**
- Flutter Docs: https://flutter.dev/docs
- Express Docs: https://expressjs.com
- Mongoose Docs: https://mongoosejs.com
- Provider Pattern: https://pub.dev/packages/provider

**Tools:**
- MongoDB Atlas: https://www.mongodb.com/cloud/atlas
- Heroku: https://www.heroku.com
- Firebase Console: https://console.firebase.google.com
- Postman: https://www.postman.com

**Learning:**
- Dart/Flutter: https://dart.dev
- Node.js: https://nodejs.org/en/docs
- REST APIs: https://restfulapi.net
- JWT: https://jwt.io

---

## ✅ Verification Checklist

After setup, verify:

- [ ] Backend starts without errors
- [ ] MongoDB has sample data
- [ ] Flutter app installs
- [ ] Can login with rajesh@school.edu
- [ ] Dashboard shows 2 classes
- [ ] Can navigate to attendance screen
- [ ] Can swipe cards (Right = Present, etc.)
- [ ] Submission works without errors
- [ ] Analytics screen shows data
- [ ] Can logout

---

## 💡 Tips & Tricks

1. **Hot Reload in Flutter**: Save file = instant reload (l key in terminal)
2. **Undo Swipe**: Click "Undo" button to revert last swipe
3. **View Student Details**: Swipe UP on card for profile modal
4. **Batch Operations**: Mark all, then submit (not per-student)
5. **Offline Mode**: Marks are stored locally until sync
6. **Database Reset**: Run `npm run seed` to reset everything
7. **API Testing**: Use Postman + Bearer token from login
8. **Color Coding**: Green=Present, Red=Absent, Orange=Late
9. **Progress Tracking**: Watch progress bar fill as you swipe
10. **Error Messages**: Read carefully, they guide what's wrong

---

## 🎓 Learning Resources

### Flutter Concepts Used
- StatefulWidget & State
- Provider Pattern (ChangeNotifier)
- Gesture Detection
- Animation Controller
- Network Requests
- SharedPreferences

### Backend Concepts Used
- REST API Design
- JWT Authentication
- Express Middleware
- MongoDB Schemas
- Password Hashing
- Error Handling

### Database Concepts Used
- Collections & Documents
- Indexing
- Aggregation
- Relationships
- Schema Design

---

## 📞 Getting Help

1. **Check Documentation**
   - README.md (Overview)
   - SETUP.md (Installation)
   - API.md (Endpoints)
   - ARCHITECTURE.md (Design)

2. **Debug Steps**
   - Enable verbose logging
   - Check error messages
   - Review terminal output
   - Check network tab
   - Verify database state

3. **Common Issues**
   - Port already in use → Kill process or use different port
   - MongoDB not found → Install or start service
   - API timeout → Check backend running + correct URL
   - Login failed → Verify seed ran + credentials correct
   - Gesture not working → Ensure card is active (top)

4. **Getting Logs**
   - Backend: Terminal output
   - Frontend: `flutter run -v`
   - Database: `db.system.profile.find()`

---

**Last Updated: February 2024**

For the most up-to-date information, check the main README.md
