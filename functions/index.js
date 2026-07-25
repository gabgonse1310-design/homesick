const {onDocumentCreated, onDocumentUpdated} =
  require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

async function activeTokensForUser(uid) {
  if (!uid) return [];

  const snapshot = await getFirestore()
      .collection("users")
      .doc(uid)
      .collection("devices")
      .where("enabled", "==", true)
      .get();

  return snapshot.docs
      .map((document) => document.data().token)
      .filter((token) => typeof token === "string" && token.length > 0);
}

async function sendToUser(uid, notification, data) {
  const tokens = await activeTokensForUser(uid);
  if (tokens.length === 0) return;

  const response = await getMessaging().sendEachForMulticast({
    tokens,
    notification,
    data: Object.fromEntries(
        Object.entries(data).map(([key, value]) => [key, String(value ?? "")]),
    ),
    android: {
      priority: "high",
      notification: {
        channelId: "homesick_letters",
        sound: "default",
      },
    },
  });

  const invalidTokens = [];
  response.responses.forEach((result, index) => {
    const code = result.error?.code ?? "";
    if (code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token") {
      invalidTokens.push(tokens[index]);
    }
  });

  if (invalidTokens.length > 0) {
    const db = getFirestore();
    const deviceSnapshot = await db
        .collection("users")
        .doc(uid)
        .collection("devices")
        .where("token", "in", invalidTokens.slice(0, 30))
        .get();

    const batch = db.batch();
    deviceSnapshot.docs.forEach((document) => {
      batch.set(
          document.ref,
          {enabled: false, invalidatedAt: new Date()},
          {merge: true},
      );
    });
    await batch.commit();
  }
}

exports.notifyNewSharedLetter = onDocumentCreated(
    "sharedLetters/{letterId}",
    async (event) => {
      const letter = event.data?.data();
      if (!letter) return;

      const recipientUid = letter.recipientUid ?? "";
      const senderName = letter.senderName || "Someone you care about";
      const isCapsule = letter.isTimeCapsule === true;

      await sendToUser(
          recipientUid,
          {
            title: isCapsule ? "A time capsule is waiting" : "New words for you",
            body: isCapsule ?
              `${senderName} sealed something for your future.` :
              `${senderName} sent you a letter.`,
          },
          {
            type: isCapsule ? "time_capsule_received" : "new_letter",
            letterId: event.params.letterId,
          },
      );
    },
);

exports.notifyConnectionInvitation = onDocumentCreated(
    "connectionInvitations/{invitationId}",
    async (event) => {
      const invitation = event.data?.data();
      if (!invitation) return;

      const recipientUid = invitation.recipientUid ?? "";
      if (!recipientUid) return;

      const senderName = invitation.senderName || invitation.senderEmail ||
          "Someone";

      await sendToUser(
          recipientUid,
          {
            title: "A new connection",
            body: `${senderName} would like to connect with you on Homesick.`,
          },
          {
            type: "connection_invitation",
            invitationId: event.params.invitationId,
          },
      );
    },
);

exports.notifyInvitationAccepted = onDocumentUpdated(
    "connectionInvitations/{invitationId}",
    async (event) => {
      const before = event.data?.before.data();
      const after = event.data?.after.data();
      if (!before || !after) return;

      if (before.status === after.status || after.status !== "accepted") return;

      const recipientName = after.recipientName || after.recipientEmail ||
          "Your person";

      await sendToUser(
          after.senderUid ?? "",
          {
            title: "Invitation accepted",
            body: `${recipientName} is now connected with you on Homesick.`,
          },
          {
            type: "invitation_accepted",
            invitationId: event.params.invitationId,
          },
      );
    },
);
