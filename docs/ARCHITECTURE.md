# System Architecture

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Mobile App                      │
│  (Android + iOS with single codebase)                       │
├─────────────────────────────────────────────────────────────┤
│  • Login Screen                                             │
│  • Dashboard (Classes List)                                 │
│  • Swipe Attendance Screen (Core Feature)                   │
│  • Attendance Report Screen                                 │
│  • Analytics Screen                                         │
└─────────────────────┬───────────────────────────────────────┘
                      │ HTTP/HTTPS (REST API)
                      │ JWT Bearer Token
                      ▼
┌─────────────────────────────────────────────────────────────┐
│            Express.js + Node.js Backend Server              │
├─────────────────────────────────────────────────────────────┤
│  • Authentication Routes (/api/auth)                        │
│  • Teacher Routes (/api/teacher)                            │
│  • Attendance Routes (/api/attendance)                      │
│  • Middleware (Auth, Validation)                            │
│  • Error Handling & Logging                                 │
└─────────────────────┬───────────────────────────────────────┘
                      │ MongoDB Driver
                      │ CRUD Operations
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    MongoDB Database                         │
├─────────────────────────────────────────────────────────────┤
│  • Teachers Collection                                      │
│  • Classes Collection                                       │
│  • Students Collection                                      │
│  • Attendance Collection                                    │
│  • Indexes for Fast Queries                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## Component Architecture

### Frontend (Flutter)

```
lib/
├── main.dart
│   └── MultiProvider Setup
│       ├── AuthProvider
│       ├── ClassProvider
│       └── AttendanceProvider
│
├── theme/
│   └── app_theme.dart
│       ├── Colors
│       ├── Typography
│       ├── Shadows
│       └── Spacing Constants
│
├── services/
│   └── api_service.dart
│       ├── Dio HTTP Client
│       ├── Interceptors
│       └── All API Methods
│
├── providers/
│   ├── auth_provider.dart
│       ├── Login/Logout
│       ├── Token Management
│       └── Teacher Profile
│   ├── class_provider.dart
│       ├── Fetch Classes
│       ├── Fetch Class Details
│       └── Fetch Students
│   └── attendance_provider.dart
│       ├── Mark Attendance
│       ├── Batch Mark
│       ├── Fetch Reports
│       ├── Offline Queue
│       └── Analytics
│
└── screens/
    ├── splash_screen.dart
    ├── auth/
    │   └── login_screen.dart
    └── home/
        ├── dashboard_screen.dart
        ├── attendance_screen.dart ⭐ CORE
        ├── attendance_report_screen.dart
        └── analytics_screen.dart
```

### Backend (Node.js/Express)

```
backend/
├── server.js
│   ├── Express Setup
│   ├── CORS Configuration
│   ├── Middleware Registration
│   ├── Route Setup
│   └── Error Handling
│
├── models/
│   ├── Teacher.js
│   │   ├── Schema Definition
│   │   ├── Indexes
│   │   ├── Password Hashing
│   │   └── Methods
│   ├── Class.js
│   ├── Student.js
│   └── Attendance.js
│
├── routes/
│   ├── auth.js
│   │   ├── POST /login
│   │   ├── POST /logout
│   │   ├── GET /me
│   │   └── POST /verify-token
│   ├── teacher.js
│   │   ├── GET /classes
│   │   ├── GET /class/:id
│   │   ├── GET /class/:id/students
│   │   └── GET /dashboard
│   └── attendance.js
│       ├── POST /mark
│       ├── POST /batch-mark
│       ├── GET /class/:id
│       ├── PUT /:id
│       ├── GET /student/:id
│       └── GET /analytics/:id
│
├── middleware/
│   ├── auth.js
│   │   ├── JWT Verification
│   │   ├── Token Generation
│   │   └── Authorization Checks
│   └── validation.js
│       ├── Input Validation Rules
│       ├── Error Handling
│       └── Sanitization
│
├── scripts/
│   └── seed.js
│       ├── Database Clearing
│       ├── Sample Data Generation
│       └── Relationship Setup
│
└── config/
    └── .env (Not in repo)
        ├── Database URI
        ├── JWT Secret
        ├── Port
        └── Environment
```

### Database (MongoDB)

