from django.db import models
from hatch_app.features.chat.models import Bucket
from hatch_app.features.user.models import User

class Task(models.Model):
    """Represents a task assigned within a community (bucket)"""
    community = models.ForeignKey(Bucket, on_delete=models.CASCADE)
    assigned_by = models.ForeignKey(User, related_name="assigned_by", on_delete=models.SET_NULL, null=True)
    assigned_to = models.ForeignKey(User, related_name="assigned_to", on_delete=models.SET_NULL, null=True)
    title = models.CharField(max_length=255)
    description = models.TextField(null=True, blank=True)
    status = models.CharField(max_length=50) 
    due_date = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title
    
class Notification(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    task = models.ForeignKey(Task, on_delete=models.SET_NULL, null=True, blank=True)  # Changed to SET_NULL
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        if self.task:
            return f"Notification for {self.user.name} about {self.task.title}"
        return f"Notification for {self.user.name}"
