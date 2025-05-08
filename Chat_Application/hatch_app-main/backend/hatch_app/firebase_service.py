import firebase_admin
from firebase_admin import messaging
from django.conf import settings

def initialize_firebase():
    if not firebase_admin._apps:
        cred = firebase_admin.credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        firebase_admin.initialize_app(cred)

def send_push_notification(token, title, body, data=None):
    initialize_firebase()
    
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        token=token,
        data=data or {}
    )
    
    try:
        messaging.send(message)
        return True
    except Exception as e:
        print(f"Error sending notification: {e}")
        return False