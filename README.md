# Android prebuilts system

The Android prebuilts system lets you create pre-compiled packages for AOSP.
It's main purpose is to speed up Android development.
Compiling AOSP usually takes a very long time,
especially for the first time.
Although AOSP can make use of ccache for subsequent builds,
compiling a fresh checkout usually takes ages.
It gets even worse on not-so-beefy hardware.

The Android prebuilts system tries to mitigate this.
It provides prebuilt packages for heavy modules (in terms of compile time).
It is aimed at developers for a fast edit-compile-run cycle.

Currently this is a proof-of-concept with limitations.
Look at the [Hacking](#hacking) section below for missing features.

# Installation

Add this repository to your (local) manifest
and check it out to ```prebuilts/android```.

Apply the following patch to ```build/core/main.mk```.

```make
--- a/core/main.mk
+++ b/core/main.mk
@@ -527,6 +527,8 @@ ifneq ($(dont_bother),true)
 subdir_makefiles := \
        $(shell build/tools/findleaves.py --prune=$(OUT_DIR) --prune=.repo --prune=.git $(subdirs) Android.mk)
 
+-include $(TOP)/prebuilts/android/prebuilts.mk
+
 $(foreach mk, $(subdir_makefiles), $(eval include $(mk)))
 
 endif # dont_bother
```
# Usage

On first-time use of the prebuilts system you need to popuate prebuilts.
These will be used automatically in subsequent runs,
even after you deleted the entire ```$OUT``` directory.

To populate prebuilts, run

```
 $ m prebuilts
```

Prebuilts will be placed under ```$(TOP)/prebuilts/android/{target,host}/``` by default.
This target directory can be ovverridden with the ```PREBUILTS_BINARIES``` environemnt variable.
Each host OS and each target architecture have its own directory tree.
Every prebuilt module name contains the following information:

 - local module (mandatory)
 - build variant (optional)
 - build type (optional)
 - Git SHA1 of source directory (mandatory)

The directory structure is chosen so that you can create separate repositories for the binaries.
These repositories then can be used to prepopulate other build hosts
via (local) manifest, rsync or shared NFS directories.

It is recommended to re-populate prebuilts every now and then.
Prebuilts will not be recompiled if not necessary.
Prebuilts will not be used for modules that have another version than the prebuilt binary.

The prebuilts cache is used during every build.
If you want to build everything from source although a valid prebuilts cache exists,
set the environemnt variable ```ANDROID_BUILD_FROM_SOURCE=true```.
This is strongly recommended for continuous integration or release builds.

# Hacking

Yes, please!
If you find an issue,
open a bug report on Github.
Fork this project on Github and send pull requests.

This prebuilts system aims to be a drop-in solution for AOSP builds.
Other than the on-line patch for the [installation](#installation),
there should be no need to touch upstream code.

Known TODOs are:

 * prebuild all binaries
