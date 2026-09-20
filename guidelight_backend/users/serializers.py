from rest_framework import serializers

from .models import User, FamilyMember, Alert, Location , DetectionDevice


class RegisterSerializer(serializers.ModelSerializer):

    password = serializers.CharField(
        write_only=True,
        min_length=6
    )

    role = serializers.ChoiceField(
        choices=User.ROLE_CHOICES
    )

    parent_email = serializers.EmailField(
        write_only=True,
        required=False,
        allow_blank=True
    )

    class Meta:
        model = User
        fields = [
            'username',
            'email',
            'password',
            'role',
            'parent_email',
        ]

    def validate(self, attrs):

        role = attrs.get('role')
        parent_email = attrs.get('parent_email')

        if role == 'family_member':

            if not parent_email:
                raise serializers.ValidationError({
                    'parent_email':
                        'Parent email is required for a family member.'
                })

            try:
                parent = User.objects.get(
                    email=parent_email
                )

            except User.DoesNotExist:
                raise serializers.ValidationError({
                    'parent_email':
                        'No parent account found with this email.'
                })

            if parent.role != 'parent':
                raise serializers.ValidationError({
                    'parent_email':
                        'This email does not belong to a parent account.'
                })

            attrs['parent'] = parent

        return attrs

    def create(self, validated_data):

        password = validated_data.pop('password')

        parent = validated_data.pop(
            'parent',
            None
        )

        # parent_email is only used for linking
        validated_data.pop(
            'parent_email',
            None
        )

        user = User.objects.create_user(
            password=password,
            **validated_data
        )

        # Create FamilyMember relationship
        if user.role == 'family_member':

            family_member = FamilyMember.objects.create(
                user=parent,
                device_user=user,
                name=user.username,
            )

            DetectionDevice.objects.create(
                family_member=family_member
            )

        return user


class LoginSerializer(serializers.Serializer):

    email = serializers.EmailField()

    password = serializers.CharField(
        write_only=True
    )

    def validate(self, data):

        email = data.get('email')
        password = data.get('password')

        try:
            user = User.objects.get(
                email=email
            )

        except User.DoesNotExist:

            raise serializers.ValidationError(
                "Invalid email or password."
            )

        if not user.check_password(password):

            raise serializers.ValidationError(
                "Invalid email or password."
            )

        data['user'] = user

        return data


class FamilyMemberSerializer(serializers.ModelSerializer):

    class Meta:
        model = FamilyMember

        fields = [
            'id',
            'name',
            'is_safe',
            'device_connected',
            'last_update',
        ]


class AlertSerializer(serializers.ModelSerializer):

    class Meta:
        model = Alert

        fields = [
            'id',
            'alert_type',
            'object_name',
            'distance',
            'message',
            'created_at',
        ]


class LocationSerializer(serializers.ModelSerializer):

    class Meta:
        model = Location

        fields = [
            'id',
            'family_member',
            'latitude',
            'longitude',
            'created_at',
        ]