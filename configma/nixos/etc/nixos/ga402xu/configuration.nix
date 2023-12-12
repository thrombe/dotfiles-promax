{
  config,
  pkgs,
  lib,
  modulesPath,
  username,
  ...
}: let
  tags = ["ga402xu"];
  sandisk-ssd = {
    tags = ["sandisk-ssd"];

    "/" = {
      device = "/dev/disk/by-uuid/aefbe3df-3d17-4106-ba90-71a1a71874bb";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/193B-69DB";
      fsType = "vfat";
    };
  };

  powerstate-sync-ac = pkgs.writeShellScriptBin "powerstate-sync-ac" ''
    if [ -S /tmp/.X11-unix/X0 ]; then
      # - [xrandr cannot open display](https://bbs.archlinux.org/viewtopic.php?id=122848)
      export XAUTHORITY=/home/${username}/.Xauthority
      export DISPLAY=:0

      echo "setting ac power settings"
      ${pkgs.xorg.xrandr}/bin/xrandr -r 165
    else
      ${pkgs.wlr-randr}/bin/wlr-randr --output eDP-1 --mode 2560x1600@165.001999Hz
    fi

    ${pkgs.coreutils}/bin/echo "performance" | ${pkgs.coreutils}/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
    ${pkgs.coreutils}/bin/echo "performance" | ${pkgs.coreutils}/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

    ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance
  '';
  powerstate-sync-bat = pkgs.writeShellScriptBin "powerstate-sync-bat" ''
    if [ -S /tmp/.X11-unix/X0 ]; then
      # - [xrandr cannot open display](https://bbs.archlinux.org/viewtopic.php?id=122848)
      export XAUTHORITY=/home/${username}/.Xauthority
      export DISPLAY=:0

      echo "setting battery power settings"
      ${pkgs.xorg.xrandr}/bin/xrandr -r 60
    else
      ${pkgs.wlr-randr}/bin/wlr-randr --output eDP-1 --mode 2560x1600@60.001999Hz
    fi

    ${pkgs.coreutils}/bin/echo "powersave" | ${pkgs.coreutils}/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
    ${pkgs.coreutils}/bin/echo "power" | ${pkgs.coreutils}/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference

    ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver
  '';
  powerstate-sync = pkgs.writeShellScriptBin "powerstate-sync" ''
    # status=="$(${pkgs.busybox}/bin/grep "Battery 0" | ${pkgs.busybox}/bin/cut -d ',' -f1 | ${pkgs.busybox}/bin/cut ' ' -f3)"
    status=="$(${pkgs.acpi}/bin/acpi -b | ${pkgs.busybox}/bin/grep 'Battery 0')"

    if [[ "$status" == *"Discharging"* ]]; then
        ${powerstate-sync-bat}/bin/powerstate-sync-bat
    else
        ${powerstate-sync-ac}/bin/powerstate-sync-ac
    fi
  '';
