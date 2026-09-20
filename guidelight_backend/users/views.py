from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.permissions import IsAuthenticated

from .serializers import (
    RegisterSerializer,
    LoginSerializer,
    FamilyMemberSerializer,
    AlertSerializer,
    LocationSerializer,
)

from .models import FamilyMember, Alert, Location,DetectionDevice


# =====================================================
# REGISTER
# =====================================================

class RegisterView(APIView):

    def post(self, request):

        serializer = RegisterSerializer(
            data=request.data
        )

        if serializer.is_valid():

            serializer.save()

            return Response(
                {
                    "message":
                    "User registered successfully"
                },
                status=status.HTTP_201_CREATED
            )

        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )


# =====================================================
# LOGIN
# =====================================================

class LoginView(APIView):

    def post(self, request):

        serializer = LoginSerializer(
            data=request.data
        )

        if serializer.is_valid():

            user = serializer.validated_data['user']

            refresh = RefreshToken.for_user(user)

            return Response(
                {
                    "refresh": str(refresh),
                    "access": str(refresh.access_token),
                    "username": user.username,
                    "email": user.email
                },
                status=status.HTTP_200_OK
            )

        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )


# =====================================================
# PROFILE
# =====================================================

class ProfileView(APIView):

    permission_classes = [IsAuthenticated]

    def get(self, request):

        return Response(
            {
                "username": request.user.username,
                "email": request.user.email,
            },
            status=status.HTTP_200_OK
        )


# =====================================================
# FAMILY MEMBERS
# =====================================================

class FamilyMemberView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        members = FamilyMember.objects.filter(
            user=request.user
        ).order_by('-last_update')

        serializer = FamilyMemberSerializer(
            members,
            many=True
        )

        return Response(
            serializer.data,
            status=status.HTTP_200_OK
        )

# =====================================================
# ALERTS
# =====================================================

