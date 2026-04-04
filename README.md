# OpenWrt for Banana Pi BPI-R4 (kernel 6.12)

OpenWrt 25.12 for Banana Pi BPI-R4 (MT7988, Wi-Fi 7) with a complete install system that runs entirely on GitHub — no Linux machine needed.

---

## What you get

- **SD card image** — boot OpenWrt directly from SD card, no installation needed.
- **NVMe install** — install OpenWrt permanently to an NVMe SSD for best performance.
- **eMMC install** — install OpenWrt permanently to the internal eMMC storage.
- **Sysupgrade support** — update your NVMe system directly from LuCI (System → Backup / Flash Firmware) or from the command line.

---

## DIP switch reference

| Boot medium  | SW3-A | SW3-B |
|--------------|-------|-------|
| SD card      | 0     | 0     |
| NAND rescue  | 0     | 1     |
| eMMC         | 1     | 0     |

> **NVMe boot** is controlled by U-Boot environment, not by DIP switch. After running `install-nvme.sh`, the device will boot from NVMe automatically on every power-on — as long as DIP is set to **NAND** (SW3-A=0, SW3-B=1).

---

## Part A — Use the ready-made release (no customization)

No setup needed. Just follow the steps below.

### Option 1 — SD card (simplest)

1. Go to [Releases](https://github.com/woziwrt/bpi-r4-rescue/releases/tag/rescue-latest) and download `openwrt-mediatek-filogic-bananapi_bpi-r4-sdcard.img.gz`.
2. Flash it to your SD card using [Balena Etcher](https://etcher.balena.io/).
3. Insert the SD card into BPI-R4, set DIP **SW3-A=0, SW3-B=0** and power on.
4. Connect via SSH: `ssh root@192.168.1.1` (no password by default).

That's it — OpenWrt is running from your SD card.

---

### Option 2 — NVMe install (recommended for permanent use)

This installs OpenWrt to an NVMe SSD. After installation, the SD card is no longer needed.

#### What you need
- A microSD card (any size, 1 GB is enough).
- An NVMe SSD installed in BPI-R4.
- A network cable connected to BPI-R4 during installation.

#### Step 1 — Flash the rescue SD card

1. Go to [Releases](https://github.com/woziwrt/bpi-r4-rescue/releases/tag/rescue-latest) and download `bpi-r4-rescue-sdcard.img.gz`.
2. Flash it to your SD card using [Balena Etcher](https://etcher.balena.io/).
3. Insert the SD card into BPI-R4.
4. Set DIP **SW3-A=0, SW3-B=0** (SD boot) and power on.
5. Connect via SSH: `ssh root@192.168.1.1` (no password).

#### Step 2 — Install NAND rescue system

```sh
/root/bpi-r4-install/install-nand.sh
```

Wait for the script to finish. Then:

1. Power off BPI-R4.
2. Set DIP **SW3-A=0, SW3-B=1** (NAND boot) and power on.
3. Connect via SSH: `ssh root@192.168.1.1`

#### Step 3 — Install OpenWrt to NVMe

Make sure the network cable is connected, then run:

```sh
/root/bpi-r4-install/install-nvme.sh
```

The script will:
- Check your NVMe disk health (SMART).
- Download the required images from GitHub automatically (~50 MB).
- Write OpenWrt to your NVMe SSD.
- Set up automatic NVMe boot.
- Reboot automatically.

After reboot, BPI-R4 boots from NVMe. The SD card is no longer needed.

> **Updating** — to update OpenWrt on NVMe, boot into NAND rescue (DIP SW3-A=0, SW3-B=1, then power on) and run `install-nvme.sh` again. It will detect the existing installation and update only the kernel and rootfs without touching your settings.

---

### Option 3 — eMMC install

This installs OpenWrt to the internal eMMC storage. Follow the same steps as NVMe install (Steps 1 and 2), then run:

```sh
/root/bpi-r4-install/install-emmc.sh
```

The script downloads the eMMC image (~103 MB) and writes it automatically.

After installation:
1. Power off BPI-R4.
2. Set DIP **SW3-A=1, SW3-B=0** (eMMC boot) and power on.

> ⚠️ eMMC install has been tested but eMMC boot is less commonly used. NVMe is the recommended option for permanent installation.

---

### Sysupgrade (updating NVMe system from LuCI)

Once running from NVMe, you can update OpenWrt without any scripts:

1. Download `bpi-r4.itb` from the [Releases](https://github.com/woziwrt/bpi-r4-rescue/releases/tag/rescue-latest) page.
2. In LuCI, go to **System → Backup / Flash Firmware**.
3. Under **Flash new firmware image**, upload `bpi-r4.itb`.
4. Uncheck **Keep settings** if you want a clean install, or leave it checked to keep your configuration.
5. Click **Flash image** and confirm.

BPI-R4 will update and reboot automatically.

---

## Part B — Fork and customize (advanced users)

Fork this repository to build your own customized release — add or remove packages, then install from your own GitHub release.

### Step 1 — Fork the repository

Fork this repository on GitHub. **Do not rename the fork** — it must stay named `bpi-r4-rescue`, otherwise the install scripts will not find your release.

### Step 2 — Enable workflows and set permissions

1. Go to the **Actions** tab in your fork and enable workflows.
2. Open **Settings → Actions → General** and set:
   - **Actions permissions**: Allow all actions and reusable workflows.
   - **Workflow permissions**: **Read and write permissions** — required to create releases. The default is read-only, change this manually.

> ⚠️ Without **Read and write permissions** the workflow will fail when trying to create a release.

### Step 3 — Customize packages

1. In your fork, open `configs/my_final_defconfig`.
2. Click the pencil icon to edit directly on GitHub.
3. You will see lines like:
   ```
   CONFIG_PACKAGE_iperf3=y
   CONFIG_PACKAGE_htop is not set
   ```
   - `=y` → package enabled
   - `is not set` → package disabled
4. Change lines to enable or disable packages.
5. **Only change lines starting with `CONFIG_PACKAGE_`.** Do not touch kernel, target, or MTK SDK options.
6. Click **Commit changes**.

### Step 4 — Trigger a build

1. Go to the **Actions** tab in your fork.
2. Select **Build BPI-R4**.
3. Click **Run workflow** and confirm.
4. After the workflow finishes (approx. 2 hours), a release tagged `rescue-latest` will be created in your fork.

### Step 5 — Install from your fork

When running `install-nvme.sh` or `install-emmc.sh`, select option **[2] My fork** and enter your GitHub username:

```
  [1] Default (woziwrt/bpi-r4-rescue)
  [2] My fork (same repo name, different username)

  Select [1/2]: 2
        Enter your GitHub username: johndoe
        URL: https://github.com/johndoe/bpi-r4-rescue/releases/download/rescue-latest
```

The URL is displayed so you can verify it before the download starts.

---

## Repository contents

| File / Directory | Description |
|------------------|-------------|
| `bpi-r4-openwrt-builder.sh` | Main build script — clones OpenWrt and MTK SDK, applies patches, builds. |
| `configs/my_final_defconfig` | Package config — edit this to customize your build. |
| `my_files/` | Patches, custom files, install scripts. |
| `rescue/bpi-r4-rescue-sdcard.img.gz` | Static rescue SD card image. |
| `.github/workflows/build.yml` | GitHub Actions workflow. |

---

## Notes

- This build is for Banana Pi BPI-R4 only (MT7988, 2x SFP+).
- OpenWrt and MTK SDK commits are pinned in the build script. Updating them requires manual editing.
- 8 GB RAM variant of BPI-R4 should work — RAM is detected automatically at boot.

### Notes about GitHub runners

This workflow runs on GitHub-hosted runners where free disk space is not guaranteed. If a build fails with a disk-related error, re-run the workflow — runners with sufficient space (~100 GB free) are usually available within a short time.

External mirrors used during the build can also be temporarily slow or unavailable. Re-running the workflow later usually resolves this.
