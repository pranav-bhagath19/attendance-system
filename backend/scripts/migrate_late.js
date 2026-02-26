const { db } = require('../config/firebase');

async function migrateLateStatus() {
    console.log('Starting migration to replace LATE with ABSENT in attendance records...');
    const snapshot = await db.collection('attendance').get();

    let modifiedCount = 0;

    for (const doc of snapshot.docs) {
        const data = doc.data();
        const records = data.records || [];
        let isModified = false;

        // Convert LATE to ABSENT
        const updatedRecords = records.map(record => {
            if (record.status === 'LATE') {
                record.status = 'ABSENT';
                isModified = true;
            }
            return record;
        });

        if (isModified) {
            console.log(`Updating document ID: ${doc.id}`);
            await db.collection('attendance').doc(doc.id).update({
                records: updatedRecords
            });
            modifiedCount++;
        }
    }

    console.log(`Migration completed successfully! Updated ${modifiedCount} documents.`);
    process.exit(0);
}

migrateLateStatus().catch(console.error);
