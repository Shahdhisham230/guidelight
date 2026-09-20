from django.urls import path

from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    DeviceAlertView,
    RegisterView,
    LoginView,
    ProfileView,
    FamilyMemberView,
    AlertView,
    LocationView,
    UserRoleView,
    UpdateFCMTokenView,
)

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path(
        'token/refresh/',
        TokenRefreshView.as_view(),
        name='token-refresh'
    ),
    path(
        'profile/',
        ProfileView.as_view(),
        name='profile'
    ),
    path(
        'family-members/',
        FamilyMemberView.as_view(),
        name='family-members'
    ),
    path(
        'alerts/',
        AlertView.as_view(),
        name='alerts'
    ),
    path(
        'locations/',
        LocationView.as_view(),
        name='locations'
    ),
    path(
        'role/',
        UserRoleView.as_view(),
        name='user-role'
    ),

    path(
        'update-fcm-token/',   
         UpdateFCMTokenView.as_view(), 
         name='update-fcm-token'),

    path(
        'device-alert/',
         DeviceAlertView.as_view(),
         name='device-alert'
),
]