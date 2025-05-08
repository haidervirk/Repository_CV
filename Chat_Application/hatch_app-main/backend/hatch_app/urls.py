from django.contrib import admin
from django.urls import path, include
from .features.storage import views

urlpatterns = [
    path('chat/', include('hatch_app.features.chat.urls')),
    path('task/', include('hatch_app.features.tasks.urls')),
    path('user/', include('hatch_app.features.user.urls')),
    path('storage/upload/', views.upload_file, name='upload_file'),
    path('storage/<int:file_id>/', views.get_file, name='get_file'),
]
