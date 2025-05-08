import json
from channels.generic.websocket import AsyncWebsocketConsumer
from django.core.exceptions import ObjectDoesNotExist
from rest_framework.exceptions import ValidationError
from asgiref.sync import sync_to_async
from .serializers import WebSocketMessageSerializer
from .models import Message, ChannelMember
from hatch_app.firebase_service import send_push_notification

class ChatConsumer(AsyncWebsocketConsumer):
    connected_users = set()

    async def connect(self):

        self.channel_id = self.scope["url_route"]["kwargs"]["channel_id"]
        self.user = self.scope["user"]

        self.group_name = f"chat_{self.channel_id}"

        await self.channel_layer.group_add(self.group_name, self.channel_name)

        await self.accept()


    async def disconnect(self, close_code):
        if hasattr(self, 'group_name') and hasattr(self, 'channel_name'):
            await self.channel_layer.group_discard(self.group_name, self.channel_name)
        if hasattr(self, 'user') and hasattr(self.user, 'id'):
            self.connected_users.discard(self.user.id)

    async def receive(self, text_data):
        try:
            data = json.loads(text_data)
            
            serializer = WebSocketMessageSerializer(
                data=data,
                context={'user': self.user}
            )
            
            is_valid = await sync_to_async(serializer.is_valid)(raise_exception=True)
            
            if is_valid:
                message = await sync_to_async(serializer.save)()
                
                await self.channel_layer.group_send(
                    self.group_name,
                    {
                        "type": "chat.message",
                        "message": message.message_text,
                        "sender": self.user.name,
                        "sender_id": self.user.id,
                        "timestamp": message.created_at.isoformat(),
                    }
                )
                
                await self.send_notifications_to_offline_members(
                    self.channel_id,
                    message.message_text
                )

        except json.JSONDecodeError:
            await self.send(text_data=json.dumps({"error": "Invalid JSON format"}))
        except ValidationError as e:
            await self.send(text_data=json.dumps({"error": str(e.detail)}))
        except Exception as e:
            await self.send(text_data=json.dumps({"error": "Internal server error"}))

    async def chat_message(self, event):
        await self.send(text_data=json.dumps(event))