from django.urls import path
from . import views

urlpatterns = [

    path('buckets/', views.list_buckets, name='list-buckets'),
    path('buckets/create/', views.create_bucket, name='create-bucket'),
    path('buckets/<int:bucket_id>/delete/', views.delete_bucket, name='delete-bucket'),

    path('buckets/members/add/', views.add_bucket_member, name='add-bucket-member'),
    path('buckets/<int:bucket_id>/members/<int:user_id>/remove/', views.remove_bucket_member, name='remove-bucket-member'),
    path('buckets/<int:bucket_id>/members/', views.list_bucket_members, name='list-bucket-members'),

    path('buckets/<int:bucket_id>/channels/', views.list_channels, name='list-channels'),
    path('channels/create/', views.create_channel, name='create-channel'),
    path('channels/invite/', views.add_member_using_invite, name='add-member-using-invite'),
    path('channels/<int:channel_id>/delete/', views.delete_channel, name='delete-channel'),

    path('channels/members/add/', views.add_channel_member, name='add-channel-member'),
    path('channels/<int:channel_id>/members/<int:user_id>/remove/', views.remove_channel_member, name='remove-channel-member'),
    path('channels/<int:channel_id>/settings/', views.get_channel_settings, name='get-channel-settings'),
    path('channels/<int:channel_id>/members/add/', views.add_channel_members, name='add-channel-members'),
    path('channels/<int:channel_id>/members/<str:member_id>/role/', views.update_channel_member_role, name='update-channel-member-role'),

    path('channels/<int:channel_id>/messages/', views.fetch_messages, name='fetch-messages'),

    path('direct-messages/recent/', views.get_chat_messages, name='get-chat-messages'),
    path('direct-messages/communities/', views.get_community_messages, name='get-community_messages'),
    path('direct-messages/send/', views.create_direct_channel_and_send_message, name='create-direct-channel-and-send-message'),
    path('direct-messages/<int:channel_id>/send/', views.send_messages, name='send-messages'),
    path('direct-messages/<int:message_id>/react/', views.react_message, name='react-message'),

    path('chatbot/message/', views.send_chatbot_message, name='send-chatbot-message'),
]
