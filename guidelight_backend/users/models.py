
from django.contrib.auth.models import AbstractUser
from django.db import models
import secrets



class User(AbstractUser):

    ROLE_CHOICES = [
        ('parent', 'Parent'),
        ('family_member', 'Family Member'),
    ]

    role = models.CharField(
        max_length=20,
        choices=ROLE_CHOICES,
        default='parent'
    )

    fcm_token = models.CharField(
        max_length=255,
        blank=True,
        null=True
    )

class FamilyMember(models.Model):
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='family_members'
    )

    device_user = models.OneToOneField(
    User,
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    related_name='family_member_device'
    )

    name = models.CharField(max_length=100)

    is_safe = models.BooleanField(default=True)

    device_connected = models.BooleanField(default=False)

    tracking_enabled = models.BooleanField(default=False)

    last_update = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name


class DetectionDevice(models.Model):

    family_member = models.OneToOneField(
        FamilyMember,
        on_delete=models.CASCADE,
        related_name='detection_device'
    )

    api_key = models.CharField(
        max_length=64,
        unique=True,
        default=secrets.token_hex,
        editable=False
    )

    is_active = models.BooleanField(
        default=True
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    def __str__(self):
        return f'{self.family_member.name} - Detection Device'

class Alert(models.Model):

    ALERT_TYPES = [
        ('danger', 'Danger'),
        ('warning', 'Warning'),
        ('info', 'Information'),
        ('assistance', 'Assistance'),
    ]

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='alerts'
    )

    family_member = models.ForeignKey(
        FamilyMember,
        on_delete=models.CASCADE,
        related_name='alerts'
    )

    alert_type = models.CharField(
        max_length=20,
        choices=ALERT_TYPES
    )

    object_name = models.CharField(
        max_length=100
    )

    distance = models.FloatField(
        null=True,
        blank=True
    )

    message = models.TextField()

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    def __str__(self):
        return f'{self.object_name} - {self.alert_type}'


class Location(models.Model):

    family_member = models.ForeignKey(
        FamilyMember,
        on_delete=models.CASCADE,
        related_name='locations'
    )

    latitude = models.FloatField()

    longitude = models.FloatField()

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    def __str__(self):
        return (
            f'{self.family_member.name} - '
            f'{self.latitude}, {self.longitude}'
        )

