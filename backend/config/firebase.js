/**
 * Firebase Admin Configuration
 * Initializes Firebase Admin SDK with Firestore database
 */

const admin = require('firebase-admin');
const dotenv = require('dotenv');

dotenv.config();

// Initialize Firebase Admin
const serviceAccount = {
  type: 'service_account',
  project_id: process.env.FIREBASE_PROJECT_ID,
  private_key_id: 'a25c2bfc84be22ab0aec1e19050078c7e51bf5e0',
  private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
  client_email: process.env.FIREBASE_CLIENT_EMAIL,
  client_id: '117626405863294148457',
  auth_uri: 'https://accounts.google.com/o/oauth2/auth',
  token_uri: 'https://oauth2.googleapis.com/token',
  auth_provider_x509_cert_url: 'https://www.googleapis.com/oauth2/v1/certs',
  client_x509_cert_url: 'https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40attendance-system-a96b0.iam.gserviceaccount.com',
  universe_domain: 'googleapis.com',
};

try {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: process.env.FIREBASE_PROJECT_ID,
  });

  console.log('✓ Firebase Admin SDK initialized successfully');
} catch (error) {
  console.error('✗ Firebase initialization failed:', error.message);
  process.exit(1);
}

// Get Firestore instance
const db = admin.firestore();

// Set default settings for Firestore
db.settings({
  ignoreUndefinedProperties: true,
});

module.exports = {
  admin,
  db,
  auth: admin.auth(),
};