in {
  specialisation = {
    sandisk-ssd.configuration = {
      system.nixos.tags = tags ++ sandisk-ssd.tags;

      fileSystems."/" = lib.mkForce sandisk-ssd."/";
      fileSystems."/boot" = lib.mkForce sandisk-ssd."/boot";
    };

    sandisk-ssd-vm.configuration = {
      system.nixos.tags = tags ++ sandisk-ssd.tags ++ ["gl553ve-vm" "mount-mnt"];

      fileSystems."/" = lib.mkForce sandisk-ssd."/";
      fileSystems."/boot" = lib.mkForce sandisk-ssd."/boot";
      fileSystems."/mnt" = lib.mkForce {
        device = "mnt";
        fsType = "virtiofs";
      };
    };

    nix-latest-kernel.configuration = {
      system.nixos.tags = tags ++ ["nix-latest-kernel"];

      boot.kernelPackages = pkgs.unstable.linuxPackages_latest;
    };

    asusd-disabled.configuration = {
      system.nixos.tags = tags ++ ["no-asusd" "linux-g14"];

      services.asusd.enable = lib.mkForce false;
      systemd.services.asusd-deepsleep.enable = lib.mkForce false;
    };

    nvme-ssd-boot-alone.configuration = {
      system.nixos.tags = tags ++ ["nvme-ssd-boot-alone"];

      fileSystems."/boot" = lib.mkForce {
        device = "/dev/nvme0n1p1";
        fsType = "vfat";
      };
      fileSystems."/" = lib.mkForce {
        device = "/dev/nvme0n1p2";
        fsType = "ext4";
      };
    };
  };

  fileSystems."/boot" = {
    device = "/dev/nvme0n1p1";
    fsType = "vfat";
  };
  fileSystems."/" = {
    device = "/dev/nvme0n1p2";
    fsType = "ext4";
  };

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules =
    ["nvme" "xhci_pci" "thunderbolt" "usbhid" "usb_storage" "uas" "sd_mod" "rtsx_pci_sdmmc"]
    ++ ["snd_hda_codec_realtek" "snd_hda_intel"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = [];

  # - [swap - NisOS wiki](https://nixos.wiki/wiki/Swap)
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 1024 * 32;
    }
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp2s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # boot.kernelParams = [ "mem_sleep_default=deep" ];

  # select patched linux kernel
  # - [Linux kernel nix wiki](https://nixos.wiki/wiki/Linux_kernel)
  boot.kernelPackages = pkgs.lib.mkDefault (let
    # - [linux-g14 6.5.8-arch1]https://aur.archlinux.org/packages/linux-g14)
    # - [applying patches to kernel](https://www.kernel.org/doc/html/v4.11/process/applying-patches.html)
    # - [linux source code](https://cdn.kernel.org/pub/linux/kernel/v6.x/)
    # patch -p1 < ./name.patch
    patches_6-5-8-arch1 = builtins.fetchTarball {
      url = "https://aur.archlinux.org/cgit/aur.git/snapshot/aur-3433bb9107cb5c4d80f09dd0d5a1825c5945169e.tar.gz";
      sha256 = "sha256:1ms9wp6g314iq86f7dyfkf3k5m3zvqgn860zcm4d04qlfn5zyp90";
    };
    linux_g14_6-5-8-arch1_pkg = {
      fetchurl,
      buildLinux,
      ...
    } @ args:
    # - [buildLinux](https://github.com/NixOS/nixpkgs/blob/a6207181cf6300566bc15f38cf8e4d4c7ce6bc90/pkgs/top-level/linux-kernels.nix#L676)
      buildLinux (args
        // rec {
          version = "6.5.8-arch1";
          extraMeta.branch = "6.5";
          modDirVersion = version;

          # - [howto linux configuration](https://linuxconfig.org/in-depth-howto-on-linux-kernel-configuration)
          # - [common-config nix linux kernel](https://github.com/NixOS/nixpkgs/blob/4f4312a71cd8129620af1d004f54b7056012e21a/pkgs/os-specific/linux/kernel/common-config.nix#L35)
          # as i understand it, this can be disabled as nix uses it's own configs if not specified.
          #   - [](https://github.com/NixOS/nixpkgs/blob/bd406645637326b1538a869cd54cc3fdf17e975a/pkgs/os-specific/linux/kernel/generic.nix#L133)
          # defconfig = "${patches}/config";
          # extraConfig = "${patches}/config";

          src = fetchurl {
            # - [git archlinux releases](https://github.com/archlinux/linux/releases)
            url = "https://github.com/archlinux/linux/archive/refs/tags/v6.5.8-arch1.tar.gz";
            sha256 = "sha256-rbvtvlUwkbuMoI1/GPbnTH67lOysUNNUPguKYjeYFMQ=";
          };

          # go to the PKGBUILD file of the arch package and copy all patches from 'source' in the same order
          kernelPatches =
            [
              {
                patch = fetchurl {
                  name = "sys-kernel_arch-sources-g14_files-0004-5.17+--more-uarches-for-kernel.patch";
                  url = "https://raw.githubusercontent.com/graysky2/kernel_compiler_patch/master/more-uarches-for-kernel-5.17+.patch";
                  sha256 = "sha256-ga1mOSWgqltTMqabrnInOTZku4HuLleig+fxbp/3Xv4=";
                };
              }
            ]
            ++ (map (x: {
                name = x;
                patch = "${patches_6-5-8-arch1}/${x}";
              }) [
                "0001-acpi-proc-idle-skip-dummy-wait.patch"
                "0001-platform-x86-asus-wmi-Add-safety-checks-to-dgpu-egpu.patch"
                "0027-mt76_-mt7921_-Disable-powersave-features-by-default.patch"
                "0001-Revert-PCI-Add-a-REBAR-size-quirk-for-Sapphire-RX-56.patch"
                "0001-constgran-v2.patch"
                "0032-Bluetooth-btusb-Add-a-new-PID-VID-0489-e0f6-for-MT7922.patch"
                "0035-Add_quirk_for_polling_the_KBD_port.patch"
                "0036-Block_a_rogue_device_on_ASUS_TUF_A16.patch"
                "0001-ACPI-resource-Skip-IRQ-override-on-ASUS-TUF-Gaming-A.patch"
                "0002-ACPI-resource-Skip-IRQ-override-on-ASUS-TUF-Gaming-A.patch"
                "v2-0001-platform-x86-asus-wmi-add-support-for-showing-cha.patch"
                "v2-0002-platform-x86-asus-wmi-add-support-for-showing-mid.patch"
                "v2-0003-platform-x86-asus-wmi-support-middle-fan-custom-c.patch"
                "v2-0004-platform-x86-asus-wmi-add-WMI-method-to-show-if-e.patch"
                "v2-0005-platform-x86-asus-wmi-don-t-allow-eGPU-switching-.patch"
                "v2-0006-platform-x86-asus-wmi-add-safety-checks-to-gpu-sw.patch"
                "v2-0007-platform-x86-asus-wmi-support-setting-mini-LED-mo.patch"
                "v2-0008-platform-x86-asus-wmi-expose-dGPU-and-CPU-tunable.patch"
                "0038-mediatek-pci-reset.patch"
                "0040-workaround_hardware_decoding_amdgpu.patch"
                "0001-platform-x86-asus-wmi-Fix-and-cleanup-custom-fan-cur.patch"
                "0005-platform-x86-asus-wmi-don-t-allow-eGPU-switching-if-.patch"
                "0006-platform-x86-asus-wmi-add-safety-checks-to-gpu-switc.patch"
                "0001-platform-x86-asus-wmi-Support-2023-ROG-X16-tablet-mo.patch"
                "amd-tablet-sfh.patch"
                "v2-0001-ALSA-hda-cs35l41-Support-systems-with-missing-_DS.patch"
                "v2-0002-ALSA-hda-cs35l41-Support-ASUS-2023-laptops-with-m.patch"
                "v6-0001-platform-x86-asus-wmi-add-support-for-ASUS-screen.patch"
                "sys-kernel_arch-sources-g14_files-0047-asus-nb-wmi-Add-tablet_mode_sw-lid-flip.patch"
                "sys-kernel_arch-sources-g14_files-0048-asus-nb-wmi-fix-tablet_mode_sw_int.patch"
              ]);
        }
        // (args.argsOverride or {}));
    patches_6-6-2-arch1 = builtins.fetchTarball {
      url = let rev = "8e4c2a7a455959bdd2da814d71f1a18660350c97"; in "https://aur.archlinux.org/cgit/aur.git/snapshot/aur-${rev}.tar.gz";
      sha256 = "sha256:0as73wsi6bv2d079yg1jzcl1vh5jdrn3nfki6px7d17z5nrlf3fp";
    };
    linux_g14_6-6-2-arch1_pkg = {
      fetchurl,
      buildLinux,
      ...
    } @ args:
    # - [buildLinux](https://github.com/NixOS/nixpkgs/blob/a6207181cf6300566bc15f38cf8e4d4c7ce6bc90/pkgs/top-level/linux-kernels.nix#L676)
      buildLinux (args
        // rec {
          version = "6.6.2-arch1";
          extraMeta.branch = "6.6";
          modDirVersion = version;

          # - [howto linux configuration](https://linuxconfig.org/in-depth-howto-on-linux-kernel-configuration)
          # - [common-config nix linux kernel](https://github.com/NixOS/nixpkgs/blob/4f4312a71cd8129620af1d004f54b7056012e21a/pkgs/os-specific/linux/kernel/common-config.nix#L35)
          # as i understand it, this can be disabled as nix uses it's own configs if not specified.
          #   - [](https://github.com/NixOS/nixpkgs/blob/bd406645637326b1538a869cd54cc3fdf17e975a/pkgs/os-specific/linux/kernel/generic.nix#L133)
          # defconfig = "${patches}/config";
          # extraConfig = "${patches}/config";

          src = fetchurl {
            # - [git archlinux releases](https://github.com/archlinux/linux/releases)
            url = "https://github.com/archlinux/linux/archive/refs/tags/v6.6.2-arch1.tar.gz";
            sha256 = "sha256-KeA4gY4hAH/eiMw2C9+ZTHBKjsk296zcDGpGavh7rp4=";
          };

          # go to the PKGBUILD file of the arch package and copy all patches from 'source' in the same order
          kernelPatches =
            [
              {
                patch = fetchurl {
                  name = "sys-kernel_arch-sources-g14_files-0004-5.17+--more-uarches-for-kernel.patch";
                  url = "https://raw.githubusercontent.com/graysky2/kernel_compiler_patch/master/more-uarches-for-kernel-5.17+.patch";
                  sha256 = "sha256-ga1mOSWgqltTMqabrnInOTZku4HuLleig+fxbp/3Xv4=";
                };
              }
            ]
            ++ (map (x: {
                name = x;
                patch = "${patches_6-6-2-arch1}/${x}";
              }) [
                "0001-ALSA-hda-realtek-Add-quirk-for-ASUS-ROG-G814Jx.patch"
                "0001-acpi-proc-idle-skip-dummy-wait.patch"
                "0001-platform-x86-asus-wmi-Add-safety-checks-to-dgpu-egpu.patch"
                "0001-Revert-PCI-Add-a-REBAR-size-quirk-for-Sapphire-RX-56.patch"
                "0001-linux6.6.y-bore3.3.0.patch"
                "0032-Bluetooth-btusb-Add-a-new-PID-VID-0489-e0f6-for-MT7922.patch"
                "0035-Add_quirk_for_polling_the_KBD_port.patch"
                "0001-ACPI-resource-Skip-IRQ-override-on-ASUS-TUF-Gaming-A.patch"
                "0002-ACPI-resource-Skip-IRQ-override-on-ASUS-TUF-Gaming-A.patch"
                "v2-0005-platform-x86-asus-wmi-don-t-allow-eGPU-switching-.patch"
                "v2-0006-platform-x86-asus-wmi-add-safety-checks-to-gpu-sw.patch"
                "0038-mediatek-pci-reset.patch"
                "0040-workaround_hardware_decoding_amdgpu.patch"
                "0005-platform-x86-asus-wmi-don-t-allow-eGPU-switching-if-.patch"
                "0006-platform-x86-asus-wmi-add-safety-checks-to-gpu-switc.patch"
                "0001-platform-x86-asus-wmi-Support-2023-ROG-X16-tablet-mo.patch"
                "amd-tablet-sfh.patch"
                "v2-0002-ALSA-hda-cs35l41-Support-ASUS-2023-laptops-with-m.patch"
                "v6-0001-platform-x86-asus-wmi-add-support-for-ASUS-screen.patch"
                "sys-kernel_arch-sources-g14_files-0047-asus-nb-wmi-Add-tablet_mode_sw-lid-flip.patch"
                "sys-kernel_arch-sources-g14_files-0048-asus-nb-wmi-fix-tablet_mode_sw_int.patch"
              ]);
        }
        // (args.argsOverride or {}));
    linux_g14_6-5-8-arch1 = pkgs.callPackage linux_g14_6-5-8-arch1_pkg {};
    linux_g14_6-6-2-arch1 = pkgs.unstable.callPackage linux_g14_6-6-2-arch1_pkg {};
    linux_g14 = linux_g14_6-6-2-arch1;
  in
    pkgs.unstable.recurseIntoAttrs (pkgs.unstable.linuxPackagesFor linux_g14));

  services.supergfxd.enable = true;
  # - [Power Management nixos wiki](https://nixos.wiki/wiki/Power_Management)
  # echo XHC0 | sudo tee /proc/acpi/wakeup
  # asusd sleeps well works with this, tho wake up from sleep using power button
  services.asusd.enable = true;
  # - [disable wakeup for all pci devices](https://nixos.wiki/wiki/Power_Management#Troubleshooting)
  systemd.services.asusd-deepsleep = {
    wantedBy = ["multi-user.target"];
    serviceConfig = rec {
      Type = "oneshot";
      RemainAfterExit = "yes";
      # - [workarouund](https://bbs.archlinux.org/viewtopic.php?pid=1575617#p1575617)
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/echo XHC0 | ${pkgs.coreutils}/bin/tee /proc/acpi/wakeup'";
      ExecStop = ExecStart;
    };
  };

  # - [modify dsdt](https://gitlab.com/marcaux/g14-2021-s3-dsdt/-/blob/main/modify-dsdt.sh)
  # nix-shell -p acpica-tools pcre busybox
  # ./modify_dsdt.sh
  # boot.initrd.prepend = ["${./acpi_override.cpio}"];

  # Bootloader.
  # reinstall bootloader `sudo nixos-rebuild --install-bootloader switch`
  # - [Bootloader nix wiki](https://nixos.wiki/wiki/Bootloader)
  boot.loader = {
    systemd-boot.enable = false;
    # - [NixOS managed grub not detecting another distribution (Fedora) - Help - NixOS Discourse](https://discourse.nixos.org/t/nixos-managed-grub-not-detecting-another-distribution-fedora/5777)
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      efiSupport = true;
      devices = ["nodev"];
      useOSProber = true;
    };
  };

  # power consumption stuff
  # - [asus linux discord](https://discord.com/channels/725125934759411753/1166376689551548559)
  # sudo cat /sys/kernel/debug/dri/0/amdgpu_pm_info (look at 'average GPU')
  # sudo cat /sys/class/drm/card0/device/pp_dpm_sclk
  # cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_available_preferences
  # cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference
  # cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
  # 'sudo turbostat' (look at PkgWatt. it should be entire cpu's power consumption)

  # set the following in this same order for better battery
  # - [tlp nixoswiki](https://nixos.wiki/wiki/Laptop#tlp)
  #   - afaik tlp can also set this, but peeps over at asus-linux discord said no tlp is better
  # on battery
  # echo "powersave" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  # echo "power" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
  # idle 35% bright 60Hz -> 10W
  # idle 35% bright 165Hz -> 11W
  # idle 5% bright 60Hz -> 8W
  # 720p youtube 60Hz 5% bright -> 10W
  # 720p youtube 60Hz 35% bright -> 12W
  # 720p youtube 165Hz 35% bright -> 13W

  # on AC
  # echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
  # echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

  # xrandr -q (check available refresh rates)
  # xrandr -r 60 (change refresh rate)

  # wlr-randr --output eDP-1 --mode 2560x1600@60.001999Hz
  # wlr-randr --output eDP-1 --mode 2560x1600@165.001999Hz

  # check if on battery
  # cat /sys/class/power_supply/ADP0/online

  # - [nixpkgs acpid](https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/hardware/acpid.nix)
  services.acpid = {
    enable = true;

    # 'systemctl status acpid' to check logs
    # - [acpid archwiki](https://wiki.archlinux.org/title/Acpid#Determine_the_event)
    # - [ppd cli](https://discussion.fedoraproject.org/t/how-to-switch-profiles-of-power-profiles-daemon-automatically-on-kde-plasma/34071)
    handlers.on-power-change = {
      event = "ac_adapter/*";
      action = ''
        echo "on-power-change handler"

        vals=($1)  # space separated string to array of multiple values
        if [[ ''${vals[3]} == 00000000 ]]; then
          ${powerstate-sync-bat}/bin/powerstate-sync-bat
        else
          ${powerstate-sync-ac}/bin/powerstate-sync-ac
        fi
      '';
    };
  };
  # this runs too early
  # powerManagement.powerUpCommands = ''
  #   echo "power up command"
  #   ${powerstate-sync}/bin/powerstate-sync
  # '';

  # asusd anime stuff does not work after resume unless asusd is restarted (asusctl 4.7.1)
  powerManagement.resumeCommands = ''
    echo "resume started"
    ${pkgs.systemd}/bin/systemctl restart asusd
    echo "asusd restart command ended"
  '';

  # - [Laptop - NixOS Wiki](https://nixos.wiki/wiki/Laptop)
  # default (atleast in kde)
  services.power-profiles-daemon.enable = true;
  # powerManagement.powertop.enable = false;
  # services.auto-cpufreq.enable = false;
  services.tlp = {
        enable = false;
        settings = {
          # - [Laptop - NixOS Wiki](https://nixos.wiki/wiki/Laptop)
          # - [Processor — TLP 1.6 documentation](https://linrunner.de/tlp/settings/processor.html)
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

          CPU_MIN_PERF_ON_AC = 0;
          CPU_MAX_PERF_ON_AC = 100;
          CPU_MIN_PERF_ON_BAT = 0;
          CPU_MAX_PERF_ON_BAT = 20;

          CPU_BOOST_ON_AC = 1;
          CPU_BOOST_ON_BAT = 0;

          # CPU_DRIVER_OPMODE_ON_AC = "guided";
          # CPU_DRIVER_OPMODE_ON_BAT= "guided";
          # CPU_SCALING_MIN_FREQ_ON_AC = 0;
          # CPU_SCALING_MAX_FREQ_ON_AC = 9999999;
          # CPU_SCALING_MIN_FREQ_ON_BAT = 0;
          # CPU_SCALING_MAX_FREQ_ON_BAT = 2000000;
        };
  };

  # nvidia stuff
  # - [Nvidia - NixOS Wiki](https://nixos.wiki/wiki/Nvidia)
  # - [prime arch wiki](wiki.archlinux.org/title/PRIME)
  #   - check if gpu is active:
  #     - 'cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status'
  #     - suspended is gpu off. active is gpu on.
  #     - nvidia-smi

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # Modesetting is needed most of the time
    modesetting.enable = false;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    powerManagement.enable = true;
    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = true;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Do not disable this unless your GPU is unsupported or if you have a good reason to.
    open = false;
    # 'nvidia-smi -L' unable to determine device
    # some nvidia forums said to use non-open drivers

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      amdgpuBusId = "PCI:101:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  environment.systemPackages = with pkgs; [
    pciutils
    lsof
    lshw

    vulkan-tools
    glxinfo

    # - [nixpkgs turbostat](https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/turbostat/default.nix)
    linuxPackages.turbostat
    acpi

    powerstate-sync-ac
    powerstate-sync-bat
    powerstate-sync
  ];
}