```
attendance_system (Database)
│
├── teachers
│   ├── _id (ObjectId)
│   ├── name (String)
│   ├── email (String, unique, indexed)
│   ├── password (String, hashed)
│   ├── phone (String)
│   ├── department (String)
│   ├── assigned_classes [ObjectId]
│   ├── is_active (Boolean, indexed)
│   ├── last_login (Date)
│   └── timestamps
│
├── classes
│   ├── _id (ObjectId)
│   ├── name (String)
│   ├── subject (String)
│   ├── code (String, unique, indexed)
│   ├── teacher_id (ObjectId, indexed)
│   ├── section (String)
│   ├── students [ObjectId]
│   ├── total_sessions (Number)
│   ├── last_attendance_date (Date, indexed)
│   ├── is_active (Boolean)
│   └── timestamps
│
├── students
│   ├── _id (ObjectId)
│   ├── name (String)
│   ├── roll_no (String)
│   ├── email (String)
│   ├── phone (String)
│   ├── class_id (ObjectId, indexed)
│   ├── photo (String)
│   ├── attendance_stats
│   │   ├── total_classes
│   │   ├── present_count
│   │   ├── absent_count
│   │   └── late_count
│   ├── is_active (Boolean)
│   └── timestamps
│
└── attendance
    ├── _id (ObjectId)
    ├── class_id (ObjectId, indexed)
    ├── teacher_id (ObjectId, indexed)
    ├── student_id (ObjectId)
    ├── status (String: PRESENT|ABSENT|LATE|EXCUSED)
    ├── date (Date, indexed)
    ├── marked_at (Date)
    ├── marked_by (String: MANUAL|SWIPE|BIOMETRIC)
    ├── notes (String)
    ├── edited_at (Date)
    ├── edited_by (ObjectId)
    └── timestamps
    
Indexes:
├── class_id + date (compound)
├── student_id + date (compound)
├── teacher_id + date (compound)
└── class_id + student_id + date (unique)
```

---

## Data Flow Diagram

### Authentication Flow

```
┌─────────────┐
│   Flutter   │
│   App       │
└──────┬──────┘
       │
       │ 1. POST /auth/login
       │    {email, password}
       ▼
┌─────────────────────────────┐
│   Express.js API            │
│   (auth.js route)           │
└──────┬──────────────────────┘
       │
       │ 2. Find teacher in DB
       ▼
┌─────────────────────────────┐
│   MongoDB                   │
│   teachers collection       │
└──────┬──────────────────────┘
       │
       │ 3. Compare password
       ▼
┌─────────────────────────────┐
│   Bcrypt                    │
│   Password verification     │
└──────┬──────────────────────┘
       │
       │ 4. Valid? Generate JWT
       ▼
┌─────────────────────────────┐
│   JWT Token Created         │
│   Payload: {id, exp}        │
└──────┬──────────────────────┘
       │
       │ 5. Return token
       ▼
┌──────────────────────────────┐
│   Flutter                    │
│   Save to SharedPreferences  │
│   Set in all API calls       │
└──────────────────────────────┘
```

### Attendance Marking Flow

```
┌──────────────────────────┐
│   Swipe Attendance       │
│   Screen                 │
└────────────┬─────────────┘
             │
             │ 1. User swipes card
             │    (Right/Left/Down)
             ▼
┌──────────────────────────────┐
│   Gesture Handler            │
│   Calculate swipe direction  │
│   Determine status           │
└────────────┬─────────────────┘
             │
             │ 2. Status determined
             │    (PRESENT/ABSENT/LATE)
             ▼
┌──────────────────────────────┐
│   AttendanceProvider         │
│   Add to pending queue       │
│   Update local state         │
└────────────┬─────────────────┘
             │
             │ 3. Show next card
             │    Animate current
             ▼
┌──────────────────────────────┐
│   All Students Processed?    │
│   No → Show next card        │
│   Yes → Proceed to report    │
└────────────┬─────────────────┘
             │
             │ 4. User submits
             │    Batch mark API call
             ▼
┌──────────────────────────────┐
│   POST /attendance/batch-mark│
│   {class_id, date, data[]}   │
└────────────┬─────────────────┘
             │
             │ 5. Verify & save
             ▼
┌──────────────────────────────┐
│   MongoDB                    │
│   Insert/Update records      │
│   Update student stats       │
└────────────┬─────────────────┘
             │
             │ 6. Return success
             ▼
┌──────────────────────────────┐
│   Flutter                    │
│   Navigate to Report Screen  │
│   Display confirmation       │
└──────────────────────────────┘
```

---

## State Management Pattern

### Provider Pattern Usage

```
User Interface
     │
     ├─ LoginScreen
     │   └─ reads AuthProvider
     │       ├─ login()
     │       └─ token getter
     │
     ├─ DashboardScreen
     │   └─ reads ClassProvider
     │       ├─ fetchClasses()
     │       └─ classes getter
     │
     ├─ AttendanceScreen
     │   └─ reads AttendanceProvider
     │       ├─ markAttendance()
     │       ├─ pendingAttendance
     │       └─ batchMarkAttendance()
     │
     └─ AnalyticsScreen
         └─ reads AttendanceProvider
             ├─ fetchAnalytics()
             └─ analytics getter

Provider Dependencies:
ClassProvider depends on AuthProvider for token
AttendanceProvider depends on AuthProvider for token
```

---

## Gesture Recognition System

### Swipe Gesture Algorithm

```
GestureDetector.onPanUpdate()
│
├─ Record initial position
├─ Track drag offset (dx, dy)
└─ Update UI in real-time
    │
    ├─ Right > 50px → Show "Present" hint
    ├─ Left < -50px → Show "Absent" hint
    ├─ Down > 50px → Show "Late" hint
    └─ Up < -50px → Show "Details" hint

GestureDetector.onPanEnd()
│
└─ Calculate final offset
   │
   ├─ dx > 100px → PRESENT (Right swipe)
   ├─ dx < -100px → ABSENT (Left swipe)
   ├─ dy > 100px → LATE (Down swipe)
   ├─ dy < -100px → DETAILS (Up swipe)
   └─ else → Reset card position
```

