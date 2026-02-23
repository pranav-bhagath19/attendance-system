# API Documentation

## Base URL
```
http://localhost:5000/api
```

## Authentication

All requests (except login) require JWT token in Authorization header:
```
Authorization: Bearer {token}
```

---

## Authentication Endpoints

### POST /auth/login

Login with email and password.

**Request:**
```json
{
  "email": "rajesh@school.edu",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "teacher": {
    "id": "507f1f77bcf86cd799439011",
    "name": "Dr. Rajesh Kumar",
    "email": "rajesh@school.edu",
    "phone": "+91 9876543210",
    "department": "Computer Science",
    "assigned_classes": ["507f1f77bcf86cd799439012", "507f1f77bcf86cd799439013"]
  }
}
```

**Error (401):**
```json
{
  "error": "Invalid email or password"
}
```

---

### POST /auth/logout

Logout current teacher.

**Request:** No body

**Response (200):**
```json
{
  "success": true,
  "message": "Logout successful"
}
```

---

### GET /auth/me

Get current authenticated teacher profile.

**Request:** No body

**Response (200):**
```json
{
  "success": true,
  "teacher": {
    "id": "507f1f77bcf86cd799439011",
    "name": "Dr. Rajesh Kumar",
    "email": "rajesh@school.edu",
    "phone": "+91 9876543210",
    "department": "Computer Science",
    "assigned_classes": [...]
  }
}
```

---

## Teacher Endpoints

### GET /teacher/classes

Get all classes assigned to teacher.

**Response (200):**
```json
{
  "success": true,
  "count": 2,
  "classes": [
    {
      "id": "507f1f77bcf86cd799439012",
      "name": "Class 10-A",
      "subject": "Computer Science",
      "section": "A",
      "code": "CS10A",
      "room_number": "101",
      "student_count": 15,
      "total_sessions": 10,
      "last_attendance_date": "2024-02-23T10:30:00Z",
      "is_active": true
    }
  ]
}
```

---

### GET /teacher/class/:classId

Get specific class details with students.

**Response (200):**
```json
{
  "success": true,
  "class": {
    "id": "507f1f77bcf86cd799439012",
    "name": "Class 10-A",
    "subject": "Computer Science",
    "section": "A",
    "code": "CS10A",
    "students": [
      {
        "id": "507f1f77bcf86cd799439020",
        "name": "Arjun Sharma",
        "roll_no": "001",
        "email": "arjun@student.edu",
        "photo": "https://api.example.com/photos/001.jpg",
        "attendance_percentage": 85,
        "stats": {
          "total_classes": 10,
          "present_count": 8,
          "absent_count": 1,
          "late_count": 1
        }
      }
    ],
    "total_students": 15
  }
}
```

---

### GET /teacher/class/:classId/students

Get students for swipe attendance (optimized for card display).

**Response (200):**
```json
{
  "success": true,
  "count": 15,
  "students": [
    {
      "id": "507f1f77bcf86cd799439020",
      "name": "Arjun Sharma",
      "roll_no": "001",
      "photo": "https://api.example.com/photos/001.jpg",
      "email": "arjun@student.edu",
      "phone": "+91 9000000000",
      "attendance_percentage": 85,
      "stats": {
        "total_classes": 10,
        "present_count": 8,
        "absent_count": 1,
        "late_count": 1
      }
    }
  ]
}
```

---

### GET /teacher/dashboard

Get teacher dashboard summary.

**Response (200):**
```json
{
  "success": true,
  "dashboard": {
    "total_classes": 2,
    "total_students": 30,
    "classes": [
      {
        "id": "507f1f77bcf86cd799439012",
        "name": "Class 10-A",
        "subject": "Computer Science"
      }
    ]
  }
}
```

---

## Attendance Endpoints

### POST /attendance/mark

Mark attendance for single student.

**Request:**
```json
{
  "student_id": "507f1f77bcf86cd799439020",
  "class_id": "507f1f77bcf86cd799439012",
  "status": "PRESENT",
  "date": "2024-02-23T00:00:00Z",
  "notes": "Optional notes"
}
```

**Status Values:** PRESENT, ABSENT, LATE, EXCUSED

**Response (201):**
```json
{
  "success": true,
  "message": "Attendance marked successfully",
  "attendance": {
    "student_id": "507f1f77bcf86cd799439020",
    "class_id": "507f1f77bcf86cd799439012",
    "status": "PRESENT",
    "date": "2024-02-23T00:00:00Z",
    "marked_at": "2024-02-23T10:30:00Z"
  }
}
```

---

### POST /attendance/batch-mark

Mark attendance for multiple students at once.

