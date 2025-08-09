### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# begin properties
properties() { '
kernel.string=OPMod
do.devicecheck=0
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=1
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties

### AnyKernel install
## boot files attributes
boot_attributes() {
    set_perm_recursive 0 0 755 644 $RAMDISK/*
    set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin
} # end attributes

## boot shell variables
BLOCK="/dev/block/by-name/boot"
IS_SLOT_DEVICE=auto
RAMDISK_COMPRESSION=auto
PATCH_VBMETA_FLAG=auto
NO_MAGISK_CHECK=1
NO_VBMETA_PARTITION_PATCH=1

## Linux version check
check_linux_version() {
    version_good=$(uname -r | awk '{
      split($0, version, /[.-]/);
      if (version[1] != 5) print "N";
      else if (version[2] != 10) print "N";
      else if (version[3] < 168) print "N";
      else print "Y";
    }')

    current=$(uname -r)
    ui_print "required Linux min ver: 5.10.168"
    ui_print "current Linux: $current"

    if [ "$version_good" == "N" ]; then
        abort "current linux version not match"
    fi
}

## cmd output
print_output() {
    IFS=$'\n'
    eval "$1" | while read line; do
        ui_print "${line}"
    done
}

## is recovery
is_recovery() {
    pgrep zygote && return 1 || return 0
}

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh

# detect bootmode
is_recovery && abort "Wrong boot mode!"

# check linux version
check_linux_version


## install additional module
ui_print "Installing additional module"
if [ -n "$(which magisk)" ]; then
    MAGISK_VER="$(magisk -v)"
    MAGISK_VERCODE="$(magisk -V)"
    (grep -q kitsune "$MAGISK_VER" || grep -q delta "$MAGISK_VER") && abort "Invalid magisk"
    [ "$MAGISK_VERCODE" -lt 28100 ] && abort "Magisk version too low"
    ui_print "Magisk: $MAGISK_VER($MAGISK_VERCODE)"
    print_output "magisk --install-module $AKHOME/magisk.zip"
elif [ -f "/data/adb/ksud" ]; then
    KSU_VER="$(/data/adb/ksud -V)"
    KSU_VERCODE="$(/data/adb/ksud debug version | awk -F': ' '{print $2}')"
    [ "$KSU_VERCODE" -lt 12081 ] && abort "KernelSU version too low"
    ui_print "KernelSU: $KSU_VER($KSU_VERCODE)"
    print_output "/data/adb/ksud module install $AKHOME/magisk.zip"
elif [ -f "/data/adb/apd" ]; then
    APATCH_VER="$(/data/adb/apd -V | awk -F' ' '{print $2}')"
    [ "$APATCH_VER" -lt 11039 ] && abort "APatch version too low"
    ui_print "APatch: $APATCH_VER"
    print_output "/data/adb/apd module install $AKHOME/magisk.zip"
    ui_print "After flash, you should reinstall APatch manually" && sleep 3
else
    abort "No module system not found"
fi

# boot install
split_boot
flash_boot
## end boot install
