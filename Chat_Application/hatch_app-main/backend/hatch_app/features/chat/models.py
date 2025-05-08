from django.db import models
from hatch_app.features.user.models import User

class Bucket(models.Model):
    name = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    picture = models.CharField(max_length=255, default='https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSpwxCN33LtdMLbWdhafc4HxabqpaU0qVbDxQ&s')

    def __str__(self):
        return f"{self.name},{self.id}"
    
class BucketMember(models.Model):
    bucket = models.ForeignKey(Bucket, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    role = models.CharField(max_length=50)  # Role (permission level)
    invite_accepted = models.BooleanField(default=False)  # Whether the user was invited or not
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('bucket', 'user')

    def __str__(self):
        return f"{self.user.name} in {self.bucket.name} with role {self.role}"

class Channel(models.Model):
    bucket = models.ForeignKey(Bucket, on_delete=models.CASCADE, related_name='channels')
    name = models.CharField(max_length=255)
    channel_type = models.CharField(max_length=50)  # E.g., 'group' or 'direct'
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    picture = models.CharField(max_length=255, default='https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSpwxCN33LtdMLbWdhafc4HxabqpaU0qVbDxQ&s')
    def __str__(self):
        return f"{self.id}: {self.name} in {self.bucket.name} "

class ChannelMember(models.Model):
    channel = models.ForeignKey(Channel, on_delete=models.CASCADE, related_name='members')
    user = models.ForeignKey(User, on_delete=models.CASCADE,db_column='user_id',to_field='id')
    invite_accepted = models.BooleanField(default=True)  
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('channel', 'user')

    def __str__(self):
        return f"{self.id}  {self.channel.id}:{self.user.name} in {self.channel.name} in bucket: {self.channel.bucket.name}"

class Message(models.Model):
    sender = models.ForeignKey(User, on_delete=models.CASCADE)
    channel = models.ForeignKey(Channel, on_delete=models.CASCADE)
    message_text = models.TextField()
    message_file = models.TextField(null=True, blank=True)
    join_channel = models.CharField(max_length=255, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Message from {self.sender.name} in {self.channel.name}"

class MessageReaction(models.Model):
    message = models.ForeignKey(Message, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    reaction = models.CharField(max_length=50)  # E.g., emoji or text reaction
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('message', 'user')

    def __str__(self):
        return f"Reaction by {self.user.name} to message {self.message.id}"

class MessageSeen(models.Model):
    message = models.ForeignKey(Message, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    seen_at = models.DateTimeField()

    class Meta:
        unique_together = ('message', 'user')

    def __str__(self):
        return f"{self.user.name} saw message {self.message.id}"
    
class ChatBot(models.Model):
    name = models.CharField(max_length=255)
    user = models.ForeignKey(User, on_delete=models.CASCADE)

class ChatBotMessage(models.Model):
    chat_bot = models.ForeignKey(ChatBot, on_delete=models.CASCADE)
    message_text = models.TextField()
    reply_text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Message from {self.chat_bot.name}"