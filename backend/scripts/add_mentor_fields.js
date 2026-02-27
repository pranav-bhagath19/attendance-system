require('dotenv').config();
const { db } = require('../config/firebase');

const indianNames = [
    "Rajesh Kumar", "Suresh Reddy", "Priya Sharma", "Anil Verma",
    "Kavita Singh", "Mahesh Patel", "Sunita Devi", "Ravi Teja",
    "Lakshmi Narayana", "Pooja Gupta", "Amit Desai", "Neha Joshi",
    "Siddharth Rao", "Deepa Nair", "Vikram Menon"
];

const indianPrefixes = ["6", "7", "8", "9"];

function getRandomName() {
    return indianNames[Math.floor(Math.random() * indianNames.length)];
}

function getRandomPhone() {
    let phone = "+91";
    phone += indianPrefixes[Math.floor(Math.random() * indianPrefixes.length)];
    for (let i = 0; i < 9; i++) {
        phone += Math.floor(Math.random() * 10);
    }
    return phone;
}

async function runMigration() {
    console.log("Starting mentor fields migration...");
    try {
        const studentsRef = db.collection('students');
        const snapshot = await studentsRef.get();

        if (snapshot.empty) {
            console.log("No students found.");
            process.exit(0);
            return;
        }

        let updatedCount = 0;

        for (const doc of snapshot.docs) {
            const data = doc.data();
            let needsUpdate = false;
            const updates = {};

            if (!data.mentor_name || data.mentor_name.trim() === "") {
                updates.mentor_name = getRandomName();
                needsUpdate = true;
            }

            if (!data.mentor_phone || data.mentor_phone.trim() === "") {
                updates.mentor_phone = getRandomPhone();
                needsUpdate = true;
            }

            if (needsUpdate) {
                await doc.ref.update(updates);
                updatedCount++;
                console.log(`Updated student ${doc.id} with mentor: ${updates.mentor_name || data.mentor_name} (${updates.mentor_phone || data.mentor_phone})`);
            }
        }

        console.log(`\nMigration completed successfully! Total students updated: ${updatedCount}`);
    } catch (error) {
        console.error("Migration failed:", error);
    } finally {
        process.exit(0);
    }
}

runMigration();
