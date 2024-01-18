#!/bin/bash
#

# This script was created to re-package an ISO and modify the squashfs
# nix-store located on the original. This is not necessary and the script
# is deprecated, but it could be useful for other applications
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run with sudo privileges."
    exit 1
fi

./check_env.sh
exit_status=$?

case $exit_status in
    0)
        echo "Environment setup required. Running set_env.sh..."
        ./set_env.sh
        echo "Restarting the script..."
        exec "$0" "$@"
        ;;
    1)
        NIX="/run/current-system/sw/bin/nix"
        ;;
    2)
        NIX="/nix/var/nix/profiles/default/bin/nix"
        ;;
    *)
        echo "Error: Invalid environment or check_env.sh script not found."
        ./restore_env.sh
        exit 1
        ;;
esac

ISO_DIR="../result/iso/"
ISO_PATH=$(find $ISO_DIR -type f -name "*.iso" -print -quit)
ISO_LABEL=$(blkid -o value -s LABEL "$ISO_PATH")

if [ -z "$ISO_LABEL" ]; then
    echo "Could not find original ISO label at $ISO_PATH"
    exit 1
fi

if [[ ! -f "$ISO_PATH" ]]; then
    echo "No ISO file found in $ISO_DIR"
    exit 1
fi

MOUNT_POINT="./iso_mnt"
mkdir -p $MOUNT_POINT

SQUASHFS_PATH="$MOUNT_POINT/nix-store.squashfs"

EXTRACTED_PATH="./squash_tmp"
mkdir -p $EXTRACTED_PATH

MODIFIED_SQUASHFS_PATH="./nix-store-mod.squashfs"

NEW_ISO_PATH="./new_iso"
mkdir -p $NEW_ISO_PATH

NEW_ISO_FILE="./patched_installer.iso"

LOOP_DEVICE=$(losetup -Pf --show $ISO_PATH)

PART1="${LOOP_DEVICE}p1"

error_handler() {
    exit_status=$?
    if [[ $exit_status -ne 0 ]]; then
        echo "Script halted due to error"
        sleep 3
        umount $MOUNT_POINT
        losetup -d $LOOP_DEVICE
        rm -rf $MOUNT_POINT  $EXTRACTED_PATH $MODIFIED_SQUASHFS_PATH $NEW_ISO_PATH 

        ./restore_env.sh
        exit 1
    fi
}
trap 'error_handler $LINENO' ERR

echo "Mounting ISO partition..."
mount $PART1 $MOUNT_POINT
echo

echo "Extracting SquashFS nix-store..."
unsquashfs -d $EXTRACTED_PATH $SQUASHFS_PATH
echo

echo "Copying new files to the nix-store..."
cp -rv ./store_include/* $EXTRACTED_PATH
echo

echo "Creating new SquashFS nix-store..."
mksquashfs $EXTRACTED_PATH $MODIFIED_SQUASHFS_PATH
echo

echo "Copying old partition 1 ISO contents..."
shopt -s dotglob
cp -r $MOUNT_POINT/* $NEW_ISO_PATH
shopt -u dotglob
rm $NEW_ISO_PATH/$(basename $SQUASHFS_PATH)
echo

echo "Copying new nix-store SquashFS..."
cp $MODIFIED_SQUASHFS_PATH $NEW_ISO_PATH/$(basename $SQUASHFS_PATH)
echo

ls -la $NEW_ISO_PATH

echo "Creating new bootable ISO file..."
xorriso -as mkisofs -isohybrid-mbr $NEW_ISO_PATH/isolinux/isohdpfx.bin -c isolinux/boot.cat -b isolinux/isolinux.bin \
    -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot \
    -e boot/efi.img -no-emul-boot -isohybrid-gpt-basdat \
    -o $NEW_ISO_FILE -V $ISO_LABEL \
    -graft-points \
    /isolinux=$NEW_ISO_PATH/isolinux \
    /EFI=$NEW_ISO_PATH/EFI \
    $NEW_ISO_PATH
echo

echo "Unmounting old ISO and removing temp files..."
umount $MOUNT_POINT
losetup -d $LOOP_DEVICE
rm -rf $MOUNT_POINT $EXTRACTED_PATH $MODIFIED_SQUASHFS_PATH $NEW_ISO_PATH 
echo

echo "New ISO created at $NEW_ISO_FILE"
