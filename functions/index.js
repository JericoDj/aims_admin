const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// 1️⃣ **Set a User as an Admin (Now HTTP POST)**
exports.setAdmin = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).json({
      success: false,
      message: "Method Not Allowed",
    });
  }

  const { uid } = req.body;

  if (!uid) {
    return res.status(400).json({
      success: false,
      message: "Missing user ID.",
    });
  }

  try {
    await admin.auth().setCustomUserClaims(uid, {admin: true});

    return res.status(200).json({
      success: true,
      message: `User ${uid} is now an admin.`,
    });
  } catch (error) {
    console.error("🔥 Error setting admin claim:", error);
    return res.status(500).json({
      success: false,
      message: `Failed to set admin: ${error.message}`,
    });
  }
});

// 2️⃣ **Delete a User from Firebase Authentication**
exports.deleteUser = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).json({
      success: false,
      message: "Method Not Allowed",
    });
  }

  const { uid } = req.body;

  if (!uid) {
    return res.status(400).json({
      success: false,
      message: "Missing user ID.",
    });
  }

  try {
    console.log(`🗑️ Attempting to delete user: ${uid}`);

    await admin.auth().deleteUser(uid);

    console.log(`✅ User ${uid} deleted successfully from Authentication`);

    return res.status(200).json({
      success: true,
      message: "User deleted successfully from Authentication.",
    });
  } catch (error) {
    console.error("🔥 Error deleting user from Authentication:", error);
    return res.status(500).json({
      success: false,
      message: `Failed to delete user: ${error.message}`,
    });
  }
});
