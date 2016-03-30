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

#$(eval $(call $(PREBUILTS_DEFINITIONS_MODE)_var,BUILD_STATIC_LIBRARY))
$(eval $(call $(PREBUILTS_DEFINITIONS_MODE)_var,BUILD_SHARED_LIBRARY))
$(eval $(call $(PREBUILTS_DEFINITIONS_MODE)_var,BUILD_EXECUTABLE))
#$(eval $(call $(PREBUILTS_DEFINITIONS_MODE)_var,BUILD_HOST_STATIC_LIBRARY))
#$(eval $(call $(PREBUILTS_DEFINITIONS_MODE)_var,BUILD_HOST_SHARED_LIBRARY))
#$(eval $(call $(PREBUILTS_DEFINITIONS_MODE)_var,BUILD_HOST_EXECUTABLE))
#$(eval $(call $(PREBUILTS_DEFINITIONS_MODE)_var,BUILD_PACKAGE))
