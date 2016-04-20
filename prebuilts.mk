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

PREBUILTS_ROOT := $(call my-dir)
PREBUILTS_MK_ROOT := $(PREBUILTS_ROOT)
PREBUILTS_BINARIES ?= $(PREBUILTS_ROOT)
PREBUILTS_TARGET_BINARIES := $(PREBUILTS_BINARIES)/target
PREBUILTS_HOST_BINARIES := $(PREBUILTS_BINARIES)/host/$(HOST_OS)

# List of build includes that we can provide prebuilts for.
PREBULTS_OVERRIDE := \
    BUILD_SHARED_LIBRARY \
    BUILD_EXECUTABLE \
    BUILD_HOST_SHARED_LIBRARY \
    BUILD_HOST_EXECUTABLE

# Save a variable that contains a build system's makefile path.
# Adjust the path to the makefile to $(PREBUILTS_ROOT).
# The prebuilt makefile can use the original one as PREBUILTS_ORIGINAL_$(1).
#
# Parameters:
#   $(1):	Makefile to adjust, e.g. BUILD_EXECUTABLE
define save_var
    PREBUILTS_ORIGINAL_$(1) := $($(1))
    $(1) := $(PREBUILTS_ROOT)/$(notdir $($(1)))
    $(if $(wildcard $($(1))),,$(error Cannot find prebuilts override for $(1) = $($(1))))
endef

# Restore a variable formerly adjusted by save_var.
#
# Parameters:
#   $(1):	Makefile to restore, e.g. BUILD_EXECUTABLE
define restore_var
    $(1) := $(PREBUILTS_ORIGINAL_$(1))
    $(PREBUILTS_ORIGINAL_$(1)) :=
endef

# Save and adjust all variables defined in prebuilts.definitions.mk.
define save_vars
    $(foreach inc, $(PREBULTS_OVERRIDE), $(eval $(call save_var,$(inc))))
endef

# Restore all variables defined in prebuilts.definitions.mk.
define restore_vars
    $(foreach inc, $(PREBULTS_OVERRIDE), $(eval $(call restore_var,$(inc))))
endef

# Check if special variables are used to build a module.
# Outputs a list of the values of all special variables from
# $(2) that the local module depends upon.
#
# Parameters:
#   $(1):	LOCAL_PATH of the current module to check
#   $(2):	List of make variables to check for.
#
# Example:
#  $(call prebuilts_check_for, $(LOCAL_PATH), \
#         TARGET_BUILD_VARIANT TARGET_BUILD_TYPE)
#     -> userdebug-
#  or -> userdebug-release-
define prebuilts_check_for
$(strip \
    $(eval lst := ) \
    $(foreach var, $(2), \
        $(if $(shell find $(1) -name \*.mk | xargs grep $(var)), \
            $(eval lst += $($(var))))) \
    $(if $(subst $(space),-,$(strip $(lst))), \
        $(subst $(space),-,$(strip $(lst)))-) \
)
endef

# Create rule for a file in the prebuilts cache.
#
# Parameters:
#   $(1):	Prebuilts file to be cached
#   $(2):	Built intermediate file
define prebuilts_cache_file
$(eval $(call copy-one-file,$(2),$(1)))
prebuilts: $(1)
endef

# Print Git revision for a path.
#
# Parameters:
#   $(1):	Path to .git directory
define prebuilts-git-rev
$(strip \
  $(if $(filter %/.git,$(1)), \
    $(eval my_git_path := $(1)/..), \
    $(eval my_git_path := $(1)) \
  ) \
  $(shell cd $(my_git_path) && git rev-parse HEAD 2> /dev/null) \
  $(eval my_git_path :=) \
)
endef

# Print status if repository at given path is dirty,
# no ouput otherwise.
#
# Parameters:
#   $(1):	Path to .git directory
define prebuilts-git-dirty
$(strip \
  $(if $(filter %/.git,$(1)), \
    $(eval my_git_path := $(1)/..), \
    $(eval my_git_path := $(1)) \
  ) \
  $(shell cd $(my_git_path) && git status -s 2> /dev/null | tail -n1) \
  $(eval my_git_path :=) \
)
endef

# List all git repositories below given path.
#
# Parameters:
#   $(1):	Path
define prebuilts-git-subdirs
$(sort $(filter-out $(1)/.git,$(shell find $(1) -name .git -type d -prune)))
endef

# Get Git revisions of all repositories under a given path,
# including the path itself.
#
# If there are multiple git repositories to consider, an artficial hash is
# created. That avoids file names to become too long.
#
# Parameters:
#   $(1):	Path
define prebuilts-git-revs-for
$(strip \
  $(eval my_git_rev := $(call prebuilts-git-rev,$(1))) \
  $(eval my_git_subdirs := $(call prebuilts-git-subdirs,$(1))) \
  $(if $(my_git_subdirs), \
    $(shell echo $(my_git_rev)$(foreach d,$(my_git_subdirs),$(call prebuilts-git-rev,$(d))) | \
    				git hash-object --no-filters --stdin), \
    $(my_git_rev) \
  ) \
  $(eval my_git_subdirs := ) \
  $(eval my_git_rev := ) \
)
endef

# Get dirty state of all repositories under a given path,
# including the path itself.
#
# Parameters:
#   $(1):	Path
define prebuilts-git-dirty-for
$(strip \
  $(eval my_git_subdirs := $(call prebuilts-git-subdirs,$(1))) \
  $(call prebuilts-git-dirty,$(1))$(foreach d,$(my_git_subdirs),$(call prebuilts-git-dirty,$(d))) \
  $(eval my_git_subdirs := ) \
)
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

# These hooks are used in upstream makefiles before rule generation
target-shared-library-hook = $(eval include $(PREBUILTS_MK_ROOT)/prebuilts.internal.mk)
target-executable-hook = $(eval include $(PREBUILTS_MK_ROOT)/prebuilts.internal.mk)
host-shared-library-hook = $(eval include $(PREBUILTS_MK_ROOT)/prebuilts.internal.mk)
host-executable-hook = $(eval include $(PREBUILTS_MK_ROOT)/prebuilts.internal.mk)

prebuilts_avail := 0
prebuilts_used := 0
prebuilts-count = $(eval $(1) := $(shell echo $$(( $($(1)) + 1 )) ))

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

$(info Using $(prebuilts_used) cached prebuilts; $(prebuilts_avail) modules scanned.)

target-shared-library-hook =
target-executable-hook =
host-shared-library-hook =
host-executable-hook =

prebuilts-count :=
prebuilts_used :=
prebuilts_avail :=
prebuilts_projects :=
prebuilts_makefiles :=
PREBUILTS_OVERRIDE :=
PREBUILTS_HOST_BINARIES :=
PREBUILTS_TARGET_BINARIES :=
PREBUILTS_BINARIES :=
PREBUILTS_MK_ROOT :=
PREBUILTS_ROOT :=
