from django.urls import path
from apps.energy import views

urlpatterns = [
    # 当前状态相关（GET和PUT都支持）
    path('current-status/', views.current_energy_status, name='energy-current-status'),
    
    # 能量记录
    path('records/', views.get_energy_records, name='energy-records'),
    
    # 能量预规划
    path('plans/', views.get_energy_plans, name='energy-plans'),
    path('plans/create/', views.create_energy_plan, name='energy-plan-create'),
    
    # 临时状态
    path('temporary-state/', views.create_temporary_state, name='energy-temporary-create'),
    path('temporary-state/end/', views.end_temporary_state, name='energy-temporary-end'),
    
    # 伴侣状态
    path('partner-status/', views.get_partner_status, name='energy-partner-status'),
]
