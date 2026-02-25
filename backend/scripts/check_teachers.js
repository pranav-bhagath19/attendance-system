const { db } = require('../config/firebase');

async function checkTeachers() {
    const teachersSnapshot = await db.collection('teachers').get();
    teachersSnapshot.docs.forEach(doc => {
        console.log(`Teacher Doc ID: ${doc.id} (Length: ${doc.id.length}) - Email: ${doc.data().email}`);
    });
}
checkTeachers().catch(console.error).finally(() => process.exit(0));
