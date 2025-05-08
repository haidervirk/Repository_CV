from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Task,Notification
from .serializers import TaskSerializer
from datetime import datetime, timedelta
from django.utils import timezone
from django.db.models import Q, Count
from django.db.models.functions import TruncDate
from django.utils import timezone
from django.utils.timezone import make_aware
from datetime import datetime
from hatch_app.decorators import token_required
from hatch_app.features.chat.models import Bucket,BucketMember,Message,Channel
from hatch_app.features.user.models import User
from django.shortcuts import get_object_or_404
from django.db.models import OuterRef, Subquery, Count

@api_view(['GET'])
@token_required
def get_all_communities_task(request):
    """
    Get all incomplete tasks organized by communities and due in next 7 days.
    Returns:
    - Tasks assigned by me
    - Tasks assigned to me
    - Tasks counts per community
    - Next 7 days task analytics
    """
    try:
        user = request.user
        today = timezone.now()
        next_week = today + timedelta(days=7)

        communities = Bucket.objects.filter(
            bucketmember__user=user,
            bucketmember__invite_accepted=True
        ).distinct()

        if not communities.exists():
            return Response({
                'communities': [],
                'overall_stats': {
                    'total_communities': 0,
                    'total_upcoming_tasks': 0,
                    'tasks_by_status': {'open': 0, 'in_progress': 0},
                    'daily_task_counts': {}
                }
            })

        response_data = []
        
        for community in communities:
            tasks = Task.objects.filter(
                community=community
            ).filter(
                Q(assigned_to=user) | Q(assigned_by=user)
            )
            
            community_data = {
                'community_id': community.id,
                'community_name': community.name,
                'total_tasks': tasks.count(),
                'tasks': [{
                    'task_id': task.id,
                    'title': task.title,
                    'due_date': task.due_date,
                    'status': task.status,
                    'assigned_by': task.assigned_by.id if task.assigned_by else None,
                } for task in tasks]
            }
            
            response_data.append(community_data)

        all_upcoming_tasks = Task.objects.filter(
            community__in=communities,
            status__in=['open', 'in-progress'],
            due_date__range=[today, next_week]
        ).filter(
            Q(assigned_to=user) | Q(assigned_by=user)
        )

        daily_task_counts = {
            (today + timedelta(days=i)).date().isoformat(): 
            all_upcoming_tasks.filter(
                due_date__date=(today + timedelta(days=i)).date()
            ).count() 
            for i in range(8)
        }

        overall_stats = {
            'total_communities': len(response_data),
            'total_upcoming_tasks': all_upcoming_tasks.count(),
            'tasks_by_status': {
                'open': all_upcoming_tasks.filter(status='open').count(),
                'in_progress': all_upcoming_tasks.filter(status='in-progress').count()
            },
            'daily_task_counts': daily_task_counts
        }

        return Response({
            'communities': response_data,
            'overall_stats': overall_stats
        })

    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    
