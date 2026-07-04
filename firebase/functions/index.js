const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ── 1. Miss You Tap Handler ───────────────────────────────────────────────────
//
// Triggers when the `lastMissYouSentAt` field updates in a couple document.
// Sends an FCM push notification to the partner.

exports.onMissYouTap = functions.firestore
  .document('couples/{coupleId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only fire when lastMissYouSentAt actually changes
    const beforeTime = before.lastMissYouSentAt?.toMillis?.() ?? 0;
    const afterTime  = after.lastMissYouSentAt?.toMillis?.() ?? 0;
    if (afterTime <= beforeTime) return null;

    const senderUid = after.lastMissYouSentBy;
    if (!senderUid) return null;

    const memberIds = after.memberIds || [];
    const partnerUid = memberIds.find(id => id !== senderUid);
    if (!partnerUid) return null;

    // Get sender's display name
    const senderDoc = await db.collection('users').doc(senderUid).get();
    const senderName = senderDoc.exists ? (senderDoc.data().displayName || 'Your partner') : 'Your partner';

    // Get partner's FCM token
    const partnerDoc = await db.collection('users').doc(partnerUid).get();
    if (!partnerDoc.exists) return null;
    const partnerToken = partnerDoc.data().fcmToken;
    if (!partnerToken) return null;

    // Send FCM
    const message = {
      token: partnerToken,
      notification: {
        title: `💕 ${senderName} is thinking of you`,
        body: 'Tap to open LoveSnaps and say hi!',
      },
      data: {
        type: 'miss_you',
        senderUid,
        coupleId: context.params.coupleId,
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'lovesnaps_main',
        },
      },
    };

    try {
      await messaging.send(message);
      functions.logger.info(`Miss you sent from ${senderUid} to ${partnerUid}`);
    } catch (err) {
      functions.logger.error('FCM send failed:', err);
    }

    return null;
  });

// ── 2. Nightly Streak Reset ───────────────────────────────────────────────────
//
// Runs at 00:05 UTC every day.
// - Resets both partnerACheckedIn / partnerBCheckedIn flags.
// - If neither partner checked in, breaks the streak (set to 0).

exports.resetDailyCheckins = functions.pubsub
  .schedule('5 0 * * *')
  .timeZone('UTC')
  .onRun(async () => {
    functions.logger.info('Running nightly streak reset...');

    const couplesSnap = await db.collection('couples').get();
    const batch = db.batch();

    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = yesterday.toISOString().split('T')[0]; // "YYYY-MM-DD"

    for (const doc of couplesSnap.docs) {
      const data = doc.data();
      const lastDate = data.streakLastUpdatedDate;

      const updates = {
        partnerACheckedIn: false,
        partnerBCheckedIn: false,
      };

      // If neither checked in yesterday, break the streak
      if (lastDate !== yesterdayStr) {
        updates.streakCount = 0;
        functions.logger.info(`Streak broken for couple ${doc.id}`);
      }

      batch.update(doc.ref, updates);
    }

    await batch.commit();
    functions.logger.info(`Reset complete for ${couplesSnap.size} couples.`);
    return null;
  });

// ── 3. Monthly Anniversary Notification ───────────────────────────────────────
//
// Runs on the 1st of every month at 08:00 UTC.
// Sends a push to both partners celebrating their monthly anniversary.

exports.monthlyAnniversaryNotification = functions.pubsub
  .schedule('0 8 1 * *')
  .timeZone('UTC')
  .onRun(async () => {
    functions.logger.info('Sending monthly anniversary notifications...');

    const couplesSnap = await db.collection('couples')
      .where('relationshipStartDate', '!=', null)
      .get();

    for (const doc of couplesSnap.docs) {
      const data = doc.data();
      const memberIds = data.memberIds || [];
      if (memberIds.length < 2) continue;

      const startDate = data.relationshipStartDate?.toDate?.();
      if (!startDate) continue;

      const now = new Date();
      const months = (now.getFullYear() - startDate.getFullYear()) * 12
        + (now.getMonth() - startDate.getMonth());
      if (months <= 0) continue;

      const days = data.streakCount || 0;

      // Notify both partners
      for (const uid of memberIds) {
        try {
          const userDoc = await db.collection('users').doc(uid).get();
          const token = userDoc.data()?.fcmToken;
          if (!token) continue;

          await messaging.send({
            token,
            notification: {
              title: `🎉 ${months} month${months === 1 ? '' : 's'} together!`,
              body: `You've been inseparable for ${months} month${months === 1 ? '' : 's'}. Celebrate today! 💕`,
            },
            data: { type: 'anniversary', months: String(months) },
          });
        } catch (err) {
          functions.logger.error(`Failed to notify ${uid}:`, err);
        }
      }
    }

    return null;
  });

// ── 4. Milestone Notification ─────────────────────────────────────────────────
//
// Runs daily at 08:05 UTC. Checks if any couple hits a milestone day today.

exports.dailyMilestoneCheck = functions.pubsub
  .schedule('5 8 * * *')
  .timeZone('UTC')
  .onRun(async () => {
    const milestones = [7, 14, 30, 50, 100, 150, 200, 365, 500, 730, 1000];
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const couplesSnap = await db.collection('couples')
      .where('relationshipStartDate', '!=', null)
      .get();

    for (const doc of couplesSnap.docs) {
      const data = doc.data();
      const startDate = data.relationshipStartDate?.toDate?.();
      if (!startDate) continue;

      const start = new Date(startDate);
      start.setHours(0, 0, 0, 0);
      const daysDiff = Math.floor((today - start) / (1000 * 60 * 60 * 24)) + 1;

      if (!milestones.includes(daysDiff)) continue;

      const memberIds = data.memberIds || [];
      for (const uid of memberIds) {
        try {
          const userDoc = await db.collection('users').doc(uid).get();
          const token = userDoc.data()?.fcmToken;
          if (!token) continue;

          await messaging.send({
            token,
            notification: {
              title: `⭐ Day ${daysDiff} together!`,
              body: `You've hit a milestone — ${daysDiff} days as a couple. Keep going! 💕`,
            },
            data: { type: 'milestone', days: String(daysDiff) },
          });
        } catch (err) {
          functions.logger.error(`Milestone notify failed for ${uid}:`, err);
        }
      }
    }

    return null;
  });
