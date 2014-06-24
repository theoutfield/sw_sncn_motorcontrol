# This variable should contain a space separated list of all
# the directories containing buildable applications (usually
# prefixed with the app_ prefix)
#
# If the variable is set to "all" then all directories that start with app_
# are built.

BUILD_SUBDIRS = app_demo_bldc_homing app_demo_bldc_velocity_control app_demo_bldc_torque_control app_demo_bldc_position_control app_demo_brushed_dc_position_control app_demo_brushed_dc_velocity_control app_demo_ethercat_motorcontrol app_demo_sin_commutation

XMOS_MAKE_PATH ?= ..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.toplevel
