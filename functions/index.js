const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

exports.deleteExpiredTasks = functions.pubsub
  .schedule("every 1 hour")
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    // Получаем заявки, у которых eventTime < сейчас (т.е. прошли)
    const expiredTasksQuery = db
      .collection("tasks")
      .where("eventTime", "<", now);
    const expiredTasksSnapshot = await expiredTasksQuery.get();

    const batch = db.batch();

    expiredTasksSnapshot.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();

    console.log(`Deleted ${expiredTasksSnapshot.size} expired tasks`);
    return null;
  });

exports.clearStaleInProgressTasks = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    // Вычисляем время 24 часа назад
    const cutoffTime = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 24 * 60 * 60 * 1000),
    );

    // Ищем заявки в статусе in_progress, которые обновлялись более 24 часов назад
    const staleTasksQuery = db
      .collection("tasks")
      .where("status", "==", "in_progress")
      .where("statusUpdatedAt", "<", cutoffTime);

    const staleTasksSnapshot = await staleTasksQuery.get();

    const batch = db.batch();

    staleTasksSnapshot.forEach((doc) => {
      // Вариант 1: удаляем заявку
      // batch.delete(doc.ref);

      // Вариант 2: меняем статус на "expired" или "cancelled"
      batch.update(doc.ref, {
        status: "expired",
        statusUpdatedAt: now,
      });
    });

    await batch.commit();

    console.log(`Processed ${staleTasksSnapshot.size} stale in-progress tasks`);
    return null;
  });
