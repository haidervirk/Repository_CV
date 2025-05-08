"""
ASGI config for django_config project.

It exposes the ASGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/4.2/howto/deployment/asgi/
"""

import os

from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
# import hatch_app.features.chat.routing

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "django_config.settings")
application = ProtocolTypeRouter({
    "http": get_asgi_application(),  # Handles normal HTTP requests
    # "websocket": AuthMiddlewareStack(  # Handles WebSockets
    #     URLRouter(
    #         hatch_app.features.chat.routing.websocket_urlpatterns  # Use correct path
    #     )
    # ),
})

