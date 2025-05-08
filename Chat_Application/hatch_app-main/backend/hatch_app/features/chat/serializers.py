from rest_framework import serializers
from .models import Bucket, BucketMember, Channel, ChannelMember, Message, MessageReaction, MessageSeen
from hatch_app.features.user.models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'name', 'email']

class BucketSerializer(serializers.ModelSerializer):
    class Meta:
        model = Bucket
        fields = '__all__'

class BucketMemberSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = BucketMember
        fields = '__all__'

class ChannelSerializer(serializers.ModelSerializer):
    class Meta:
        model = Channel
        fields = '__all__'

class ChannelMemberSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = ChannelMember
        fields = '__all__'

class MessageSerializer(serializers.ModelSerializer):
    sender = UserSerializer(read_only=True)
    
    class Meta:
        model = Message
        fields = '__all__'

class MessageReactionSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = MessageReaction
        fields = '__all__'

class MessageSeenSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = MessageSeen
        fields = '__all__'


class WebSocketMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ['message_text', 'channel_id', 'sender_id']
        extra_kwargs = {
            'sender_id': {'write_only': True},
            'channel_id': {'write_only': True}
        }

    def validate_sender_id(self, value):
        if value != self.context['user'].id:
            raise serializers.ValidationError("Sender ID doesn't match authenticated user")
        return value

    def validate_channel_id(self, value):
        if not ChannelMember.objects.filter(
            channel_id=value,
            user_id=self.context['user'].id
        ).exists():
            raise serializers.ValidationError("User is not a member of this channel")
        return value