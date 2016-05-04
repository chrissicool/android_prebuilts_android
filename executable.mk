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

include $(PREBUILTS_ORIGINAL_BUILD_EXECUTABLE)

ifndef LOCAL_PREBUILT_MODULE_FILE
ifdef my_prebuilts_module_file
$(eval $(call prebuilts_cache_file, $(my_prebuilts_module_file), $(LOCAL_INSTALLED_MODULE)))
endif
endif

my_prebuilts_module_file :=
