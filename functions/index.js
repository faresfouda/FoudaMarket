const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendOrderStatusNotification = functions.firestore
    .document("orders/{orderId}")
    .onUpdate(async (change, context) => {
        const beforeStatus = change.before.data().status;
        const afterStatus = change.after.data().status;

        // إذا لم تتغير الحالة، لا ترسل إشعار
        if (beforeStatus === afterStatus) {
            return null;
        }

        const userId = change.after.data().userId;
        const orderId = context.params.orderId;

        // جلب توكن المستخدم من Firestore
        const userDoc = await admin
            .firestore()
            .collection("users")
            .doc(userId)
            .get();
        const fcmToken = userDoc.data().fcmToken;

        if (!fcmToken) {
            console.log("No FCM token for user:", userId);
            return null;
        }

        // نص الإشعار حسب الحالة الجديدة
        const statusText = {
            pending: "قيد الانتظار",
            accepted: "تم قبول الطلب",
            preparing: "جاري التحضير",
            delivering: "جاري التوصيل",
            delivered: "تم التوصيل",
            cancelled: "تم إلغاء الطلب",
            failed: "فشل الطلب",
        }[afterStatus] || afterStatus;

        const payload = {
            notification: {
                title: "تحديث حالة الطلب",
                body: "تم تحديث حالة طلبك إلى: " + statusText,
            },
            data: {
                orderId: orderId,
                newStatus: afterStatus,
            },
        };

        // إرسال الإشعار
        await admin.messaging().sendToDevice(fcmToken, payload);
        console.log(
            "Notification sent to", userId, "for order", orderId,
        );
        return null;
    });