@api_view(['POST'])
@token_required
def create_task(request):
    """
    Create a new task with validations:
    - Both creator and assignee must be community members
    - Due date must be in the future
    """
    try:
        community_id = request.data.get('community')
        assigned_to_id = request.data.get('assigned_to')
        title = request.data.get('title')
        description = request.data.get('description')
        due_date_str = request.data.get('due_date')

        if not all([community_id, assigned_to_id, title, due_date_str]):
            return Response({
                'error': 'Missing required fields'
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            community = Bucket.objects.get(id=community_id)
        except Bucket.DoesNotExist:
            return Response({
                'error': 'Community not found'
            }, status=status.HTTP_404_NOT_FOUND)

        creator = request.user
        creator_member = BucketMember.objects.filter(
            user_id=creator,
            bucket=community,
            invite_accepted=True
        ).exists()
        
        assignee_member = BucketMember.objects.filter(
            user_id=assigned_to_id,
            bucket=community,
            invite_accepted=True
        ).exists()

        if not (creator_member and assignee_member):
            return Response({
                'error': 'Both users must be members of the community'
            }, status=status.HTTP_403_FORBIDDEN)

        try:
            due_date = datetime.strptime(due_date_str, "%d/%m/%Y")
            due_date = make_aware(due_date)
            if due_date <= timezone.now():
                return Response({
                    'error': 'Due date must be in the future'
                }, status=status.HTTP_400_BAD_REQUEST)
        except ValueError:
            return Response({
                'error': 'Invalid date format. Expected DD/MM/YYYY'
            }, status=status.HTTP_400_BAD_REQUEST)

        sender = get_object_or_404(User, id=request.user)
        task = Task.objects.create(
            community=community,
            assigned_by=sender,
            assigned_to_id=assigned_to_id,
            title=title,
            description=description,
            status='open',
            due_date=due_date
        )
        notification = Notification.objects.create(
            user_id=assigned_to_id,
            task=task,
            message=f"You have been assigned a new task: {title}"
        )
        rec = User.objects.get(id=assigned_to_id)
        notification = Notification.objects.create(
            user_id=request.user,
            task=task,
            message=f"You have assigned a new task to {rec.name}: {title}"
        )

        serializer = TaskSerializer(task)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    except Exception as e:
        print(e)
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@token_required
def get_task(request, task_id):

    try:
        task = get_object_or_404(Task, id=task_id)
        user = request.user

        if user != task.assigned_to_id and user != task.assigned_by_id:
            return Response(
                {'error': 'You do not have permission to view this task'},
                status=status.HTTP_403_FORBIDDEN
            )
        serializer = TaskSerializer(task)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    

@api_view(['POST'])
@token_required
def update_task_assigned_by(request, task_id):
    """
    Updates a task's details if the requester is the:
    - original assigner
    - both users belong to the same community.
    """
    try:
        task = get_object_or_404(Task, id=task_id)
        user = request.user

        if user != task.assigned_by_id:
            return Response(
                {'error': 'You do not have permission to update this task'},
                status=status.HTTP_403_FORBIDDEN
            )

        community_id = request.data.get('community')
        assigned_to_id = request.data.get('assigned_to')
        title = request.data.get('title')
        description = request.data.get('description')
        due_date_str = request.data.get('due_date')
        task_status = request.data.get('status')

        if not all([community_id, assigned_to_id, title, due_date_str]):
            return Response({
                'error': 'Missing required fields'
            }, status=status.HTTP_400_BAD_REQUEST)
        if task_status not in ['open', 'in-progress', 'completed']:
            return Response({
                'error': 'Invalid status'
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            community = Bucket.objects.get(id=community_id)
        except Bucket.DoesNotExist:
            return Response({
                'error': 'Community not found'
            }, status=status.HTTP_404_NOT_FOUND)

        creator = request.user
        creator_member = BucketMember.objects.filter(
            user_id=creator,
            bucket=community,
            invite_accepted=True
        ).exists()
        
        assignee_member = BucketMember.objects.filter(
            user_id=assigned_to_id,
            bucket=community,
            invite_accepted=True
        ).exists()

        if not (creator_member and assignee_member):
            return Response({
                'error': 'Both users must be members of the community'
            }, status=status.HTTP_403_FORBIDDEN)

        try:
            due_date = datetime.strptime(due_date_str, "%d/%m/%Y")
            due_date = make_aware(due_date)
            if due_date <= timezone.now():
                return Response({
                    'error': 'Due date must be in the future'
                }, status=status.HTTP_400_BAD_REQUEST)
        except ValueError:
            return Response({
                'error': 'Invalid date format. Expected DD/MM/YYYY'
            }, status=status.HTTP_400_BAD_REQUEST)

        rec = User.objects.get(id=assigned_to_id)
        task.assigned_to_id = assigned_to_id
        task.community = community
        task.assigned_by_id = request.user
        task.title = title
        task.description = description
        task.status = task_status
        task.due_date = due_date
        task.save()
        notification = Notification.objects.create(
            user_id=assigned_to_id,
            task=task,
            message=f"The task {title} has been updated. You have been assigned to it."
        )
        rec = User.objects.get(id=assigned_to_id)
        notification = Notification.objects.create(
            user_id=request.user,
            task=task,
            message=f"You have updated the task to {rec.name}: {title}"
        )
        serializer = TaskSerializer(task)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    

@api_view(['POST'])
@token_required
def update_task_assigned_to(request, task_id):
    """
    - Updates the status of a task if the requester is the assigned user
    - Sends notifications to both users involved.
    """
    try:
        task = get_object_or_404(Task, id=task_id)
        user = request.user

        if user != task.assigned_to_id:
            return Response(
                {'error': 'You do not have permission to update this task'},
                status=status.HTTP_403_FORBIDDEN
            )
        task_status = request.data.get('status')

        if not all([task_status]):
            return Response({
                'error': 'Missing required fields'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if task_status not in ['open', 'in-progress', 'completed']:
            return Response({
                'error': 'Invalid status'
            }, status=status.HTTP_400_BAD_REQUEST)

        task.status = task_status
        notification = Notification.objects.create(
            user_id=request.user,
            task=task,
            message=f"You have updated the status of the task: {task.title} to {status}"
        )
        rec = User.objects.get(id=task.assigned_by_id)
        notification = Notification.objects.create(
            user_id=task.assigned_by_id,
            task=task,
            message=f"The task {task.title} status has been updated to {status}"
        )
        serializer = TaskSerializer(task)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        
@api_view(['DELETE'])
@token_required
def delete_task(request,task_id):

    try:
        task = get_object_or_404(Task, id=task_id)
        user = request.user
        sender = get_object_or_404(User, id=request.user)

        if user != task.assigned_by_id:
            return Response(
                {'error': 'You do not have permission to delete this task'},
                status=status.HTTP_403_FORBIDDEN
            )
        task_title = task.title
        assigned_to = task.assigned_to

        task.delete()

        if assigned_to:
            Notification.objects.create(
                user=assigned_to,
                task=None,  
                message=f"Task '{task_title}' has been deleted by {sender.name}"
            )
        Notification.objects.create(
                
                user_id=user,
                task=None,  
                message=f"Task '{task_title}' has been deleted"
            )

        return Response(
            {
                'success': True,
                'message': f"Task '{task_title}' deleted successfully"
            },
            status=status.HTTP_200_OK
        )
    except Exception as e:

        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@token_required
def fetch_notifications_list(request):
    user = request.user
    try:
        notifications = Notification.objects.filter(user=user).order_by('-created_at')
        notification_list = []
        for notification in notifications:
            task = notification.task
            notification_data = {
                'id': notification.id,
                'task_id': None,
                'task_title': None,
                'message': notification.message,
                'created_at': notification.created_at.isoformat()
            }
            if task:
                notification_data.update({
                    'task_id': task.id,
                    'task_title': task.title
                })
            notification_list.append(notification_data)
        return Response(notification_list, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@token_required
def get_community_settings(request, community_id):

    user = request.user
    try:
        community = get_object_or_404(Bucket, id=community_id)
        if not BucketMember.objects.filter(
            user=user, 
            bucket=community, 
            invite_accepted=True
        ).exists():
            return Response(
                {'error': 'You are not a member of this community'}, 
                status=status.HTTP_403_FORBIDDEN
            )

        direct_channels = Channel.objects.filter(
            members__user = user,
            bucket=community,
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

        message_list = [{
            'channel_id': channel.id,
            'channel_name': channel.name,
            'latest_message': channel.latest_message,
            'latest_sender': channel.latest_sender,
            'latest_sender_id': channel.latest_sender_id,
            'timestamp': channel.latest_timestamp
        } for channel in direct_channels_with_messages]

        tasks = Task.objects.filter(
            community=community
        ).filter(
            Q(assigned_to=user) | Q(assigned_by=user)
        ).order_by('-due_date')

        tasks_data = [{
            'id': task.id,
            'title': task.title,
            'description': task.description,
            'status': task.status,
            'due_date': task.due_date.isoformat() if task.due_date else None,
            'assigned_by': task.assigned_by.name if task.assigned_by else None,
            'assigned_to': task.assigned_to.name if task.assigned_to else None,
        } for task in tasks]

        response_data = {
            'community_id': community.id,
            'community_name': community.name,
            'channels': message_list,
            'tasks': tasks_data,
        }

        return Response(response_data, status=status.HTTP_200_OK)

    except Bucket.DoesNotExist:
        return Response(
            {'error': 'Community not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )