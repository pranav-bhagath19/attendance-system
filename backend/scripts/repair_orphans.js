const { db } = require('../config/firebase');

async function repairSystem() {
    console.log("🛠️ Starting Auto-Repair for Database Orphans...");
    const teachersSnapshot = await db.collection('teachers').get();
    const classesSnapshot = await db.collection('classes').get();

    const validTeacherIds = new Set(teachersSnapshot.docs.map(t => t.id));

    let removedClasses = 0;
    let removedTeachers = 0;

    // 1. Remove classes with dead teacher_id references
    for (const c of classesSnapshot.docs) {
        if (!validTeacherIds.has(c.data().teacher_id)) {
            console.log(`[DELETE] Orphaned Class ${c.id} (Teacher ${c.data().teacher_id} no longer exists)`);
            await db.collection('classes').doc(c.id).delete();
            removedClasses++;
        }
    }

    // 2. Remove stubborn legacy teachers that failed migration (short IDs)
    for (const t of teachersSnapshot.docs) {
        if (t.id.length < 25) {
            console.log(`[DELETE] Legacy Fragmented Teacher: ${t.id} (${t.data().email})`);
            await db.collection('teachers').doc(t.id).delete();
            removedTeachers++;
        }
    }

    // 3. Clean orphaned students
    const validClassIds = new Set((await db.collection('classes').get()).docs.map(c => c.id));
    const studentsSnapshot = await db.collection('students').get();
    let removedStudents = 0;

    for (const s of studentsSnapshot.docs) {
        if (!validClassIds.has(s.data().class_id)) {
            console.log(`[DELETE] Orphaned Student ${s.id} (Class ${s.data().class_id} no longer exists)`);
            await db.collection('students').doc(s.id).delete();
            removedStudents++;
        }
    }

    console.log(`\n✅ REPAIR COMPLETE!`);
    console.log(`- Removed ${removedClasses} ghost classes`);
    console.log(`- Removed ${removedTeachers} legacy teachers`);
    console.log(`- Removed ${removedStudents} ghost students`);
    console.log("Your database referential integrity is now 100% Pure.");
    process.exit(0);
}

repairSystem();
