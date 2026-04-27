import os
import json
from typing import List, Optional

# Firebase Admin SDK - install with: pip install firebase-admin
try:
    import firebase_admin
    from firebase_admin import credentials, messaging
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False
    print("Warning: firebase-admin not installed. Push notifications disabled.")


class NotificationService:
    """Service for sending push notifications via Firebase Cloud Messaging"""
    
    def __init__(self, credentials_path: str = None):
        self.initialized = False
        
        if not FIREBASE_AVAILABLE:
            print("Firebase not available. Notifications disabled.")
            return
        
        if credentials_path and os.path.exists(credentials_path):
            try:
                cred = credentials.Certificate(credentials_path)
                firebase_admin.initialize_app(cred)
                self.initialized = True
                print("Firebase initialized successfully")
            except Exception as e:
                print(f"Failed to initialize Firebase: {e}")
        else:
            print(f"Firebase credentials not found at: {credentials_path}")
    
    def send_to_token(self, device_token: str, title: str, body: str, data: dict = None) -> bool:
        """
        Send notification to a single device
        
        Args:
            device_token: FCM device token
            title: Notification title
            body: Notification body
            data: Additional data payload
        
        Returns:
            bool: True if sent successfully
        """
        if not self.initialized:
            print(f"[MOCK] Would send notification: {title} - {body}")
            return True  # Return True for development without Firebase
        
        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data or {},
                token=device_token,
            )
            
            response = messaging.send(message)
            print(f"Successfully sent notification: {response}")
            return True
            
        except Exception as e:
            print(f"Error sending notification: {e}")
            return False
    
    def send_to_multiple(self, device_tokens: List[str], title: str, body: str, data: dict = None) -> dict:
        """
        Send notification to multiple devices
        
        Args:
            device_tokens: List of FCM device tokens
            title: Notification title
            body: Notification body
            data: Additional data payload
        
        Returns:
            dict: Success and failure counts
        """
        if not self.initialized:
            print(f"[MOCK] Would send to {len(device_tokens)} devices: {title}")
            return {'success': len(device_tokens), 'failure': 0}
        
        if not device_tokens:
            return {'success': 0, 'failure': 0}
        
        try:
            message = messaging.MulticastMessage(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data or {},
                tokens=device_tokens,
            )
            
            response = messaging.send_multicast(message)
            print(f"Sent {response.success_count} notifications, {response.failure_count} failed")
            
            return {
                'success': response.success_count,
                'failure': response.failure_count
            }
            
        except Exception as e:
            print(f"Error sending multicast notification: {e}")
            return {'success': 0, 'failure': len(device_tokens)}
    
    def send_queue_update(self, device_token: str, service_name: str, new_position: int) -> bool:
        """
        Send queue position update notification
        
        Args:
            device_token: FCM device token
            service_name: Name of the service
            new_position: New queue position
        
        Returns:
            bool: True if sent successfully
        """
        title = "Queue Update"
        body = f"Your position for {service_name} is now #{new_position}"
        
        data = {
            'type': 'queue_update',
            'service_name': service_name,
            'position': str(new_position)
        }
        
        return self.send_to_token(device_token, title, body, data)
    
    def send_admin_message(self, device_tokens: List[str], custom_message: str) -> dict:
        """
        Send custom admin message to users
        
        Args:
            device_tokens: List of FCM device tokens
            custom_message: Custom message from admin
        
        Returns:
            dict: Success and failure counts
        """
        title = "Admin Notification"
        body = custom_message
        
        data = {
            'type': 'admin_message'
        }
        
        return self.send_to_multiple(device_tokens, title, body, data)
    
    def send_token_completed(self, device_token: str, service_name: str) -> bool:
        """
        Notify user their token has been completed
        
        Args:
            device_token: FCM device token
            service_name: Name of the service
        
        Returns:
            bool: True if sent successfully
        """
        title = "Token Completed"
        body = f"Your token for {service_name} has been completed!"
        
        data = {
            'type': 'token_completed',
            'service_name': service_name
        }
        
        return self.send_to_token(device_token, title, body, data)


# Global notification service instance
notification_service = None

def init_notification_service(credentials_path: str = None):
    """Initialize the global notification service"""
    global notification_service
    notification_service = NotificationService(credentials_path)
    return notification_service

def get_notification_service() -> NotificationService:
    """Get the global notification service instance"""
    global notification_service
    if notification_service is None:
        notification_service = NotificationService()
    return notification_service