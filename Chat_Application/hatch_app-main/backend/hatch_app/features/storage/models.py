from django.db import models

class UploadedFile(models.Model):
    file = models.FileField(upload_to='uploads/')
    file_name = models.CharField(max_length=255)
    file_type = models.CharField(max_length=100)
    uploaded_at = models.DateTimeField(auto_now_add=True)
    bucket = models.CharField(max_length=255, blank=True, null=True)
    
    def __str__(self):
        return self.file_name