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

# Search for a suitale prebuilt file that can be used for this LOCAL_MODULE.
# Call the original build system include to define targets.
# Define a reverse target for 'make prebuilts' if no prebuilt was found.
#
# Needed variables:
#  - LOCAL_MODULE_SUFFIX
#  - LOCAL_MODULE_CLASS
#  - LOCAL_IS_HOST_MODULE
#
# Defines:
#  - LOCAL_PREBUILT_MODULE_FILE

ifdef LOCAL_IS_HOST_MODULE
my_prefix := HOST_
my_build_prefix := HOST_
my_arch := ARCH
else
my_prefix := TARGET_
my_build_prefix :=
my_arch := CPU_VARIANT
endif

my_path := $(PREBUILTS_$(my_prefix)BINARIES)/$($(my_prefix)$(LOCAL_2ND_ARCH_VAR_PREFIX)$(my_arch))
# Does this module depend on special variables?
my_module_deps := $(call prebuilts_check_for, $(LOCAL_PATH), \
    TARGET_DEVICE \
    $(my_prefix)BUILD_VARIANT \
    $(my_prefix)BUILD_TYPE \
)

# Get git revisions
my_git_rev := $(shell cd $(LOCAL_PATH) && git rev-parse HEAD 2> /dev/null)
my_git_dirty := $(strip $(shell cd $(LOCAL_PATH) && git status -s 2> /dev/null | tail -n1))

ifndef my_git_rev
$(error $(LOCAL_PATH): Cannot determine Git revision for $(LOCAL_MODULE))
endif

my_prebuilts_module_file := $(my_path)/$(LOCAL_MODULE)-$(my_module_deps)$(my_git_rev)$(LOCAL_MODULE_SUFFIX)
$(if $(wildcard $(my_prebuilts_module_file)),, \
  $(eval my_prebuilts_nonexistent := true) \
)

ifneq (,$(my_git_dirty))
my_prebuilts_nonexistent := true
endif

ifndef my_prebuilts_nonexistent
ifndef LOCAL_PREBUILT_MODULE_FILE
LOCAL_PREBUILT_MODULE_FILE := $(my_prebuilts_module_file)
$(call using-prebuilts)
endif
endif

# Include the original build system makefile.
ifeq ($(strip $(LOCAL_MODULE_CLASS)), SHARED_LIBRARIES)
include $(PREBUILTS_ORIGINAL_BUILD_$(my_build_prefix)SHARED_LIBRARY)
endif
ifeq ($(strip $(LOCAL_MODULE_CLASS)), EXECUTABLES)
include $(PREBUILTS_ORIGINAL_BUILD_$(my_build_prefix)EXECUTABLE)
endif

ifndef LOCAL_PREBUILT_MODULE_FILE
$(call prebuilts_cache_file, $(my_prebuilts_module_file), $(LOCAL_INSTALLED_MODULE))
endif

# Unset all used variables
my_git_dirty :=
my_git_rev :=
my_prebuilts_nonexistent :=
my_prebuilts_module_file :=
my_module_deps :=
my_path :=
my_arch :=
my_build_prefix :=
my_prefix :=
