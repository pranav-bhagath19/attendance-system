const { db, auth } = require('../config/firebase');

async function analyze() {
    console.log("\n----- FIRESTORE TEACHERS -----");
    const teachersSnapshot = await db.collection('teachers').get();
    teachersSnapshot.docs.forEach(doc => {
        console.log(`Teacher Doc ID: ${doc.id} - Email: ${doc.data().email}`);
    });

    console.log("\n----- FIRESTORE CLASSES -----");
    const classesSnapshot = await db.collection('classes').get();
    classesSnapshot.docs.forEach(doc => {
        console.log(`Class Doc ID: ${doc.id} - Name: ${doc.data().name} - teacher_id: ${doc.data().teacher_id} - teacherId: ${doc.data().teacherId}`);
    });

    console.log("\n----- FIRESTORE STUDENTS (Top-level) -----");
    const studentsSnapshot = await db.collection('students').limit(3).get();
    studentsSnapshot.docs.forEach(doc => {
        console.log(`Student Doc ID: ${doc.id} - Name: ${doc.data().name} - class_id: ${doc.data().class_id}`);
    });

    if (classesSnapshot.docs.length > 0) {
        console.log(`\n----- FIRESTORE STUDENTS (Sub-collection under first class) -----`);
        const subStudentsSnapshot = await db.collection('classes').doc(classesSnapshot.docs[0].id).collection('students').get();
        console.log(`Found ${subStudentsSnapshot.docs.length} students in classes/${classesSnapshot.docs[0].id}/students`);
    }
}

analyze().catch(console.error).finally(() => process.exit(0));
