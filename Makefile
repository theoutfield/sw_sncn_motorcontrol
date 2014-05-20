# This variable should contain a space separated list of all
# the directories containing buildable applications (usually
# prefixed with the app_ prefix)
#
# If the variable is set to "all" then all directories that start with app_
# are built.

BUILD_SUBDIRS = demo_bldc-homing demo_bldc-position-control demo_bldc-torque-control demo_bldc-velocity-control demo_brushed-dc-position-control demo_brushed-dc-velocity-control demo_ethercat-motorcontrol

XMOS_MAKE_PATH ?= ..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.toplevel
