from rest_framework import serializers
from .models import Task

class TaskSerializer(serializers.ModelSerializer):
    assigned_by_name = serializers.CharField(source='assigned_by.name', read_only=True, allow_null=True)
    assigned_to_name = serializers.CharField(source='assigned_to.name', read_only=True, allow_null=True)

    class Meta:
        model = Task
        fields = '__all__'

        fields = [
            'id', 'title', 'description', 'status', 'due_date',
            'created_at', 'updated_at', 'community',
            'assigned_by', 'assigned_to',
            'assigned_by_name', 'assigned_to_name'
        ]