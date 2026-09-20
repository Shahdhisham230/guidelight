from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import User, FamilyMember, Alert, Location,DetectionDevice


@admin.register(User)
class CustomUserAdmin(UserAdmin):

    list_display = (
        'username',
        'email',
        'role',
        'is_active',
        'is_staff',
    )

    list_filter = (
        'role',
        'is_active',
        'is_staff',
    )

    search_fields = (
        'username',
        'email',
    )

    fieldsets = UserAdmin.fieldsets + (
        (
            'Guidelight Information',
            {
                'fields': (
                    'role',
                    'fcm_token',
                ),
            },
        ),
    )

    add_fieldsets = UserAdmin.add_fieldsets + (
        (
            'Guidelight Information',
            {
                'fields': (
                    'role',
                    'fcm_token',
                ),
            },
        ),
    )


@admin.register(FamilyMember)
class FamilyMemberAdmin(admin.ModelAdmin):

    list_display = (
        'name',
        'user',
        'device_user',
        'is_safe',
        'device_connected',
        'tracking_enabled',
        'last_update',
    )

    list_filter = (
        'is_safe',
        'device_connected',
        'tracking_enabled',
    )

    search_fields = (
        'name',
        'user__username',
        'device_user__username',
    )


@admin.register(Alert)
class AlertAdmin(admin.ModelAdmin):

    list_display = (
        'object_name',
        'alert_type',
        'user',
        'family_member',
        'distance',
        'created_at',
    )

    list_filter = (
        'alert_type',
        'created_at',
    )

    search_fields = (
        'object_name',
        'message',
        'user__username',
        'family_member__name',
    )


@admin.register(Location)
class LocationAdmin(admin.ModelAdmin):

    list_display = (
        'family_member',
        'latitude',
        'longitude',
        'created_at',
    )

    list_filter = (
        'created_at',
    )

    search_fields = (
        'family_member__name',
    )


@admin.register(DetectionDevice)
class DetectionDeviceAdmin(admin.ModelAdmin):

    list_display = (
        'family_member',
        'api_key',
        'is_active',
        'created_at',
    )

    list_filter = (
        'is_active',
    )

    search_fields = (
        'family_member__name',
    )