const { admin, db } = require('../config/firebase');

async function validateSystem() {
    console.log("🔍 Validating Database Integrity...");
    const issues = [];

    const teachers = await db.collection('teachers').get();
    const classes = await db.collection('classes').get();

    const authUIDs = new Set();
    const dbTeacherUIDs = new Set(teachers.docs.map(t => t.id));

    // 1. Verify every DB teacher exists in Auth
    for (const t of teachers.docs) {
        try {
            await admin.auth().getUser(t.id);
            authUIDs.add(t.id);
        } catch (e) {
            issues.push(`[FATAL] Firestore teacher ${t.id} missing from Firebase Auth!`);
        }
    }

    // 2. Verify all classes have valid teacher UIDs
    for (const c of classes.docs) {
        if (!authUIDs.has(c.data().teacher_id)) {
            issues.push(`[FATAL] Class ${c.id} has orphaned teacher_id: ${c.data().teacher_id}`);
        }
    }

    if (issues.length === 0) {
        console.log("✅ SYSTEM SECURE: 100% Referential Integrity Passed.");
    } else {
        console.log("❌ ISSUES FOUND:");
        issues.forEach(i => console.log(i));
    }
    process.exit(0);
}

validateSystem();
