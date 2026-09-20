import firebase_admin
from firebase_admin import credentials, messaging
from pathlib import Path

# تهيئة Firebase مرة واحدة بس
BASE_DIR = Path(__file__).resolve().parent.parent
cred_path = BASE_DIR / "firebase-service-account.json"

if not firebase_admin._apps:
    cred = credentials.Certificate(str(cred_path))
    firebase_admin.initialize_app(cred)


def send_push_notification(token: str, title: str, body: str):
    """
    إرسال إشعار لشخص واحد عن طريق FCM Token
    """
    if not token:
        print("No FCM token provided")
        return False

    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            token=token,
        )

        response = messaging.send(message)
        print(f"Successfully sent message: {response}")
        return True

    except Exception as e:
        print(f"Error sending push notification: {e}")
        return False