class AlertView(APIView):

    permission_classes = [IsAuthenticated]

    # -------------------------------------------------
    # GET ALERTS
    # -------------------------------------------------

    def get(self, request):

        alerts = Alert.objects.filter(
            user=request.user
        ).order_by('-created_at')

        serializer = AlertSerializer(
            alerts,
            many=True
        )

        return Response(
            serializer.data,
            status=status.HTTP_200_OK
        )

    # -------------------------------------------------
    # CREATE ALERT
    # -------------------------------------------------

    def post(self, request):

        alert_type = request.data.get(
            'alert_type',
            'info'
        )

        object_name = request.data.get(
            'object_name',
            ''
        )

        distance = request.data.get(
            'distance'
        )

        message = request.data.get(
            'message',
            'New alert'
        )

        family_member_id = request.data.get(
            'family_member'
        )

        family_member = None

        # =============================================
        # CASE 1:
        # Patient / Family Member
        # =============================================

        try:

            family_member = FamilyMember.objects.get(
                device_user=request.user
            )

        except FamilyMember.DoesNotExist:

            # =========================================
            # CASE 2:
            # Parent
            # =========================================

            if family_member_id:

                try:

                    family_member = FamilyMember.objects.get(
                        id=family_member_id,
                        user=request.user
                    )

                except FamilyMember.DoesNotExist:

                    return Response(
                        {
                            'error':
                            'Family member not found'
                        },
                        status=status.HTTP_404_NOT_FOUND
                    )

            else:

                family_member = FamilyMember.objects.filter(
                    user=request.user
                ).first()

        # =============================================
        # No Family Member
        # =============================================

        if not family_member:

            return Response(
                {
                    'error':
                    'No family member found'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # =============================================
        # Alert belongs to Parent
        # =============================================

        alert_owner = family_member.user

        # =============================================
        # Create Alert
        # =============================================

        alert = Alert.objects.create(
            user=alert_owner,
            family_member=family_member,
            alert_type=alert_type,
            object_name=object_name,
            distance=distance,
            message=message,
        )

        # =============================================
        # Push Notification
        # =============================================

        if alert_owner.fcm_token:

            try:

                from .firebase_utils import (
                    send_push_notification
                )

                send_push_notification(
                    token=alert_owner.fcm_token,
                    title="New Alert",
                    body=message,
                )

            except Exception as e:

                print(
                    "Push notification failed:",
                    e
                )

        # =============================================
        # Response
        # =============================================

        serializer = AlertSerializer(
            alert
        )

        return Response(
            serializer.data,
            status=status.HTTP_201_CREATED
        )

class DeviceAlertView(APIView):

    permission_classes = []

    def post(self, request):

        device_key = request.headers.get(
            'X-Device-Key'
        )

        if not device_key:

            return Response(
                {
                    'error':
                    'X-Device-Key header is required'
                },
                status=status.HTTP_401_UNAUTHORIZED
            )

        try:

            device = DetectionDevice.objects.select_related(
                'family_member__user'
            ).get(
                api_key=device_key,
                is_active=True
            )

        except DetectionDevice.DoesNotExist:

            return Response(
                {
                    'error':
                    'Invalid or inactive device key'
                },
                status=status.HTTP_401_UNAUTHORIZED
            )

        family_member = device.family_member

        alert_owner = family_member.user

        alert_type = request.data.get(
            'alert_type',
            'info'
        )

        object_name = request.data.get(
            'object_name',
            ''
        )

        distance = request.data.get(
            'distance'
        )

        message = request.data.get(
            'message',
            'New alert'
        )

        alert = Alert.objects.create(
            user=alert_owner,
            family_member=family_member,
            alert_type=alert_type,
            object_name=object_name,
            distance=distance,
            message=message,
        )

        serializer = AlertSerializer(
            alert
        )

        return Response(
            serializer.data,
            status=status.HTTP_201_CREATED
        )
# =====================================================
# LOCATIONS
# =====================================================

class LocationView(APIView):

    permission_classes = [IsAuthenticated]

    # -------------------------------------------------
    # GET LOCATIONS
    # -------------------------------------------------

    def get(self, request):

        locations = Location.objects.filter(
            family_member__user=request.user
        ).order_by('-created_at')

        serializer = LocationSerializer(
            locations,
            many=True
        )

        return Response(
            serializer.data,
            status=status.HTTP_200_OK
        )

    # -------------------------------------------------
    # CREATE LOCATION
    # -------------------------------------------------

    def post(self, request):

        latitude = request.data.get(
            'latitude'
        )

        longitude = request.data.get(
            'longitude'
        )

        # =============================================
        # Required fields
        # =============================================

        if latitude is None or longitude is None:

            return Response(
                {
                    'error':
                    'latitude and longitude are required'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # =============================================
        # Convert to numbers
        # =============================================

        try:

            latitude = float(latitude)
            longitude = float(longitude)

        except (TypeError, ValueError):

            return Response(
                {
                    'error':
                    'latitude and longitude must be valid numbers.'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # =============================================
        # Latitude validation
        # =============================================

        if not (-90 <= latitude <= 90):

            return Response(
                {
                    'error':
                    'latitude must be between -90 and 90.'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # =============================================
        # Longitude validation
        # =============================================

        if not (-180 <= longitude <= 180):

            return Response(
                {
                    'error':
                    'longitude must be between -180 and 180.'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # =============================================
        # Find Patient / Family Member
        # =============================================

        try:

            family_member = FamilyMember.objects.get(
                device_user=request.user
            )

        except FamilyMember.DoesNotExist:

            return Response(
                {
                    'error':
                    'This account is not linked to a family member.'
                },
                status=status.HTTP_403_FORBIDDEN
            )

        # =============================================
        # Check Tracking
        # =============================================

        location = Location.objects.create(
    family_member=family_member,
    latitude=latitude,
    longitude=longitude
)

        # =============================================
        # Save Location
        # =============================================

        location = Location.objects.create(
            family_member=family_member,
            latitude=latitude,
            longitude=longitude
        )

        # =============================================
        # Device Connected
        # =============================================

        family_member.device_connected = True

        family_member.save()

        serializer = LocationSerializer(
            location
        )

        return Response(
            serializer.data,
            status=status.HTTP_201_CREATED
        )


# =====================================================
# USER ROLE
# =====================================================

class UserRoleView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(
            {
                'role': request.user.role,
                'is_family_member': request.user.role == 'family_member',
            },
            status=status.HTTP_200_OK
        )

# =====================================================
# UPDATE FCM TOKEN
# =====================================================

class UpdateFCMTokenView(APIView):

    permission_classes = [IsAuthenticated]

    def post(self, request):

        token = request.data.get(
            'fcm_token'
        )

        if not token:

            return Response(
                {
                    'error':
                    'fcm_token is required'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        request.user.fcm_token = token

        request.user.save()

        return Response(
            {
                'message':
                'FCM token updated successfully'
            },
            status=status.HTTP_200_OK
        )