---

## API Request/Response Pattern

### Standard Request
```json
{
  "Authorization": "Bearer eyJhbGc...",
  "Content-Type": "application/json",
  "body": {
    "student_id": "507f1f77bcf86cd799439020",
    "class_id": "507f1f77bcf86cd799439012",
    "status": "PRESENT",
    "date": "2024-02-23T00:00:00Z"
  }
}
```

### Standard Response
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {
    // Response payload
  }
}
```

### Error Response
```json
{
  "error": "Error message",
  "details": [
    // Error details if validation error
  ]
}
```

---

## Security Architecture

### Authentication
- JWT tokens with HS256 algorithm
- 7-day expiration by default
- Refresh token mechanism (future)
- Token stored in SharedPreferences

### Authorization
- Verified on every protected route
- Teacher can only access their classes
- Students belong to specific classes

### Data Protection
- Passwords hashed with bcrypt (10 rounds)
- CORS enabled for frontend domain only
- Input validation on all endpoints
- No sensitive data in logs

### Database Security
- Unique constraints on critical fields
- Indexed fields for query optimization
- Connection pooling
- No SQL injection (MongoDB native)

---

## Scalability Considerations

### Current Architecture (Single Server)
- Suitable for schools with < 1000 students
- Single MongoDB instance
- Express.js single process

### Future Scalability

1. **Horizontal Scaling**
   - Load balancer (nginx/HAProxy)
   - Multiple Express instances
   - PM2 for process management

2. **Database Scaling**
   - MongoDB replication (3-node cluster)
   - Database sharding by school_id
   - Read replicas for analytics

3. **Caching**
   - Redis for session storage
   - Cache frequently accessed classes
   - Cache student lists

4. **Message Queues**
   - RabbitMQ for async operations
   - PDF generation in background
   - Email notifications queue

5. **CDN**
   - Serve static assets globally
   - Image optimization
   - API response compression

---

## Performance Optimization

### Frontend
- Image caching (CachedNetworkImage)
- Lazy loading of student cards
- Local state management (no unnecessary rebuilds)
- Efficient gesture handling
- Offline support with SQLite

### Backend
- Database indexes on frequently queried fields
- Connection pooling
- Response compression
- API rate limiting
- Batch operations (batch-mark)

### Database
- Compound indexes for multi-field queries
- Aggregation pipeline for analytics
- Proper data types and validation
- TTL indexes for old records (future)

---

## Deployment Architecture

### Development
```
Local Machine
├─ Flutter app (emulator/device)
├─ Express server (localhost:5000)
└─ MongoDB (localhost:27017)
```

### Staging
```
Server
├─ Flutter app build (TestFlight/Play Store beta)
├─ Express on Port 5000
├─ MongoDB replica set
└─ Nginx reverse proxy
```

### Production
```
Cloud (AWS/Heroku/DigitalOcean)
├─ Flutter app (App Store/Play Store)
├─ Express cluster (3+ instances)
├─ MongoDB Atlas (managed service)
├─ CloudFront CDN
└─ CloudWatch monitoring
```

---

## Error Handling Strategy

```
Application Layer
├─ Network errors → Retry with exponential backoff
├─ Validation errors → Show user-friendly messages
├─ Authentication errors → Redirect to login
├─ Server errors → Show generic message + contact support
└─ Database errors → Log & alert admin

User Feedback
├─ Toast notifications (transient)
├─ Dialog boxes (persistent)
├─ Error screens (network down)
└─ Retry mechanisms (auto + manual)
```

---

## Testing Strategy (Future)

### Unit Tests
- Provider logic
- API service methods
- Database models

### Integration Tests
- Authentication flow
- Attendance marking flow
- Report generation

### E2E Tests
- Complete user journey
- Multiple user scenarios
- Edge cases

---

## Monitoring & Analytics

### Key Metrics
- API response times
- Error rates per endpoint
- Database query performance
- User authentication success rate
- Feature usage statistics

### Logging
- Structured logging (JSON)
- Log aggregation (ELK Stack future)
- Error tracking (Sentry)
- Performance monitoring (New Relic)

---

## Future Enhancements

1. **Biometric Authentication**
   - Face recognition for automatic marking
   - Fingerprint for teacher login

2. **Real-Time Sync**
   - WebSocket for live attendance updates
   - Real-time analytics dashboard

3. **Advanced Features**
   - PDF/Excel report generation
   - Email notifications
   - Bulk student import
   - Parent mobile app

4. **AI/ML Features**
   - Attendance prediction
   - Anomaly detection
   - Smart recommendations

5. **Mobile Optimization**
   - Native performance improvements
   - Offline database (SQLite)
   - Background sync

---

## Conclusion

This architecture provides:
- ✅ Scalability for multiple institutions
- ✅ Performance optimization for smooth UX
- ✅ Security for sensitive education data
- ✅ Maintainability with clean code structure
- ✅ Extensibility for future features

The system is production-ready and can handle schools with hundreds of students and classes efficiently.
