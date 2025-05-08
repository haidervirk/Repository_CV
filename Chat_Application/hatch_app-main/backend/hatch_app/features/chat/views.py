from django.shortcuts import get_object_or_404
from hatch_app.decorators import token_required
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from .models import Bucket, BucketMember, Channel, ChannelMember, Message, MessageReaction, MessageSeen, ChatBot , ChatBotMessage
from .serializers import (
    BucketSerializer, BucketMemberSerializer,
    ChannelSerializer, ChannelMemberSerializer,
    MessageSerializer, MessageReactionSerializer, MessageSeenSerializer
)
from hatch_app.features.chat.chatbot import hatch_chatbot
from django.core.paginator import Paginator,EmptyPage, PageNotAnInteger
from django.db.models import OuterRef, Subquery, Count
from django.db import transaction
from django.core.exceptions import ObjectDoesNotExist
from hatch_app.features.user.models import User
from django.conf import settings


def check_bucket_membership(bucket_id, user, required_roles=None):
    """Check if the user is a member of the bucket and optionally validate roles."""
    bucket = get_object_or_404(Bucket, id=bucket_id)
    try:
        bucket_member = BucketMember.objects.get(bucket=bucket, user=user)
        if required_roles and bucket_member.role not in required_roles:
            return Response({'error': f'Permission denied. Required roles: {required_roles}'}, status=status.HTTP_403_FORBIDDEN)
        return bucket
    except BucketMember.DoesNotExist:
        return Response({'error': 'You are not a member of this bucket'}, status=status.HTTP_403_FORBIDDEN)

def check_bucket_invite(bucket_id, user):
    """Checks if a user is invited to a bucket and hasn't already accepted the invite"""
    bucket = get_object_or_404(Bucket, id=bucket_id)
    try:
        bucket_member = BucketMember.objects.get(bucket=bucket, user=user)
        if bucket_member.invite_accepted:
            return Response({'error': f'You are already a member of this bucket'}, status=status.HTTP_403_FORBIDDEN)
        return bucket
    except BucketMember.DoesNotExist:
        return Response({'error': 'You are not invited to this bucket'}, status=status.HTTP_403_FORBIDDEN)

    
def check_channel_membership(channel_id, user):
    """Check if the user is a member of the channel."""
    if not ChannelMember.objects.filter(channel_id=channel_id, user=user).exists():
        return Response({'error': 'You are not a member of this channel'}, status=status.HTTP_403_FORBIDDEN)


