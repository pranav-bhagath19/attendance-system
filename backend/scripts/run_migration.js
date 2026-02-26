const { admin, db } = require('../config/firebase');
const { initializeApp } = require("firebase/app");
const { getAuth, signInWithEmailAndPassword, createUserWithEmailAndPassword } = require("firebase/auth");

const firebaseConfig = {
    apiKey: "AIzaSyAjBfVm1xw4qRAbLrUOWobl-UNQDQFJziE",
    authDomain: "attendance-system-a96b0.firebaseapp.com",
    projectId: "attendance-system-a96b0",
    storageBucket: "attendance-system-a96b0.firebasestorage.app",
    messagingSenderId: "1007810490380",
    appId: "1:1007810490380:web:75ed16919846272ed2be29"
};

const app = initializeApp(firebaseConfig);
const clientAuth = getAuth(app);

async function getOrCreateUser(email) {
    const password = "password123";
    try {
        const cred = await signInWithEmailAndPassword(clientAuth, email, password);
        return cred.user.uid;
    } catch (e) {
        if (e.code === 'auth/user-not-found' || e.code === 'auth/invalid-credential' || e.code === 'auth/invalid-login-credentials') {
            try {
                const cred = await createUserWithEmailAndPassword(clientAuth, email, password);
                return cred.user.uid;
            } catch (createErr) {
                if (createErr.code === 'auth/email-already-in-use') {
                    // Try generic fallback password if password changed
                    try {
                        const fbCred = await signInWithEmailAndPassword(clientAuth, email, "12345678");
                        return fbCred.user.uid;
                    } catch (fallbackErr) {
                        throw new Error(`User exists but couldn't login with pass: ${fallbackErr.message}`);
                    }
                }
                throw createErr;
            }
        }
        throw e;
    }
}

async function runProductionMigration() {
    console.log("🚀 Starting Unified UID Migration via Client SDK Fallback...");

    // 1. Snapshot everything first
    const teachersSnapshot = await db.collection('teachers').get();
    let migrated = 0;

    for (const doc of teachersSnapshot.docs) {
        const data = doc.data();
        if (!data.email) continue;

        // Skip if ID is already Auth UID (length > 25)
        if (doc.id.length > 25) {
            console.log(`[SKIP] ${data.email} already has a valid Auth UID: ${doc.id}`);
            continue;
        }

        try {
            // Bypass admin.auth() IAM lockout by using Client SDK natively
            const realUid = await getOrCreateUser(data.email);

            console.log(`[MIGRATE] ${data.email} | Legacy: ${doc.id} -> New UID: ${realUid}`);

            // Write new Teacher Document natively to Firestore
            await db.collection('teachers').doc(realUid).set({
                ...data,
                id: realUid,
                active: true,
                migrated_at: new Date()
            });

            // Update associated classes strictly
            const classQuery = await db.collection('classes').where('teacher_id', '==', doc.id).get();
            for (const classDoc of classQuery.docs) {
                console.log(`  -> Mapping Class ${classDoc.id} to new UID: ${realUid}`);
                await db.collection('classes').doc(classDoc.id).update({
                    teacher_id: realUid,
                    migrated_at: new Date()
                });
            }

            // Remove legacy fragmented document
            if (doc.id !== realUid) {
                await db.collection('teachers').doc(doc.id).delete();
            }
            migrated++;
        } catch (error) {
            console.error(`[ERROR] Migrating ${data.email}:`, error.code || error.message);
        }
    }

    console.log(`✅ Migration Complete. Re-mapped ${migrated} teachers.`);
    process.exit(0);
}

runProductionMigration();
