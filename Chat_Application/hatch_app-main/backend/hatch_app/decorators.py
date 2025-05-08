from firebase_admin import auth
from functools import wraps
from django.http import JsonResponse
from django.core.paginator import Paginator, EmptyPage, PageNotAnInteger

def verify_token(request):
    return {'user': request.META.get("HTTP_UID")}
    header_uid = request.META.get("HTTP_UID")
    token = request.META.get('HTTP_AUTHORIZATION').split(' ')[1]

    if not token or not header_uid:
        raise ValueError('Missing token or UID')
    
    try:
        decoded_token = auth.verify_id_token(token)
        uid = decoded_token['uid']
        
        if not uid or uid != header_uid:
            raise ValueError('Invalid UID')

        return decoded_token
    except:
        raise ValueError('Invalid token')

def token_required(view_func):
    @wraps(view_func)
    def _wrapped_view(request, *args, **kwargs):
        try:

            token_data = verify_token(request)
            request.user = token_data['user']
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=401)
        
        return view_func(request, *args, **kwargs)
    
    return _wrapped_view

def CustomPaginator(queryset, page, per_page):
    paginator = Paginator(queryset, per_page)
    try:
        paginated_data = paginator.page(page)
    except PageNotAnInteger:
        paginated_data = paginator.page(1)
    except EmptyPage:
        paginated_data = paginator.page(paginator.num_pages)
    
    return paginated_data