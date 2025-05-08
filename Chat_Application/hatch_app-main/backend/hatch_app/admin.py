from django.contrib import admin
from .features.user.models import User
from .features.chat.models import Channel, ChannelMember, Message, MessageReaction, MessageSeen, Bucket, BucketMember
from .features.tasks.models import Task

admin.site.register(User)
admin.site.register(Channel)
admin.site.register(Task)
admin.site.register(ChannelMember)
admin.site.register(Message)
admin.site.register(MessageReaction)
admin.site.register(MessageSeen)
admin.site.register(Bucket)
admin.site.register(BucketMember)