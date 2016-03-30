# Copyright (C) 2016 Christian Ludwig <chrissicool@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Check a number of conditions when _not_ to use prebuilts.
# - CI builds (e.g. Jenkins)
# - "user" build variant
prebuilts_criteria := $(JENKINS_URL)$(filter user,$(TARGET_BUILD_VARIANT))
ifneq ($(prebuilts_criteria),)
ANDROID_NO_PREBUILT_PATHS := $(TOP)
endif # prebuilts_criteria
prebuilts_criteria :=

PREBUILTS_ROOT := $(call my-dir)
PREBUILTS_BINARIES := $(PREBUILTS_ROOT)
PREBUILTS_TARGET_BINARIES := $(PREBUILTS_BINARIES)/target/$(TARGET_DEVICE)/$(TARGET_BUILD_VARIANT)
PREBUILTS_HOST_BINARIES := $(PREBUILTS_BINARIES)/host/$(HOST_PREBUILT_TAG)

# Save a variable that contains a build system's makefile path.
# Adjust the path to the makefile to $(PREBUILTS_ROOT).
# The prebuilt makefile can use the original one as PREBUILTS_ORIGINAL_$(1).
#
# Parameters:
#   $(1):	Makefile to adjust, e.g. BUILD_EXECUTABLE
define save_var
    $(eval PREBUILTS_ORIGINAL_$(1) := $($(1)))
    $(eval $(1) := $(PREBUILTS_ROOT)/$(notdir $($(1))))
    $(if $(wildcard $($(1))),,$(error Cannot find prebuilts override for $(1) = $($(1))))
endef

# Restore a variable formerly adjusted by save_var.
#
# Parameters:
#   $(1):	Makefile to restore, e.g. BUILD_EXECUTABLE
define restore_var
    $(eval $(1) := $(PREBUILTS_ORIGINAL_$(1)))
    $(eval $(PREBUILTS_ORIGINAL_$(1)) := )
endef

# Save and adjust all variables defined in prebuilts.definitions.mk.
define save_vars
    PREBUILTS_DEFINITIONS_MODE := save
    include $(PREBUILTS_ROOT)/prebuilts.definitions.mk
    PREBUILTS_DEFINITIONS_MODE :=
endef

# Restore all variables defined in prebuilts.definitions.mk.
define restore_vars
    PREBUILTS_DEFINITIONS_MODE := restore
    include $(PREBUILTS_ROOT)/prebuilts.definitions.mk
    PREBUILTS_DEFINITIONS_MODE :=
endef

prebuilts_projects := \
    external/chromium_org \
    external/llvm

# Check each entry in $(prebuilts_projects) for existence in $(subdir_makefiles).
prebuilts_makefiles :=
$(foreach project, $(prebuilts_projects),\
  $(if $(filter $(addsuffix /Android.mk, $(addprefix $(TOP)/, $(project))), $(subdir_makefiles)),\
    $(eval prebuilts_makefiles += $(addsuffix /Android.mk, $(addprefix $(TOP)/, $(project)))),\
    $(error Invalid prebuilt project specified: $(project))\
  )\
)

ifneq ($(prebuilts_makefiles),)
# Export a target that can be used to populate new prebuilts binaries.
.PHONY: prebuilts
prebuilts: ;

$(eval $(call save_vars))
$(foreach mk,\
    $(prebuilts_makefiles),\
    $(eval include $(mk))\
    $(eval subdir_makefiles := $(filter-out $(mk), $(subdir_makefiles)))\
)
$(eval $(call restore_vars))
endif # prebuilts_makefiles

prebuilts_projects :=
prebuilts_makefiles :=
PREBUILTS_HOST_BINARIES :=
PREBUILTS_TARGET_BINARIES :=
PREBUILTS_BINARIES :=
PREBUILTS_ROOT :=
