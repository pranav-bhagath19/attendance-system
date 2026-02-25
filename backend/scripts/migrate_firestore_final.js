const https = require('https');
const { db } = require('../config/firebase');

const API_KEY = "AIzaSyAjBfVm1xw4qRAbLrUOWobl-UNQDQFJziE"; // Extracted from flutter web firebase_options

async function signInUser(email, password) {
    return new Promise((resolve, reject) => {
        const data = JSON.stringify({
            email,
            password,
            returnSecureToken: true
        });

        const options = {
            hostname: 'identitytoolkit.googleapis.com',
            path: `/v1/accounts:signInWithPassword?key=${API_KEY}`,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': data.length
            }
        };

        const req = https.request(options, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => {
                if (res.statusCode === 200) {
                    resolve(JSON.parse(body));
                } else {
                    reject(new Error(body));
                }
            });
        });

        req.on('error', reject);
        req.write(data);
        req.end();
    });
}

async function runMigration() {
    try {
        console.log("Authenticating rajesh@school.edu...");
        const res1 = await signInUser('rajesh@school.edu', 'password123');
        const rajeshUid = res1.localId;
        console.log(`Rajesh UID: ${rajeshUid}`);

        console.log("Authenticating priya@school.edu...");
        const res2 = await signInUser('priya@school.edu', 'password123');
        const priyaUid = res2.localId;
        console.log(`Priya UID: ${priyaUid}`);

        console.log("Authenticating amit@school.edu...");
        const res3 = await signInUser('amit@school.edu', 'password123');
        const amitUid = res3.localId;
        console.log(`Amit UID: ${amitUid}`);

        const authMap = {
            'rajesh@school.edu': rajeshUid,
            'priya@school.edu': priyaUid,
            'amit@school.edu': amitUid
        };

        // 1. Process Teachers
        const teachersSnapshot = await db.collection('teachers').get();
        const oldTeacherIdToNewUid = {};

        for (const doc of teachersSnapshot.docs) {
            const data = doc.data();
            if (data.email && authMap[data.email]) {
                const newUid = authMap[data.email];
                // Don't modify if it's already using the auth UID
                if (doc.id !== newUid) {
                    console.log(`Migrating Teacher ${doc.id} -> ${newUid}`);
                    oldTeacherIdToNewUid[doc.id] = newUid;
                    // Copy to new document
                    await db.collection('teachers').doc(newUid).set({
                        ...data,
                        id: newUid // overwrite id field if it exists
                    });
                    // Optional: delete old doc. Leaving it for safety but let's delete to avoid dupes
                    await db.collection('teachers').doc(doc.id).delete();
                } else {
                    oldTeacherIdToNewUid[doc.id] = newUid; // already correct
                }
            }
        }

        // 2. Process Classes
        const classesSnapshot = await db.collection('classes').get();
        for (const doc of classesSnapshot.docs) {
            const data = doc.data();
            const oldTeacherId = data.teacher_id || data.teacherId;
            const newUid = oldTeacherIdToNewUid[oldTeacherId] || authMap['rajesh@school.edu'];

            console.log(`Updating Class ${doc.id} - teacher_id -> ${newUid}`);
            await db.collection('classes').doc(doc.id).update({
                teacher_id: newUid,
                teacherId: newUid // Add both to be super safe
            });
        }

        // 3. Optional: Delete teacherID from students if there's any?
        // Let's verify student structures:
        const studentSnapshot = await db.collection('students').limit(1).get();
        if (!studentSnapshot.empty) {
            console.log(`Sample Student Data: ${JSON.stringify(studentSnapshot.docs[0].data())}`);
        }

        console.log("Migration complete!");

    } catch (e) {
        require('fs').writeFileSync('err.json', e.message || e);
        console.error("Migration failed, see err.json");
    }
}

runMigration().catch(console.error).finally(() => process.exit(0));
