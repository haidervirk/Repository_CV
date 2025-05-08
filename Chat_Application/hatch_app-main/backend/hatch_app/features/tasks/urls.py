from django.urls import path
from . import views

urlpatterns = [
    path('get_all_tasks/', views.get_all_communities_task, name='get-all-communities-tasks'),
    path('create/', views.create_task, name='create-task'),
    path('get/<str:task_id>/', views.get_task, name='get-task'),
    path('fetch_notifications', views.fetch_notifications_list, name='fetch-notifications-list'),
    path('get_community_settings/<str:community_id>/', views.get_community_settings, name='get-community-settings'),
    path('update/<str:task_id>/assigned_by/', views.update_task_assigned_by, name='update-task-assigned-by'),
    path('update/<str:task_id>/assigned_to/', views.update_task_assigned_to, name='update-task-assigned-to'),
    path('delete/<str:task_id>/', views.delete_task, name='delete-task'),
]
