const { db } = require('../config/firebase');

async function migrateWithoutAuth() {
    console.log("Migrating Classes and Students...");

    const teachersSnapshot = await db.collection('teachers').get();

    // Find duplicate emails. The ones with longer UIDs are usually Auth UIDs,
    // whereas the ones from seed script might be shorter standard Firestore auto-ids.
    const emailToUid = {};
    for (const doc of teachersSnapshot.docs) {
        if (doc.id.length > 20) {
            // Firebase Auth UIDs are typically 28 chars
            emailToUid[doc.data().email] = doc.id;
        }
    }

    // Let's print out what we found
    console.log("Found UIDs for mapping:", emailToUid);

    const classesSnapshot = await db.collection('classes').get();
    const classPromises = [];

    for (const doc of classesSnapshot.docs) {
        const data = doc.data();
        const oldTeacherId = data.teacher_id;

        // we look up the teacher's email from the old teachers document
        const oldTeacherDoc = await db.collection('teachers').doc(oldTeacherId).get();
        if (oldTeacherDoc.exists) {
            const email = oldTeacherDoc.data().email;
            const authUid = emailToUid[email];

            if (authUid) {
                console.log(`Updating Class ${doc.id} - replacing old teacher_id: ${oldTeacherId} with new teacherId: ${authUid}`);
                classPromises.push(db.collection('classes').doc(doc.id).update({
                    teacherId: authUid
                }));
            } else {
                console.log(`Warning: no Auth UID found for email ${email} - just setting teacherId = teacher_id`);
                classPromises.push(db.collection('classes').doc(doc.id).update({
                    teacherId: oldTeacherId
                }));
            }
        } else {
            classPromises.push(db.collection('classes').doc(doc.id).update({
                teacherId: oldTeacherId
            }));
        }
    }
    await Promise.all(classPromises);

    // 4. Migrate Students to Subcollections
    const studentsSnapshot = await db.collection('students').get();
    console.log(`Migrating ${studentsSnapshot.docs.length} Students to subcollections...`);
    const studentPromises = [];
    studentsSnapshot.docs.forEach(doc => {
        const data = doc.data();
        const classId = data.class_id;
        if (classId) {
            studentPromises.push(
                db.collection('classes').doc(classId)
                    .collection('students').doc(doc.id)
                    .set(data)
            );
        }
    });
    await Promise.all(studentPromises);

    console.log("Migration Completed!");
}

migrateWithoutAuth().catch(console.error).finally(() => process.exit(0));
