const { initializeApp } = require("firebase/app");
const { getAuth, signInWithEmailAndPassword, createUserWithEmailAndPassword } = require("firebase/auth");
const { db } = require('../config/firebase'); // using admin sdk for writes

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

async function authUser(email, password) {
    try {
        const userCredential = await signInWithEmailAndPassword(clientAuth, email, password);
        return userCredential.user;
    } catch (e) {
        if (e.code === 'auth/user-not-found' || e.code === 'auth/invalid-credential' || e.code === 'auth/invalid-login-credentials') {
            console.log(`User ${email} not found or invalid credential. Creating...`);
            try {
                const userCredential = await createUserWithEmailAndPassword(clientAuth, email, password);
                return userCredential.user;
            } catch (createErr) {
                console.error(`Error creating ${email}:`, createErr.message || createErr);
                return null;
            }
        }
        console.error(`Error signing in ${email}:`, e.message || e);
        return null;
    }
}

async function run() {
    const defaultPassword = 'password123';
    const emailToUid = {};

    // For all legacy teachers in DB, either authenticate or create their firebase auth
    const teachersSnapshot = await db.collection('teachers').get();
    const oldTeacherIdToNewUid = {};

    for (const doc of teachersSnapshot.docs) {
        const data = doc.data();
        if (data.email) {
            console.log(`Processing teacher: ${data.email} (DocID: ${doc.id})`);

            // Skip if looks like a Firebase Auth UID already
            if (doc.id.length > 25) {
                console.log(`Skipping - already looks like Auth UID: ${doc.id}`);
                continue;
            }

            const user = await authUser(data.email, defaultPassword);
            if (user) {
                emailToUid[data.email] = user.uid;
                oldTeacherIdToNewUid[doc.id] = user.uid;

                // Sync their new UID to FireStore!
                await db.collection('teachers').doc(user.uid).set({
                    ...data,
                    id: user.uid,
                    password: "" // Blank out legacy password hash
                });

                // Delete the old one
                console.log(`Deployed new Teacher profile for ${user.uid} (deleted old ${doc.id})`);
                await db.collection('teachers').doc(doc.id).delete();
            }
        }
    }

    // Process classes: map old assigned teacher to new Firebase Auth UID
    const classesSnapshot = await db.collection('classes').get();
    for (const doc of classesSnapshot.docs) {
        const data = doc.data();
        let newTeacherId = data.teacher_id;

        // If it was mapped previously
        if (oldTeacherIdToNewUid[data.teacher_id]) {
            newTeacherId = oldTeacherIdToNewUid[data.teacher_id];
        }

        console.log(`Updating class ${doc.id}: teacher_id -> ${newTeacherId}`);
        await db.collection('classes').doc(doc.id).update({
            teacher_id: newTeacherId,
            teacherId: newTeacherId // For redundant compatibility
        });
    }

    console.log("Migration finished.");
    process.exit(0);
}

run();
