#! /usr/bin/env nix-shell
#! nix-shell -i bash -p squashfsTools xorriso

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

ISO_DIR="./result/iso/"
ISO_PATH=$(find $ISO_DIR -type f -name "*.iso" -print -quit)

if [[ ! -f "$ISO_PATH" ]]; then
    echo "No ISO file found in $ISO_DIR"
    exit 1
fi

MOUNT_POINT="./iso_mnt"
mkdir -p $MOUNT_POINT

MOUNT_POINT_EFI="./iso_efi_mnt"
mkdir -p $MOUNT_POINT_EFI

SQUASHFS_PATH="$MOUNT_POINT/nix-store.squashfs"

EXTRACTED_PATH="./squash_tmp"
mkdir -p $EXTRACTED_PATH

MODIFIED_SQUASHFS_PATH="./nix-store-mod.squashfs"

NEW_ISO_P1_CONTENTS=./new_iso_contents_p1
mkdir -p $NEW_ISO_P1_CONTENTS

NEW_ISO_P2_CONTENTS=./new_iso_contents_p2
mkdir -p $NEW_ISO_P2_CONTENTS

EFI_IMG_PATH="./efi.img"
NEW_ISO_PATH="./patched_installer.iso"

LOOP_DEVICE=$(losetup -Pf --show $ISO_PATH)

PART1="${LOOP_DEVICE}p1"
PART2="${LOOP_DEVICE}p2"

error_handler() {
    exit_status=$?
    if [[ $exit_status -ne 0 ]]; then
        echo "Script halted due to error"
        sleep 3
        umount $MOUNT_POINT
        umount $MOUNT_POINT_EFI
        losetup -d $LOOP_DEVICE
        rm -rf $MOUNT_POINT $MOUNT_POINT_EFI $EXTRACTED_PATH $MODIFIED_SQUASHFS_PATH $NEW_ISO_P1_CONTENTS $NEW_ISO_P2_CONTENTS $EFI_IMG_PATH

        ./restore_env.sh
        exit 1
    fi
}
trap 'error_handler $LINENO' ERR

echo "Mounting ISO partitions..."
mount $PART1 $MOUNT_POINT
mount $PART2 $MOUNT_POINT_EFI
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
cp -r $MOUNT_POINT/* $NEW_ISO_P1_CONTENTS
shopt -u dotglob
rm ./new_iso_contents_p1/$(basename $SQUASHFS_PATH)
echo

echo "Copying new nix-store SquashFS..."
cp $MODIFIED_SQUASHFS_PATH $NEW_ISO_P1_CONTENTS
echo

echo "Copying EFI data to partition 2..."
shopt -s dotglob
cp -r $MOUNT_POINT_EFI/* $NEW_ISO_P2_CONTENTS
shopt -u dotglob
echo

echo "Creating a FAT filesystem for EFI data..."
mkfs.vfat -C $EFI_IMG_PATH 65536
mmd -i $EFI_IMG_PATH ::/EFI
mcopy -i $EFI_IMG_PATH -s $NEW_ISO_P2_CONTENTS/* ::/
echo

echo "Creating new UEFI bootable ISO file..."
xorriso -as mkisofs -o $NEW_ISO_PATH -J -R \
    -append_partition 2 0xef $EFI_IMG_PATH \
    -eltorito-alt-boot \
    -e /EFI/boot/bootx64.efi -no-emul-boot \
    -isohybrid-gpt-basdat \
    $NEW_ISO_P1_CONTENTS
echo

echo "Unmounting old ISO and removing temp files..."
umount $MOUNT_POINT
umount $MOUNT_POINT_EFI
losetup -d $LOOP_DEVICE
rm -rf $MOUNT_POINT $MOUNT_POINT_EFI $EXTRACTED_PATH $MODIFIED_SQUASHFS_PATH $NEW_ISO_P1_CONTENTS $NEW_ISO_P2_CONTENTS $EFI_IMG_PATH 
echo

echo "New ISO created at $NEW_ISO_PATH"
