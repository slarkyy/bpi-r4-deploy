#!/bin/sh
# install-emmc.sh — Install OpenWrt to eMMC
# Must be run from NAND rescue system only!

set -e

EMMC_IMG="/tmp/emmc-img.bin"
EMMC_DEV="/dev/mmcblk0"
EMMC_BOOT="/dev/mmcblk0boot0"
GH_USER="woziwrt"
GH_REPO="bpi-r4-rescue"

# 1. Check boot media
echo ">>> Checking boot media..."
if grep -q "fitrw" /proc/mounts; then
    echo "ERROR: Running from SD card — must be run from NAND rescue!"
    exit 1
fi
if ! grep -q "ubi.block" /proc/cmdline; then
    if grep -q "fit0" /proc/cmdline && ! grep -q "ubi" /proc/cmdline; then
        echo "ERROR: Running from eMMC — must be run from NAND rescue!"
        exit 1
    fi
fi
echo "    OK — running from NAND rescue"

# 2. Check eMMC
echo ">>> Checking eMMC..."
if [ ! -b "$EMMC_DEV" ]; then
    echo "ERROR: eMMC ($EMMC_DEV) not found!"
    exit 1
fi
echo "    OK — $EMMC_DEV found"

# 3. Fork selection
echo ""
echo ">>> Release source"
printf "Are you using your own fork? [y/n]: "
read USE_FORK
if [ "$USE_FORK" = "y" ]; then
    echo "    INFO: Fork repository name must remain 'bpi-r4-rescue' (do not rename it)"
    echo "    INFO: Example username: johndoe"
    printf "Enter your GitHub username: "
    read GH_USER
fi
EMMC_IMG_URL="https://github.com/${GH_USER}/${GH_REPO}/releases/download/rescue-latest/openwrt-mediatek-filogic-bananapi_bpi-r4-emmc-img.bin"
echo "    Using release URL: $EMMC_IMG_URL"

# 4. Network check + info
echo ""
echo ">>> Network check..."
echo "    INFO: Internet connection required to download emmc-img.bin (~103MB)"
echo "    INFO: Make sure ethernet cable is connected before continuing"
echo ""
printf "Is ethernet connected? [yes/no]: "
read NET_CONFIRM
if [ "$NET_CONFIRM" != "yes" ]; then
    echo "    INFO: Connect ethernet and run the script again"
    exit 0
fi
if ! ping -c 1 -W 3 github.com > /dev/null 2>&1; then
    echo "ERROR: No network connectivity — check ethernet cable and try again"
    exit 1
fi
echo "    OK — network available"

# 5. Download emmc-img.bin
echo ">>> Downloading emmc-img.bin from GitHub (~103MB)..."
wget -O "$EMMC_IMG" "$EMMC_IMG_URL"
echo "    OK — downloaded to $EMMC_IMG"

# 6. Final warning
echo ""
echo "!!! WARNING !!!"
echo "About to overwrite eMMC ($EMMC_DEV)."
echo "All data on eMMC will be lost!"
echo ""
printf "Continue? [yes/no]: "
read CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    rm -f "$EMMC_IMG"
    echo "Aborted."
    exit 0
fi

# 7. Write image to eMMC
echo ">>> Writing emmc-img.bin to $EMMC_DEV..."
dd if="$EMMC_IMG" of="$EMMC_DEV" bs=1M
sync
echo "    OK — image written"

# 8. Write BL2 to boot partition
echo ">>> Writing BL2 to boot partition..."
echo 0 > /sys/block/mmcblk0boot0/force_ro
dd if="$EMMC_IMG" of="$EMMC_BOOT" bs=512 skip=34 count=512
sync
echo "    OK — BL2 written"

# 9. Set eMMC boot partition
echo ">>> Setting eMMC boot partition..."
mmc bootpart enable 1 1 "$EMMC_DEV"
echo "    OK"

# 10. Cleanup
rm -f "$EMMC_IMG"

# 11. Done
echo ""
echo "=== Installation complete ==="
echo ""
echo "Next steps:"
echo "  1. Power off the device"
echo "  2. Set DIP switch: SW3-A=1, SW3-B=0 (eMMC boot)"
echo "  3. Power on the device"
echo ""