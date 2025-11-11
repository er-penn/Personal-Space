from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.energy import views

router = DefaultRouter()
# router.register(r'records', views.EnergyRecordViewSet, basename='energy-record')

urlpatterns = [
    path('current/', views.get_current_energy_status, name='energy-current'),
    path('current/update/', views.update_current_energy_level, name='energy-update'),
    path('temporary/', views.create_temporary_state, name='energy-temporary'),
    path('temporary/end/', views.end_temporary_state, name='energy-temporary-end'),
    path('plans/', views.create_energy_plan, name='energy-plan-create'),
    path('records/', views.get_energy_records, name='energy-records'),
]

