const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// ─────────────────────────────────────────────────────────────
//  Cloud Function: deleteAllStudents
//  Deletes all Firebase Auth accounts whose email ends with
//  @apsit.edu.in EXCEPT the caller's own account (the teacher).
//  Also deletes all documents in the 'students' collection.
// ─────────────────────────────────────────────────────────────
exports.deleteAllStudents = functions.https.onCall(async (data, context) => {
  // 1. Make sure the caller is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be logged in to perform this action.",
    );
  }

  const callerUid = context.auth.uid;
  const db = admin.firestore();
  const auth = admin.auth();

  let deletedAuth = 0;
  let deletedFirestore = 0;
  let skipped = 0;

  try {
    // ── STEP 1: Delete all Auth accounts with @apsit.edu.in email ──
    let pageToken = undefined;

    do {
      // List users in batches of 1000
      const listResult = await auth.listUsers(1000, pageToken);

      const uidsToDelete = [];

      for (const user of listResult.users) {
        // Skip the teacher (caller's own account)
        if (user.uid === callerUid) {
          skipped++;
          continue;
        }
        // Only delete @apsit.edu.in student accounts
        if (user.email && user.email.endsWith("@apsit.edu.in")) {
          uidsToDelete.push(user.uid);
        }
      }

      // Delete in batches of 1000 (Firebase limit)
      if (uidsToDelete.length > 0) {
        const deleteResult = await auth.deleteUsers(uidsToDelete);
        deletedAuth += deleteResult.successCount;
        if (deleteResult.failureCount > 0) {
          console.warn(
              `Failed to delete ${deleteResult.failureCount} auth accounts`,
          );
        }
      }

      pageToken = listResult.pageToken;
    } while (pageToken);

    // ── STEP 2: Delete all docs in 'students' collection ──
    const studentsRef = db.collection("students");
    const snapshot = await studentsRef.get();

    // Firestore batch delete (max 500 per batch)
    const batchSize = 500;
    let batch = db.batch();
    let batchCount = 0;

    for (const doc of snapshot.docs) {
      batch.delete(doc.ref);
      batchCount++;
      deletedFirestore++;

      if (batchCount === batchSize) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    return {
      success: true,
      message: `✅ Done! Deleted ${deletedAuth} Auth accounts and ${deletedFirestore} Firestore records. (${skipped} account(s) kept)`,
      deletedAuth,
      deletedFirestore,
    };
  } catch (error) {
    console.error("deleteAllStudents error:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});
