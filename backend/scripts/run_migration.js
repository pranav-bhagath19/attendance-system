const { admin, db } = require('../config/firebase');

async function runProductionMigration() {
    console.log("🚀 Starting Unified UID Migration...");
    const teachersSnapshot = await db.collection('teachers').get();
    let migrated = 0;

    for (const doc of teachersSnapshot.docs) {
        const data = doc.data();
        if (!data.email) continue;

        // Skip if ID is already a 28-char Auth UID
        if (doc.id.length > 25) {
            console.log(`[SKIP] ${data.email} already uses Auth UID: ${doc.id}`);
            continue;
        }

        try {
            // Find true Firebase Auth User
            const userRecord = await admin.auth().getUserByEmail(data.email);
            const realUid = userRecord.uid;

            console.log(`[MIGRATE] ${data.email} | Legacy: ${doc.id} -> UID: ${realUid}`);

            // Write new Teacher Document
            await db.collection('teachers').doc(realUid).set({
                ...data,
                id: realUid,
                active: true,
                migrated_at: new Date()
            });

            // Update associated classes
            const classQuery = await db.collection('classes').where('teacher_id', '==', doc.id).get();
            for (const classDoc of classQuery.docs) {
                console.log(`  -> Mapping Class ${classDoc.id} to UID: ${realUid}`);
                await db.collection('classes').doc(classDoc.id).update({ teacher_id: realUid });
            }

            // Remove legacy document
            await db.collection('teachers').doc(doc.id).delete();
            migrated++;
        } catch (error) {
            console.error(`[ERROR] Migrating ${data.email}:`, error.code || error.message);
        }
    }

    console.log(`✅ Migration Complete. Re-mapped ${migrated} teachers.`);
    process.exit(0);
}

runProductionMigration();
