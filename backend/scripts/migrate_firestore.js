const { db, auth } = require('../config/firebase');

async function migrate() {
    console.log("Starting Migration...");

    // 1. Get all Auth users dynamically by email matching
    const listUsersResult = await auth.listUsers(1000);
    const authUsers = listUsersResult.users;
    const emailToUid = {};
    authUsers.forEach(u => emailToUid[u.email.toLowerCase()] = u.uid);

    // 2. Read old teachers and create mappings
    const teachersSnapshot = await db.collection('teachers').get();
    const oldIdToUid = {};

    for (const doc of teachersSnapshot.docs) {
        const data = doc.data();
        if (!data.email) continue;

        const email = data.email.toLowerCase();
        let uid = emailToUid[email];

        // Create new user if not exists
        if (!uid) {
            console.log(`Auth user for ${email} not found. Creating it...`);
            try {
                const newAuthUser = await auth.createUser({
                    email: data.email,
                    password: 'password123',
                    displayName: data.name
                });
                uid = newAuthUser.uid;
                emailToUid[email] = uid;
            } catch (err) {
                console.error(`Failed to create Auth User for ${email}`, err);
            }
        }

        if (uid) {
            oldIdToUid[doc.id] = uid;
            // Copy to new Teachers structure expected by auth_provider.dart
            console.log(`Migrating Teacher: ${doc.id} -> ${uid}`);
            await db.collection('teachers').doc(uid).set({
                ...data,
                id: uid
            });
        }
    }

    // 3. Migrate Classes
    const classesSnapshot = await db.collection('classes').get();
    const classUpdates = [];
    classesSnapshot.docs.forEach(doc => {
        const data = doc.data();
        const oldTeacherId = data.teacher_id;
        const newUid = oldIdToUid[oldTeacherId] || oldTeacherId;

        console.log(`Updating Class ${doc.id}... Setting teacherId to ${newUid}`);
        classUpdates.push(doc.ref.update({
            teacherId: newUid,
            teacher_id: admin.firestore.FieldValue.delete() // Optional: remove old field
        }).catch(e => doc.ref.update({ teacherId: newUid })));
    });
    await Promise.all(classUpdates);

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

const admin = require('firebase-admin');
migrate().catch(console.error).finally(() => process.exit(0));