@api_view(['POST'])
@token_required
@transaction.atomic
def send_chatbot_message(request):
    """
    Send a message to chatbot, get API response, and store both message and reply.
    """
    message_text = request.data.get('message')
    user = get_object_or_404(User, id=request.user)
    if not message_text:
        return Response(
            {"error": "Message is required"}, 
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        chatbot_lol, created = ChatBot.objects.get_or_create(
            user_id=request.user,
            defaults={'name': f"{user.name}'s Assistant"}
        )

        bot_reply = hatch_chatbot.generate(message_text)

        chat_message = ChatBotMessage.objects.create(
            chat_bot=chatbot_lol,
            message_text=message_text,
            reply_text=bot_reply
        )
        return Response({
            'chatbot_id': chatbot_lol.id,
            'chatbot_name': chatbot_lol.name,
            'current_message': {
                'message_id': chat_message.id,
                'user_message': message_text,
                'bot_reply': bot_reply,
                'timestamp': chat_message.created_at
            },
        }, status=status.HTTP_200_OK)

    except ValueError as e:
        return Response(
            {"error": str(e)}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    except Exception as e:
        return Response(
            {"error": f"Error processing message: {str(e)}"}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@token_required
def get_chat_messages(request):
    """Retrieve the latest direct messages (1-on-1 chats) for the user."""
    direct_channels = Channel.objects.filter(
        members__user=request.user,
        channel_type="direct"
    )

    latest_messages = Message.objects.filter(
        channel=OuterRef('id')
    ).order_by('-created_at')

    
    direct_channels_with_messages = direct_channels.annotate(
        latest_message=Subquery(latest_messages.values('message_text')[:1]),
        latest_sender=Subquery(latest_messages.values('sender__name')[:1]),
        latest_sender_id=Subquery(latest_messages.values('sender__id')[:1]),
        latest_timestamp=Subquery(latest_messages.values('created_at')[:1])
    ).order_by('-latest_timestamp')

    message_list = []
    for channel in direct_channels_with_messages:
        members = ChannelMember.objects.filter(channel_id=channel.id).exclude(user=request.user)
        last_message = {
            
            'channel_id': channel.id,
            'channel_name': members.first().user.name if members.exists() else 'Unknown',
            'profile_picture': members.first().user.profile_picture if members.exists() else None,
            'latest_message': channel.latest_message or 'No messages yet',
            'latest_sender_name': channel.latest_sender,
            'latest_sender_id': channel.latest_sender_id ,
            'timestamp': channel.latest_timestamp
        }
        message_list.append(last_message)

    return Response(message_list)

@api_view(['GET'])
@token_required
def get_community_messages(request):
    """Retrieve the latest messages from community channels."""

    buckets = Bucket.objects.filter(
        bucketmember__user=request.user
    ).annotate(member_count=Count('bucketmember'))

    bucket_list = []
    for bucket in buckets:

        community_channels = Channel.objects.filter(
            bucket=bucket,
            members__user=request.user,
            channel_type="community"

        ).annotate(
            latest_message=Subquery(
                Message.objects.filter(channel=OuterRef('id')).order_by('-created_at').values('message_text')[:1]
            ),
            latest_sender_name=Subquery(
                Message.objects.filter(channel=OuterRef('id')).order_by('-created_at').values('sender__name')[:1]
            ),
            latest_sender_id=Subquery(
                Message.objects.filter(channel=OuterRef('id')).order_by('-created_at').values('sender__id')[:1]
            ),
            latest_timestamp=Subquery(
                Message.objects.filter(channel=OuterRef('id')).order_by('-created_at').values('created_at')[:1]
            )
        )

        channels_list = []
        for channel in community_channels:
            channels_list.append({
                'channel_id': channel.id,
                'channel_name': channel.name,
                'picture': channel.picture,
                'latest_message': channel.latest_message or 'No messages yet',
                'latest_sender_name': channel.latest_sender_name,
                'latest_sender_id': channel.latest_sender_id,
                'timestamp': channel.latest_timestamp
            })

        bucket_list.append({
            "Bucket ID": bucket.id,
            "Bucket Name": bucket.name,
            "Bucket Picture": bucket.picture,
            "Bucket_id": bucket.id,
            "Member Count": bucket.member_count,
            "channels_list": channels_list
        })

    return Response(bucket_list)

@api_view(['POST'])
def create_bucket(request):
    data = request.data
    bucket_serializer = BucketSerializer(data=data)  
    if bucket_serializer.is_valid():
        bucket = bucket_serializer.save()

        BucketMember.objects.create(
            bucket=bucket,
            user=request.user,
            role='admin'
        )
        return Response(bucket_serializer.data, status=status.HTTP_201_CREATED)
    return Response(bucket_serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
def delete_bucket(request, bucket_id):
    bucket = check_bucket_membership(bucket_id, request.user, required_roles=['admin'])
    if isinstance(bucket, Response):
        return bucket
    bucket.delete()
    return Response({'message': 'Bucket deleted'}, status=status.HTTP_204_NO_CONTENT)

@api_view(['GET'])
def list_buckets(request):
    user = request.user

    buckets = Bucket.objects.filter(
        bucketmember__user=user
    ).annotate(member_count=Count('bucketmember'))

    bucket_list = []
    for bucket in buckets:
        bucket_data = {
            "id": bucket.id,
            "name": bucket.name,
            "member_count": bucket.member_count,
        }
        bucket_list.append(bucket_data)

    return Response(bucket_list)

@api_view(['POST'])
def add_bucket_member(request):
    data = request.data

    serializer = BucketMemberSerializer(data=data)
    if serializer.is_valid():
        bucket_id = data.get('bucket')
        bucket_check = check_bucket_membership(bucket_id, request.user, required_roles=['admin'])
        if isinstance(bucket_check, Response):
            return bucket_check
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
def remove_bucket_member(request, bucket_id, user_id):
    bucket_check = check_bucket_membership(bucket_id, request.user, required_roles=['admin'])
    if isinstance(bucket_check, Response):
        return bucket_check
    member = get_object_or_404(BucketMember, bucket_id=bucket_id, user_id=user_id)
    member.delete()
    return Response({'message': 'User removed from bucket'}, status=status.HTTP_204_NO_CONTENT)


@api_view(['GET'])
@token_required
def list_bucket_members(request, bucket_id):

    bucket_check = check_bucket_membership(bucket_id, request.user)
    if isinstance(bucket_check, Response):
        return bucket_check

    members = BucketMember.objects.filter(bucket_id=bucket_id)
    serializer = BucketMemberSerializer(members, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['GET'])
@token_required
def get_channel_settings(request, channel_id):
    """
    List channel members with their names and bucket membership status.
    Returns only member name and their role in the associated bucket.
    """
    try:
        # Check channel membership
        membership_check = check_channel_membership(channel_id, request.user)
        if isinstance(membership_check, Response):
            return membership_check

        # Get channel and its bucket
        channel = get_object_or_404(Channel, id=channel_id)
        bucket_id = channel.bucket.id

        # Get channel members with their bucket status
        members = ChannelMember.objects.filter(
            channel_id=channel_id
        ).select_related('user')

        # Format response data
        member_data = []
        for member in members:
            try:
                # Get member's bucket status
                bucket_member = BucketMember.objects.get(
                    bucket_id=bucket_id,
                    user=member.user
                )
                member_data.append({
                    'member_name': member.user.name,
                    'member_id': member.user.id,
                    'bucket_role': bucket_member.role,
                })
            except BucketMember.DoesNotExist:
                continue
        res = {
            'channel_id': channel.id,
            'channel_name': channel.name,
            'channel_picture': channel.picture,
            'members': member_data
        }
        return Response(res, status=status.HTTP_200_OK)

    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    

@api_view(['POST'])
@token_required
@transaction.atomic
def create_channel(request):
    """Creates a new channel (group or direct) and optionally a new bucket, adds members, and sends invites if needed."""
    data = request.data.copy()
    bucket_id = data.get('bucket')
    bucket_name = data.get('bucket_name')
    channel_members = data.get('members', [])
    sender = get_object_or_404(User, id=request.user)

    if not bucket_id and not bucket_name:
        return Response({'error': 'Either bucket_id or bucket_name is required.'}, status=status.HTTP_400_BAD_REQUEST)

    if not bucket_id:
        bucket = Bucket.objects.create(name=bucket_name)
        BucketMember.objects.create(bucket=bucket, user=sender, role='admin',invite_accepted = True)
        data['bucket'] = bucket.id
    else:
        bucket = check_bucket_membership(bucket_id, request.user, required_roles=['admin'])
        if isinstance(bucket, Response):
            return bucket

    serializer = ChannelSerializer(data=data)
    if serializer.is_valid():
        channel = serializer.save()

        ChannelMember.objects.create(channel=channel, user=sender)

        for member_email in channel_members:
            user = get_object_or_404(User, email=member_email)
            bucket_member = BucketMember.objects.get_or_create(bucket=bucket, user=user, defaults={'role': 'member', 'invite_accepted': False})
            if not bucket_member[0].invite_accepted:
                message_text = f"{sender.name} Has invited you to join {bucket.name}. Use following code to join code:{bucket.id}"
                create_direct_channel_and_send_message_helper(member_email,message_text,sender)
                ChannelMember.objects.create(channel=channel, user=user, invite_accepted=False)
            else:
                ChannelMember.objects.create(channel=channel, user=user, invite_accepted=True)

        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@token_required
@transaction.atomic
def add_channel_members(request,channel_id):
    """
    Add new members to a channel and its associated bucket.
    If users are not bucket members, they will be invited.
    """
    try:
        data = request.data.copy()
        existing_members = data.get('existing', [])
        new_members = data.get('new', [])
        
        channel = get_object_or_404(Channel, id=channel_id)
        bucket = get_object_or_404(Bucket, id=channel.bucket.id)
        sender = get_object_or_404(User, id=request.user)
        bucket_check = check_bucket_membership(bucket.id, request.user, required_roles=['admin'])
        if isinstance(bucket_check, Response):
            return bucket_check

        added_members = []
        for member_email in new_members:
            try:
                user = get_object_or_404(User, email=member_email)
                bucket_member, created = BucketMember.objects.get_or_create(
                    bucket=bucket,
                    user=user,
                    defaults={'role': 'member', 'invite_accepted': True}
                )
                channel_member = ChannelMember.objects.get_or_create(
                    channel=channel,
                    user=user,
                    invite_accepted=True
                )

                added_members.append({
                    'email': member_email,
                    'status': 'added'
                })

            except User.DoesNotExist:
                added_members.append({
                    'email': member_email,
                    'status': 'user_not_found'
                })
                continue

        for member_id in existing_members:
            try:
                print(f"Adding {member_id} to channel {channel.name}")
                user = get_object_or_404(User, id=member_id)
                if BucketMember.objects.filter(bucket=bucket, user=user, invite_accepted=True).exists():
                    ChannelMember.objects.get_or_create(
                        channel=channel,
                        user=user,
                        defaults={'invite_accepted': True}
                    )
                    added_members.append({
                        'email': user.email,
                        'status': 'added'
                    })

            except User.DoesNotExist:
                added_members.append({
                    'email': member_id,
                    'status': 'user_not_found'
                })
                continue

        return Response({
            'message': 'Members processed successfully',
            'results': added_members
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@token_required
def update_channel_member_role(request,member_id,channel_id):
    """Update the invite_accepted status of a channel member."""
    try:
        channel = get_object_or_404(Channel, id=channel_id)
        bucket = get_object_or_404(Bucket, id=channel.bucket.id)
        membership_check = check_bucket_membership(bucket.id, request.user, required_roles=['admin'])
        
        if isinstance(membership_check, Response):
            return membership_check
        
        member = get_object_or_404(BucketMember, bucket=bucket, user=member_id)
        role = request.data.get('status', member.role)
        if role not in ['member', 'admin']:
            return Response({'error': 'Invalid role'}, status=status.HTTP_400_BAD_REQUEST)
        member.role = role
        member.save()
        return Response({'message': 'Member status updated successfully'}, status=status.HTTP_200_OK)
    except ObjectDoesNotExist:
        return Response({'error': 'Member not found'}, status=status.HTTP_404_NOT_FOUND)
        


        


@api_view(['POST'])
@token_required
@transaction.atomic
def add_member_using_invite(request):
    """Accept an invite to a bucket and update invite_accepted for all related channels."""
    bucket_id = request.data.get("code")
    if not bucket_id:
        return Response({"error": "Code is required."}, status=status.HTTP_400_BAD_REQUEST)

    try:
        bucket = check_bucket_invite(bucket_id, request.user)
        if isinstance(bucket, Response):
            return bucket

        bucket_member = BucketMember.objects.get(bucket=bucket, user=request.user)
        bucket_member.invite_accepted = True
        bucket_member.save()

        ChannelMember.objects.filter(
            channel__bucket=bucket_id, user=request.user
        ).update(invite_accepted=True)

        return Response({"message": "Invite accepted successfully."}, status=status.HTTP_200_OK)

    except BucketMember.DoesNotExist:
        return Response({"error": "You are not invited to this bucket."}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
def delete_channel(request, channel_id):

    channel = get_object_or_404(Channel, id=channel_id)

    membership_check = check_channel_membership(channel_id, request.user)
    if membership_check:
        return membership_check

    bucket_check = check_bucket_membership(channel.bucket.id, request.user, required_roles=['admin'])
    if isinstance(bucket_check, Response):
        return bucket_check

    channel.delete()
    return Response({'message': 'Channel deleted'}, status=status.HTTP_204_NO_CONTENT)

@api_view(['GET'])
def list_channels(request, bucket_id):
    """Retrieve all channels in a bucket with the most recent message."""
    user = request.user

    if not Bucket.objects.filter(id=bucket_id, bucketmember__user=user).exists():
        return Response({"detail": "You are not a member of this bucket."}, status=403)

    latest_messages = Message.objects.filter(
        channel=OuterRef('id')
    ).order_by('-created_at').values('message_text')[:1]

    channels = Channel.objects.filter(bucket_id=bucket_id).annotate(
        latest_message=Subquery(latest_messages)
    )

    channel_list = []
    for channel in channels:
        channel_data = {
            "id": channel.id,
            "name": channel.name,
            "channel_type": channel.channel_type,
            "latest_message": channel.latest_message if channel.latest_message else "No messages yet",
        }
        channel_list.append(channel_data)

    return Response(channel_list)

@api_view(['POST'])
def add_channel_member(request):
    data = request.data
    channel_id = data.get('channel')

    if not channel_id:
        return Response({'error': 'Channel ID is required'}, status=status.HTTP_400_BAD_REQUEST)
    channel = get_object_or_404(Channel, id=channel_id)

    bucket_check = check_bucket_membership(channel.bucket.id, request.user, required_roles=['admin', 'moderator'])
    if isinstance(bucket_check, Response):
        return bucket_check

    serializer = ChannelMemberSerializer(data=data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
def remove_channel_member(request, channel_id, user_id):

    channel = get_object_or_404(Channel, id=channel_id)

    bucket_check = check_bucket_membership(channel.bucket.id, request.user, required_roles=['admin', 'moderator'])
    if isinstance(bucket_check, Response):
        return bucket_check

    member = get_object_or_404(ChannelMember, channel=channel, user_id=user_id)

    member.delete()
    return Response({'message': 'User removed from channel'}, status=status.HTTP_204_NO_CONTENT)

@api_view(['GET'])
@token_required
def fetch_messages(request, channel_id):
    """Fetches paginated messages for a channel along with reactions, supporting pagination
    and after_id filtering."""
    membership_check = check_channel_membership(channel_id, request.user)
    if membership_check:
        return membership_check

    page = int(request.GET.get('page', 1))
    page_limit = int(request.GET.get('page_limit', 10))
    after_id = request.GET.get('after_id')

    messages_queryset = Message.objects.filter(channel_id=channel_id).prefetch_related('messagereaction_set')

    if after_id:
        try:
            reference_message = Message.objects.get(id=after_id)
            messages_queryset = messages_queryset.filter(
                created_at__gt=reference_message.created_at
            )
        except Message.DoesNotExist:
            pass

    messages_queryset = messages_queryset.order_by("-created_at")

    paginator = Paginator(messages_queryset, page_limit)

    try:
        messages_page = paginator.get_page(page)
    except EmptyPage:
        messages_page = []
    except PageNotAnInteger:
        messages_page = paginator.get_page(1)

    serializer = MessageSerializer(messages_page, many=True)

    for message in serializer.data:
        message_obj = messages_queryset.get(id=message['id'])
        reactions = message_obj.messagereaction_set.all()
        message['reactions'] = [
            {
                "user_id": reaction.user.id,
                "user_name": reaction.user.name,
                "reaction": reaction.reaction
            }
            for reaction in reactions
        ]

    response_data = {
        'page': page,
        'page_limit': page_limit,
        'total_pages': paginator.num_pages,
        'total_messages': paginator.count,
        'messages': serializer.data
    }

    return Response(response_data)


@api_view(['POST'])
@token_required
@transaction.atomic
def send_messages(request, channel_id):

    membership_check = check_channel_membership(channel_id, request.user)
    if membership_check:
        return membership_check

    message_text = request.data.get('message_text')
    message_file = request.data.get('message_file')

    
    if not message_text:
        return Response({"error": "Message text is required."}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        sender = get_object_or_404(User, id=request.user)
        message = Message.objects.create(
            sender=sender,
            channel_id=channel_id,
            message_text=message_text,
            message_file=message_file
        )
        return Response({
            "message": "Message sent successfully.",
            "message_id": message.id
        }, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@token_required
def react_message(request, message_id):

    message = get_object_or_404(Message, id=message_id)
    membership_check = check_channel_membership(message.channel, request.user)
    if membership_check:
        return membership_check

    reaction = request.data.get('reaction')
    if not reaction:
        return Response({"error": "Reaction is required."}, status=status.HTTP_400_BAD_REQUEST)
    try:

        sender = get_object_or_404(User, id=request.user)
        reaction, created = MessageReaction.objects.update_or_create(
            message=message,
            user=sender,
            reaction=reaction,
        )

        if created:
            response_message = "Reaction added successfully."
        else:
            response_message = "Reaction updated successfully."

        return Response({"message": response_message}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def create_direct_channel_and_send_message_helper(email, message_text, sender):
    """Helper function to create a direct channel with a user and send a message."""
    try:
        recipient = User.objects.get(email=email)

        direct_channel = Channel.objects.filter(
            channel_type="direct",
            members__user__id__in=[sender.id, recipient.id]
        ).annotate(
            member_count=Count('members')
        ).filter(member_count=2).first()

        if not direct_channel:

            default_bucket, _ = Bucket.objects.get_or_create(name="Direct Messages")

            with transaction.atomic():
                direct_channel = Channel.objects.create(
                    name=f"Direct: {sender.name} & {recipient.name}",
                    channel_type="direct",
                    bucket=default_bucket
                )

                ChannelMember.objects.create(channel=direct_channel, user=sender,invite_accepted=True)
                ChannelMember.objects.create(channel=direct_channel, user=recipient,invite_accepted=True)

                BucketMember.objects.get_or_create(
                    bucket=default_bucket,
                    user=sender,
                    defaults={'role': 'member'}
                )
                BucketMember.objects.get_or_create(
                    bucket=default_bucket,
                    user=recipient,
                    defaults={'role': 'member'}
                )

        return {
            "message": "Message sent successfully.",
            "channel_id": direct_channel.id,
        }

    except User.DoesNotExist:
        raise ValueError("User with the provided email does not exist.")
    except Exception as e:
        raise ValueError(str(e))


@api_view(['POST'])
@token_required
def create_direct_channel_and_send_message(request):
    """API endpoint to create a direct channel with a user and send a message."""
    email = request.data.get('email')
    message_text = request.data.get('message')

    if not email or not message_text:
        return Response({"error": "Email and message are required."}, status=status.HTTP_400_BAD_REQUEST)

    try:
        sender = User.objects.get(id=request.user)
        result = create_direct_channel_and_send_message_helper(email, message_text, sender)
        return Response(result, status=status.HTTP_201_CREATED)
    except ValueError as e:
        return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


