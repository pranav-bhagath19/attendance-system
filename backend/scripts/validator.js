const { db } = require('../config/firebase');

async function validateSystem() {
    console.log("🔍 Validating Database Referential Integrity...");
    const issues = [];

    const teachers = await db.collection('teachers').get();
    const classes = await db.collection('classes').get();

    // The single source of truth for relationships is the modern teacher documents
    const dbTeacherUIDs = new Set(teachers.docs.map(t => t.id));

    // 1. Verify all new teacher UIDs meet Firebase standard lengths
    for (const t of teachers.docs) {
        if (t.id.length < 25) {
            issues.push(`[FATAL] Teacher ${t.id} looks like legacy ID! Has not run migration.`);
        }
    }

    // 2. Verify all classes have valid referential teacher UIDs mappings strictly
    for (const c of classes.docs) {
        if (!dbTeacherUIDs.has(c.data().teacher_id)) {
            issues.push(`[FATAL] Class ${c.id} has orphaned backward compatibility teacher_id: ${c.data().teacher_id}`);
        }
    }

    // 3. Verify downstream integrity securely over students tracking
    const students = await db.collection('students').get();
    const classUids = new Set(classes.docs.map(c => c.id));
    for (const s of students.docs) {
        if (!classUids.has(s.data().class_id)) {
            issues.push(`[WARNING] Student ${s.id} mapped to non-existent class_id: ${s.data().class_id}`);
        }
    }

    if (issues.length === 0) {
        console.log("✅ SYSTEM SECURE: 100% Referential Integrity bindings passed verification.");
    } else {
        console.log("❌ ISSUES FOUND:");
        issues.forEach(i => console.log(i));
    }
    process.exit(0);
}

validateSystem();
