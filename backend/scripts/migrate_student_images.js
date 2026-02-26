const { db } = require('../config/firebase');

async function migrateStudentImages() {
    console.log('Starting migration to ensure all students have an image_url field...');

    try {
        const studentsSnapshot = await db.collection('students').get();

        let updatedCount = 0;

        for (const doc of studentsSnapshot.docs) {
            const data = doc.data();

            // Check if image_url exists. Note that data.photo could be used as fallback temporarily.
            if (data.image_url === undefined) {

                let initialImageUrl = "";

                // If a valid HTTP url exists in photo, migrate it over safely
                if (data.photo && data.photo.startsWith("http")) {
                    initialImageUrl = data.photo;
                }

                console.log(`Updating student ID: ${doc.id}`);
                await doc.ref.update({
                    image_url: initialImageUrl,
                });

                updatedCount++;
            }
        }

        console.log(`Migration completed successfully! Updated ${updatedCount} students.`);
        process.exit(0);
    } catch (error) {
        console.error('Migration failed:', error);
        process.exit(1);
    }
}

migrateStudentImages();
