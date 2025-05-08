from rest_framework import status
from rest_framework.decorators import api_view, parser_classes
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from .models import UploadedFile
from .serializers import UploadedFileSerializer

@api_view(['POST'])
@parser_classes([MultiPartParser, FormParser])
def upload_file(request):

    serializer = UploadedFileSerializer(data=request.data)
    
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
def get_file(request, file_id):

    try:
        file = UploadedFile.objects.get(id=file_id)
        serializer = UploadedFileSerializer(file)
        return Response(serializer.data)
    except UploadedFile.DoesNotExist:
        return Response(
            {"error": "File not found"}, 
            status=status.HTTP_404_NOT_FOUND
        )
