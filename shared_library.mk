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

ifeq ($(strip $(LOCAL_MODULE_SUFFIX)),)
LOCAL_MODULE_SUFFIX := $(TARGET_SHLIB_SUFFIX)
endif

ifeq ($(strip $(LOCAL_MODULE_CLASS)),)
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
endif

LOCAL_PREBUILT_MODULE_FILE := $(PREBUILTS_TARGET_BINARIES)/$(LOCAL_MODULE)-$(TARGET_ARCH_VARIANT)$(LOCAL_MODULE_SUFFIX)
$(if $(wildcard $(LOCAL_PREBUILT_MODULE_FILE)),, \
  $(eval LOCAL_PREBUILT_MODULE_FILE := ) \
  $(eval my_prebuilts_nonexistent := true) \
)

# Compare git revisions
my_git_rev := $(shell cd $(LOCAL_PATH) && git rev-parse HEAD 2> /dev/null)
my_git_dirty := $(strip $(shell cd $(LOCAL_PATH) && git status -s 2> /dev/null | tail -n1))

ifndef my_git_rev
$(error $(LOCAL_PATH): Cannot determine Git revision for $(LOCAL_MODULE))
endif

ifdef LOCAL_PREBUILT_MODULE_FILE
my_module_rev := $(shell test -f $(LOCAL_PREBUILT_MODULE_FILE).rev && cat $(LOCAL_PREBUILT_MODULE_FILE).rev)
$(if $(shell if [ "$(my_module_rev)" != "$(my_git_rev)" ] ; then echo failed ; fi ),\
    $(eval LOCAL_PREBUILT_MODULE_FILE := ) \
    $(eval my_prebuilts_nonexistent := true) \
)
endif

ifneq (,$(my_git_dirty))
my_prebuilts_nonexistent := true
LOCAL_PREBUILT_MODULE_FILE :=
endif

include $(PREBUILTS_ORIGINAL_BUILD_SHARED_LIBRARY)

ifdef my_prebuilts_nonexistent
LOCAL_PREBUILT_MODULE_FILE := $(PREBUILTS_TARGET_BINARIES)/$(LOCAL_MODULE)-$(TARGET_ARCH_VARIANT)$(LOCAL_MODULE_SUFFIX)

$(LOCAL_PREBUILT_MODULE_FILE): $(LOCAL_BUILT_MODULE)
	$(call copy-file-to-target-with-cp)

$(LOCAL_PREBUILT_MODULE_FILE).rev: PRIVATE_GIT_REV := $(my_git_rev)
$(LOCAL_PREBUILT_MODULE_FILE).rev: PRIVATE_GIT_DIRTY := $(my_git_dirty)
$(LOCAL_PREBUILT_MODULE_FILE).rev: PRIVATE_MODULE_REV := $(my_module_rev)
$(LOCAL_PREBUILT_MODULE_FILE).rev: $(LOCAL_PREBUILT_MODULE_FILE)
	@mkdir -p $(dir $@)
	@if [ -z "$(PRIVATE_GIT_DIRTY)" -a "$(PRIVATE_GIT_REV)" != "$(PRIVATE_MODULE_REV)" ] ; then \
		echo -n "$(PRIVATE_GIT_REV)" > $@ ; \
	 fi

prebuilts: $(LOCAL_PREBUILT_MODULE_FILE) $(LOCAL_PREBUILT_MODULE_FILE).rev
endif # my_prebuilts_nonexistent

my_module_rev :=
my_git_dirty :=
my_git_rev :=
my_prebuilts_nonexistent :=
LOCAL_PREBUILT_MODULE_FILE :=
