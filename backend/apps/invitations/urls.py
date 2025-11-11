from django.urls import path
from rest_framework.routers import DefaultRouter
from apps.invitations import views

router = DefaultRouter()
# router.register(r'', views.InvitationViewSet, basename='invitation')

urlpatterns = [
    path('', views.create_invitation, name='invitation-create'),
    path('list/', views.list_invitations, name='invitation-list'),
    path('<uuid:invitation_id>/respond/', views.respond_invitation, name='invitation-respond'),
]