**Request:**
```json
{
  "class_id": "507f1f77bcf86cd799439012",
  "date": "2024-02-23T00:00:00Z",
  "attendance_data": [
    {
      "student_id": "507f1f77bcf86cd799439020",
      "status": "PRESENT",
      "notes": null
    },
    {
      "student_id": "507f1f77bcf86cd799439021",
      "status": "ABSENT",
      "notes": "Medical emergency"
    }
  ]
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Batch attendance marked successfully",
  "marked_count": 15
}
```

---

### GET /attendance/class/:classId

Get attendance report for a class on specific date.

**Query Parameters:**
- `date` (required): YYYY-MM-DD format

**Example:** `/api/attendance/class/507f1f77bcf86cd799439012?date=2024-02-23`

**Response (200):**
```json
{
  "success": true,
  "date": "2024-02-23",
  "class_name": "Class 10-A",
  "total_students": 15,
  "attendance": [
    {
      "id": "507f1f77bcf86cd799439030",
      "student_id": "507f1f77bcf86cd799439020",
      "student_name": "Arjun Sharma",
      "roll_no": "001",
      "status": "PRESENT",
      "marked_at": "2024-02-23T10:30:00Z",
      "notes": null
    }
  ]
}
```

---

### PUT /attendance/:attendanceId

Update existing attendance record.

**Request:**
```json
{
  "status": "LATE",
  "notes": "Late due to traffic"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Attendance updated successfully",
  "attendance": {
    "_id": "507f1f77bcf86cd799439030",
    "student_id": "507f1f77bcf86cd799439020",
    "class_id": "507f1f77bcf86cd799439012",
    "status": "LATE",
    "date": "2024-02-23T00:00:00Z",
    "notes": "Late due to traffic",
    "edited_at": "2024-02-23T15:45:00Z"
  }
}
```

---

### GET /attendance/student/:studentId

Get attendance history for specific student.

**Response (200):**
```json
{
  "success": true,
  "student": {
    "id": "507f1f77bcf86cd799439020",
    "name": "Arjun Sharma",
    "roll_no": "001",
    "email": "arjun@student.edu",
    "phone": "+91 9000000000"
  },
  "attendance_history": [
    {
      "id": "507f1f77bcf86cd799439030",
      "date": "2024-02-23T00:00:00Z",
      "status": "PRESENT",
      "marked_at": "2024-02-23T10:30:00Z",
      "notes": null
    }
  ]
}
```

---

### GET /attendance/analytics/:classId

Get attendance analytics for a class.

**Response (200):**
```json
{
  "success": true,
  "class_name": "Class 10-A",
  "analytics": [
    {
      "student_id": "507f1f77bcf86cd799439020",
      "student_name": "Arjun Sharma",
      "roll_no": "001",
      "total_classes": 10,
      "present": 8,
      "absent": 1,
      "late": 1,
      "attendance_percentage": 85,
      "status": "GOOD"
    }
  ]
}
```

---

## Error Handling

### Common Error Responses

**401 - Unauthorized**
```json
{
  "error": "No authentication token provided"
}
```

**403 - Forbidden**
```json
{
  "error": "Unauthorized to access this resource"
}
```

**404 - Not Found**
```json
{
  "error": "Class not found"
}
```

**400 - Bad Request**
```json
{
  "error": "Validation failed",
  "details": [
    {
      "msg": "Invalid email",
      "param": "email",
      "location": "body"
    }
  ]
}
```

**500 - Server Error**
```json
{
  "error": "Internal server error"
}
```

---

## Rate Limiting

- **Window:** 15 minutes
- **Max Requests:** 100 per window
- **Headers:** X-RateLimit-Limit, X-RateLimit-Remaining

---

## Pagination (Future)

Once implemented, list endpoints will support:
- `?page=1` - Page number
- `?limit=20` - Items per page
- `?sort=name` - Sort field

---

## Data Types

### Status Enum
```
PRESENT  - Student attended the class
ABSENT   - Student did not attend
LATE     - Student attended but late
EXCUSED  - Student was excused
```

### Date Format
All dates use ISO 8601 format: `2024-02-23T10:30:00Z`

---

## Response Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 500 | Server Error |

---

## Headers

All requests should include:
```
Content-Type: application/json
Authorization: Bearer {token}
```

---

## Examples Using cURL

### Login
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"rajesh@school.edu","password":"password123"}'
```

### Get Classes
```bash
curl -X GET http://localhost:5000/api/teacher/classes \
  -H "Authorization: Bearer {token}"
```

### Mark Attendance
```bash
curl -X POST http://localhost:5000/api/attendance/mark \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{
    "student_id":"507f1f77bcf86cd799439020",
    "class_id":"507f1f77bcf86cd799439012",
    "status":"PRESENT",
    "date":"2024-02-23T00:00:00Z"
  }'
```

---

## Websocket Events (Future)

Planned for real-time attendance updates:
- `attendance:marked` - New attendance marked
- `attendance:updated` - Attendance modified
- `sync:required` - Sync needed

---

Last Updated: February 2024
