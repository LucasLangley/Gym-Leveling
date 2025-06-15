import {
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {HttpsError} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Cloud Function (v2) triggered when a guild invitation status is updated
 * to 'accepted_by_user'.
 * Processes the user's entry into the guild, updating user and guild docs.
 */
export const onGuildInvitationAccepted = onDocumentUpdated(
  {
    document: "users/{userId}/guildInvitations/{guildId}",
    region: "southamerica-east1",
  },
  async (event) => {
    if (!event.data) {
      logger.info("No data associated with the event. Exiting function.");
      return null;
    }

    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    // Get params from the event context
    const params = event.params;
    const userId = params.userId;
    const guildId = params.guildId;

    if (
      afterData?.status !== "accepted_by_user" ||
      beforeData?.status !== "pending"
    ) {
      logger.info(
        `Invitation ${guildId} for user ${userId} not processed: ` +
        `status was '${afterData?.status}', ` +
        `previous was '${beforeData?.status}'.`
      );
      return null;
    }

    logger.info(
      `Processing guild invitation acceptance for user ${userId} ` +
      `to guild ${guildId}`
    );

    const userDocRef = db.collection("users").doc(userId);
    const guildDocRef = db.collection("guilds").doc(guildId);
    const invitationDocRef = event.data.after.ref;

    try {
      await db.runTransaction(async (transaction) => {
        const userDoc = await transaction.get(userDocRef);
        const guildDoc = await transaction.get(guildDocRef);

        if (!userDoc.exists) {
          throw new HttpsError(
            "not-found",
            `User document ${userId} not found.`
          );
        }
        if (!guildDoc.exists) {
          logger.warn(
            `Guild ${guildId} not found for invitation by ${userId}. ` +
            "Updating invitation status."
          );
          transaction.update(invitationDocRef, {
            status: "error_guild_not_found",
          });
          return;
        }

        // Get data without type assertions
        const userData = userDoc.data();
        const guildData = guildDoc.data();

        if (userData.guildId) {
          logger.warn(
            `User ${userId} is already in guild ${userData.guildId}. ` +
            `Cannot join ${guildId}.`
          );
          transaction.update(invitationDocRef, {
            status: "error_already_in_guild",
          });
          return;
        }

        const currentMembers = guildData.members || {};
        if (currentMembers[userId]) {
          logger.warn(
            `User ${userId} is already a member of guild ${guildId} ` +
            "(data inconsistency?)."
          );
          transaction.update(invitationDocRef, {
            status: "processed_already_member",
          });
          return;
        }

        currentMembers[userId] = "Membro";
        const newMemberCount = (guildData.memberCount || 0) + 1;
        const userAura = userData.aura || 0;
        const newTotalAura = (guildData.totalAura || 0) + userAura;

        transaction.update(guildDocRef, {
          members: currentMembers,
          memberCount: newMemberCount,
          totalAura: newTotalAura,
        });

        transaction.update(userDocRef, {
          guildId: guildId,
          guildName: guildData.name || "Nome da Guilda",
          guildRole: "Membro",
        });

        transaction.update(invitationDocRef, {status: "processed_accepted"});
      });

      logger.info(
        `User ${userId} successfully joined guild ${guildId}.`
      );
      return null;
    } catch (error) {
      logger.error(
        `Error accepting guild invitation for user ${userId} ` +
        `to guild ${guildId}:`,
        error
      );
      try {
        // Attempt to mark the invitation as failed if the transaction fails
        await invitationDocRef.update({
          status: "error_processing_transaction",
        });
      } catch (revertError) {
        logger.error(
          "Error trying to mark invitation as error_processing_transaction:",
          revertError
        );
      }

      if (error instanceof HttpsError) {
        throw error;
      }
      throw new HttpsError(
        "internal",
        "Failed to process guild invitation.",
        error?.message || "Unknown error during transaction."
      );
    }
  }
);

