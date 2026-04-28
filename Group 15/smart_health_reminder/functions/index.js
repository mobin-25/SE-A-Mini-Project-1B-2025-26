/**
 * Firebase Cloud Functions for MEDITOUCH appointment push notifications.
 *
 * Triggers:
 * 1. onNewAppointment — When a new appointment is created in the shared
 *    'appointments' collection, send a push notification to the doctor.
 * 2. onAppointmentStatusChange — When an appointment's status field changes
 *    (accepted / declined / cancelled / rescheduled), send a push
 *    notification to the patient.
 */

const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

// ─── Helper: send a push notification to a user by their uid ─────────
async function sendPushToUser(uid, title, body, data = {}) {
  if (!uid) return;

  // Look up the user's FCM token
  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists) return;

  const fcmToken = userDoc.data().fcmToken;
  if (!fcmToken) return;

  const message = {
    token: fcmToken,
    notification: { title, body },
    data: {
      ...data,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    android: {
      notification: {
        channelId: "appointment_notifications",
        priority: "high",
        sound: "default",
      },
    },
  };

  try {
    await messaging.send(message);
    console.log(`Push sent to ${uid}: "${title}"`);
  } catch (err) {
    // If the token is invalid, clean it up
    if (
      err.code === "messaging/invalid-registration-token" ||
      err.code === "messaging/registration-token-not-registered"
    ) {
      await db.collection("users").doc(uid).update({ fcmToken: null });
      console.log(`Removed stale FCM token for ${uid}`);
    } else {
      console.error(`FCM send failed for ${uid}:`, err);
    }
  }
}

// ─── Helper: format a date string nicely ─────────────────────────────
function formatDate(isoString) {
  if (!isoString) return "N/A";
  const d = new Date(isoString);
  return d.toLocaleString("en-IN", {
    dateStyle: "medium",
    timeStyle: "short",
  });
}

// ─── 1. New appointment → notify doctor ──────────────────────────────
exports.onNewAppointment = onDocumentCreated(
  "appointments/{appointmentId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const appointment = snap.data();

    const doctorId = appointment.doctorId;
    const patientName = appointment.patientName || "A patient";
    const specialty = appointment.specialty || "General";
    const dateStr = formatDate(appointment.dateTime);

    const title = "New Appointment Request";
    const body = `${patientName} booked a ${specialty} appointment for ${dateStr}.`;

    await sendPushToUser(doctorId, title, body, {
      type: "new_appointment",
      appointmentId: event.params.appointmentId,
    });
  }
);

// ─── 2. Appointment status change → notify patient ───────────────────
exports.onAppointmentStatusChange = onDocumentUpdated(
  "appointments/{appointmentId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    // Only fire when the status actually changes
    if (before.status === after.status) return;

    const patientId = after.patientId;
    const doctorName = after.doctorName || "Your doctor";
    const newStatus = after.status;

    let title, body;

    switch (newStatus) {
      case "accepted":
        title = "Appointment Accepted ✅";
        body = `Your appointment with ${doctorName} has been accepted.`;
        break;
      case "declined":
        title = "Appointment Declined";
        body = after.cancelReason
          ? `Your appointment with ${doctorName} was declined. Reason: ${after.cancelReason}`
          : `Your appointment with ${doctorName} was declined.`;
        break;
      case "cancelled":
        title = "Appointment Cancelled";
        body = after.cancelReason
          ? `Your appointment with ${doctorName} was cancelled. Reason: ${after.cancelReason}`
          : `Your appointment with ${doctorName} was cancelled.`;
        break;
      case "rescheduled":
        title = "Appointment Rescheduled";
        body = `Your appointment with ${doctorName} has been rescheduled to ${formatDate(after.dateTime)}.`;
        break;
      default:
        // Unknown status change — skip
        return;
    }

    await sendPushToUser(patientId, title, body, {
      type: "appointment_status",
      appointmentId: event.params.appointmentId,
      status: newStatus,
    });
  }
);
