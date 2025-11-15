from rest_framework import serializers
from apps.energy.models import EnergyRecord, EnergyLevelChange
from apps.users.models import User


class TimeSlotSerializer(serializers.Serializer):
    """时间段序列化器"""
    start_hour = serializers.IntegerField(min_value=0, max_value=23)
    start_minute = serializers.IntegerField(min_value=0, max_value=59)
    end_hour = serializers.IntegerField(min_value=0, max_value=23)
    end_minute = serializers.IntegerField(min_value=0, max_value=59)


class EnergyRecordSerializer(serializers.ModelSerializer):
    """能量记录序列化器"""
    id = serializers.UUIDField(read_only=True)
    record_date = serializers.DateField()
    record_type = serializers.ChoiceField(choices=EnergyRecord.RecordType.choices)
    energy_level = serializers.ChoiceField(choices=EnergyRecord.EnergyLevel.choices)
    time_slots = TimeSlotSerializer(many=True)
    temporary_type = serializers.ChoiceField(
        choices=[('fastCharge', '快充模式'), ('lowPower', '低电量模式')],
        required=False,
        allow_null=True
    )
    original_energy_level = serializers.ChoiceField(
        choices=EnergyRecord.EnergyLevel.choices,
        required=False,
        allow_null=True
    )
    created_at = serializers.DateTimeField(read_only=True)
    updated_at = serializers.DateTimeField(read_only=True)
    
    class Meta:
        model = EnergyRecord
        fields = [
            'id', 'record_date', 'record_type', 'energy_level',
            'time_slots', 'temporary_type', 'original_energy_level',
            'created_at', 'updated_at'
        ]


class CurrentStatusSerializer(serializers.Serializer):
    """当前状态序列化器"""
    base_energy_level = serializers.ChoiceField(
        choices=EnergyRecord.EnergyLevel.choices,
        read_only=True
    )
    display_energy_level = serializers.ChoiceField(
        choices=EnergyRecord.EnergyLevel.choices,
        read_only=True
    )
    temporary_state = serializers.DictField(read_only=True)
    planned_state = serializers.DictField(read_only=True)


class PartnerStatusSerializer(serializers.Serializer):
    """伴侣状态序列化器"""
    energy_level = serializers.ChoiceField(
        choices=EnergyRecord.EnergyLevel.choices,
        read_only=True
    )
    records = serializers.DictField(read_only=True)

