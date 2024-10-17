{
  config,
  pkgs,
  lib,
  modulesPath,
  username,
  ...
}: let
  tags = ["ga402xu"];

  get-session = pkgs.writeShellScriptBin "get-session" ''
    status="$(${pkgs.systemd}/bin/loginctl | ${pkgs.busybox}/bin/grep '${username}' | ${pkgs.busybox}/bin/awk '{print $1}')"
    session="$(${pkgs.systemd}/bin/loginctl show-session $status -p Type)"
    echo $session
  '';
  is-wayland = pkgs.writeShellScriptBin "is-wayland" ''
    session="$(${get-session}/bin/get-session)"
    if [[ "$session" == *"wayland"* ]]; then
      echo 1
    else
      echo 0
    fi
  '';
  is-x11 = pkgs.writeShellScriptBin "is-x11" ''
    session="$(${get-session}/bin/get-session)"
    if [[ "$session" == *"x11"* ]]; then
      echo 1
    else
      echo 0
    fi
  '';

  # TODO: powerstate commands are completely broken
  # wlr-randr does not work with sudo
  powerstate-sync-ac = pkgs.writeShellScriptBin "powerstate-sync-ac" ''
    echo "setting ac power settings"

    if [[ "$(${is-wayland}/bin/is-wayland)" == "1" ]]; then
      echo "powerstate wayland"

      ${pkgs.wlr-randr}/bin/wlr-randr --output eDP-1 --mode 2560x1600@165.001999Hz
    else
      echo "powerstate x11"

      # - [xrandr cannot open display](https://bbs.archlinux.org/viewtopic.php?id=122848)
      export XAUTHORITY=/home/${username}/.Xauthority
      export DISPLAY=:0

      ${pkgs.xorg.xrandr}/bin/xrandr -r 165
    fi

    ${pkgs.coreutils}/bin/echo "balance_performance" | ${pkgs.coreutils}/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
    # NOTE: performance scaling_governer is too aggressive. powersave is fine
    ${pkgs.coreutils}/bin/echo "powersave" | ${pkgs.coreutils}/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

    # ${pkgs.asusctl}/bin/asusctl profile --profile-set balanced
    ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set balanced
  '';
  powerstate-sync-bat = pkgs.writeShellScriptBin "powerstate-sync-bat" ''
    echo "setting battery power settings"

    if [[ "$(${is-wayland}/bin/is-wayland)" == "1" ]]; then
      echo "powerstate wayland"

      ${pkgs.wlr-randr}/bin/wlr-randr --output eDP-1 --mode 2560x1600@60.001999Hz
    else
      echo "powerstate x11"

      # - [xrandr cannot open display](https://bbs.archlinux.org/viewtopic.php?id=122848)
      export XAUTHORITY=/home/${username}/.Xauthority
      export DISPLAY=:0

      ${pkgs.xorg.xrandr}/bin/xrandr -r 60
    fi

    ${pkgs.coreutils}/bin/echo "powersave" | ${pkgs.coreutils}/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
    ${pkgs.coreutils}/bin/echo "power" | ${pkgs.coreutils}/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference

    # ${pkgs.asusctl}/bin/asusctl profile --profile-set quiet
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

  boot.kernelParams = [
    "mem_sleep_default=deep"

    # - [hyprland nvidia](https://wiki.hyprland.org/0.42.0/Nvidia/)
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "nvidia_drm.fbdev=1"
  ];

  # select patched linux kernel
  # - [Linux kernel nix wiki](https://nixos.wiki/wiki/Linux_kernel)
  boot.kernelPackages = pkgs.lib.mkDefault (let
    fedora-asus-kernel = {buildLinux, ...} @ args:
      buildLinux (args
        // rec {
          version = "6.11";
          extraMeta.branch = "6.11";
          modDirVersion = "6.11.0";

          # extraConfig = "${fedora-40-asus-kernel-source}/package/kernel-x86_64-fedora.config";

          src = pkgs.stdenv.mkDerivation rec {
            name = "linux-source";
            inherit version;

            # - [lukenukem/asus-kernel](https://copr.fedorainfracloud.org/coprs/lukenukem/asus-kernel/package/kernel/)
            # - [/results/lukenukem/asus-kernel/fedora-40-x86_64/07623253-kernel/](https://download.copr.fedorainfracloud.org/results/lukenukem/asus-kernel/fedora-40-x86_64/07623253-kernel/)
            # - [kernel build logs](https://download.copr.fedorainfracloud.org/results/lukenukem/asus-kernel/fedora-40-x86_64/07623253-kernel/builder-live.log.gz)
            src = builtins.fetchurl {
              url = "https://download.copr.fedorainfracloud.org/results/lukenukem/asus-kernel/fedora-41-x86_64/08026916-kernel/kernel-6.11.0-666.rog.fc41.src.rpm";
              sha256 = "sha256:1zs8shim3mc536j8jj9nman6g7mj2fpxn8ndcpmcdnm5y7jjqf4p";
            };

            phases = ["unpackPhase" "patchPhase"];
            unpackPhase = ''
              ${pkgs.rpm}/bin/rpm2cpio $src | ${pkgs.cpio}/bin/cpio -idmv

              mkdir $out
              mv ./* $out
              cd $out
              tar -xf $out/linux-${version}.tar.xz --strip-components 1 -C $out/.
            '';

            patchPhase = ''
              # apply all patches
              # ${pkgs.fd}/bin/fd -t f -e patch . > ./patches.txt
              patch -p1 -F50 < ./patch-6.11-redhat.patch
              patches=$(grep "^ApplyOptionalPatch " ./kernel.spec | grep -v "{patchversion}" | cut -d " " -f2)
              for patch in $patches; do
                patch -p1 -F50 < ./$patch
              done

              # ./Makefile.rhelver is not included in the kernel.dev package. so make sure it is not needed at all
              # inject RHEL stuff directly into the makefile
              cd $out
              var1="# Set RHEL variables"
              TOTAL_LINES=`cat ./Makefile | wc -l`
              BEGIN_LINE=`grep -n -e "$var1" ./Makefile | cut -d : -f 1`
              BEGIN_LINE=$(($BEGIN_LINE - 1))
              TAIL_LINES=$(($TOTAL_LINES - $BEGIN_LINE - 11))

              head -n $BEGIN_LINE ./Makefile > ./Makefile2
              cat ./Makefile.rhelver >> ./Makefile2
              tail -n $TAIL_LINES ./Makefile >> ./Makefile2
              mv ./Makefile2 ./Makefile
            '';
          };
          kernelPatches = [];
          # kernelPatches = map (x: {
          #     name = x;
          #     patch = "${src}/${x}";
          # }) [
          #   # patches are listed in rpm package kernel.spec
          #   # - [kernel.spec](https://copr-dist-git.fedorainfracloud.org/cgit/lukenukem/asus-kernel/kernel.git/tree/kernel.spec?id=5af4c495d3fb0cfed91e457308be4598ba4af95a#n1830)
          #   # "patch-6.9-redhat.patch"
          #   # ...
          # ];
          # kernelPatches = let
          #   names = pkgs.lib.strings.split "\n" (builtins.readFile "${fedora-40-asus-kernel-source}/patches.txt");
          #   filtered-names = pkgs.lib.lists.filter (e: ! (e == "" || e == [])) names;
          #   patches = map (x: {
          #     name = x;
          #     patch = "${src}/${x}";
          #   }) filtered-names;
          # in patches;
        }
        // (args.argsOverride or {}));

    linux_g14_6-9-6-arch1_pkg = {
      fetchzip,
      fetchurl,
      buildLinux,
      ...
    } @ args:
    # - [buildLinux](https://github.com/NixOS/nixpkgs/blob/a6207181cf6300566bc15f38cf8e4d4c7ce6bc90/pkgs/top-level/linux-kernels.nix#L676)
      buildLinux (args
        // rec {
          version = "6.9.6-arch1";
          extraMeta.branch = "6.9";
          modDirVersion = version;

          # - [howto linux configuration](https://linuxconfig.org/in-depth-howto-on-linux-kernel-configuration)
          # - [common-config nix linux kernel](https://github.com/NixOS/nixpkgs/blob/4f4312a71cd8129620af1d004f54b7056012e21a/pkgs/os-specific/linux/kernel/common-config.nix#L35)
          # as i understand it, this can be disabled as nix uses it's own configs if not specified.
          #   - [](https://github.com/NixOS/nixpkgs/blob/bd406645637326b1538a869cd54cc3fdf17e975a/pkgs/os-specific/linux/kernel/generic.nix#L133)
          # defconfig = "${patches}/config";
          # extraConfig = "${patches}/config";

          src = fetchzip {
            # - [linux source code](https://cdn.kernel.org/pub/linux/kernel/v6.x/)
            # - [git archlinux releases](https://github.com/archlinux/linux/releases)
            url = let
              rev = "ec7189215b04f825c0cef51fa102b8f521eb3bf5";
            in "https://github.com/archlinux/linux/archive/${rev}.zip";
            sha256 = "sha256-3NhsaIXFLP2+4Y+vYhzHGeJdgT5hz1Pz+2nf+/BKq50=";
          };

          # go to the PKGBUILD file of the arch package and copy all patches from 'source' in the same order
          kernelPatches = let
            # - [linux-g14 6.5.8-arch1]https://aur.archlinux.org/packages/linux-g14)
            # - [applying patches to kernel](https://www.kernel.org/doc/html/v4.11/process/applying-patches.html)
            # patch -p1 < ./name.patch
            patches = builtins.fetchTarball {
              url = let
                rev = "ca794d215234324a098d3095db5e2fb404a51bd6";
              in "https://aur.archlinux.org/cgit/aur.git/snapshot/aur-${rev}.tar.gz";
              sha256 = "sha256:1vm69zd223bici4sl8l1rq971909y4zx9xzr7w0mb119gcyw012c";
            };
          in
            [
              {
                patch = fetchurl {
                  name = "sys-kernel_arch-sources-g14-6.8+--more-uarches-for-kernel.patch";
                  url = "https://raw.githubusercontent.com/graysky2/kernel_compiler_patch/30db2170d3ddefa13a3dcffd05db66efff2fea7d/more-uarches-for-kernel-6.8-rc4+.patch";
                  sha256 = "sha256-9Of80BHyaRhA0sjCNh3KhQp46jPMXCTS4nw+ApT9HcU=";
                };
              }
              {
                patch = fetchurl {
                  name = "0001-sched-ext.patch";
                  url = "https://raw.githubusercontent.com/CachyOS/kernel-patches/97d61eeeab14589187757e923f4207a6a2a932ea/6.9/sched/0001-sched-ext.patch";
                  sha256 = "sha256-tuWbQq6W1pQwqnjl98UhLiCS56F6nNZ1dcdteaaPKOE=";
                };
              }
            ]
            ++ (map (x: {
                name = x;
                patch = "${patches}/${x}";
              }) [
                "0001-acpi-proc-idle-skip-dummy-wait.patch"

                "0001-v4-platform-x86-asus-wmi-add-support-for-2024-ROG-Mini-LED.patch"
                "0002-v4-platform-x86-asus-wmi-add-support-for-Vivobook-GPU-MUX.patch"
                "0003-v4-platform-x86-asus-wmi-add-support-variant-of-TUF-RGB.patch"
                "0004-v4-platform-x86-asus-wmi-support-toggling-POST-sound.patch"
                "0005-v4-platform-x86-asus-wmi-store-a-min-default-for-ppt-op.patch"
                "0006-v4-platform-x86-asus-wmi-adjust-formatting-of-ppt-fcts.patch"
                "0007-v4-platform-x86-asus-wmi-ROG-Ally-increase-wait-time.patch"
                "0008-v4-platform-x86-asus-wmi-add-support-for-MCU-powersave.patch"
                "0009-v4-platform-x86-asus-wmi-add-clean-up-structs.patch"

                "0001-HID-asus-fix-more-n-key-report-descriptors-if-n-key-.patch"
                "0001-platform-x86-asus-wmi-add-support-for-vivobook-fan-p.patch"
                "0002-HID-asus-make-asus_kbd_init-generic-remove-rog_nkey_.patch"
                "0003-HID-asus-add-ROG-Ally-N-Key-ID-and-keycodes.patch"
                "0004-HID-asus-add-ROG-Z13-lightbar.patch"

                "0001-platform-x86-asus-wmi-add-debug-print-in-more-key-pl.patch"
                "0002-platform-x86-asus-wmi-don-t-fail-if-platform_profile.patch"
                "0003-asus-bios-refactor-existing-tunings-in-to-asus-bios-.patch"
                "0004-asus-bios-add-panel-hd-control.patch"
                "0005-asus-bios-add-dgpu-tgp-control.patch"
                "0006-asus-bios-add-apu-mem.patch"
                "0007-asus-bios-add-core-count-control.patch"
                "v2-0001-hid-asus-use-hid-for-brightness-control-on-keyboa.patch"

                "0027-mt76_-mt7921_-Disable-powersave-features-by-default.patch"

                "0032-Bluetooth-btusb-Add-a-new-PID-VID-0489-e0f6-for-MT7922.patch"
                "0035-Add_quirk_for_polling_the_KBD_port.patch"

                "0001-ACPI-resource-Skip-IRQ-override-on-ASUS-TUF-Gaming-A.patch"
                "0002-ACPI-resource-Skip-IRQ-override-on-ASUS-TUF-Gaming-A.patch"

                "0038-mediatek-pci-reset.patch"
                "0040-workaround_hardware_decoding_amdgpu.patch"

                "amd-tablet-sfh.patch"

                # "0001-sched-ext.patch"::"https://raw.githubusercontent.com/cachyos/kernel-patches/master/6.9/sched/0001-sched-ext.patch"

                "sys-kernel_arch-sources-g14_files-0047-asus-nb-wmi-Add-tablet_mode_sw-lid-flip.patch"
                "sys-kernel_arch-sources-g14_files-0048-asus-nb-wmi-fix-tablet_mode_sw_int.patch"
              ]);
        }
        // (args.argsOverride or {}));
    # linux_g14 = pkgs.callPackage linux_g14_6-9-6-arch1_pkg {};
    linux_g14 = pkgs.callPackage fedora-asus-kernel {};
  in
    pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_g14));

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
  # - [CPU frequency scaling - ArchWiki](https://wiki.archlinux.org/title/CPU_frequency_scaling)
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

    # handlers.on-lid-open = {
    #   event = "??";
    #   action = ''
    #     echo "on-lid-open handler"
    #     ${powerstate-sync}/bin/powerstate-sync
    #   '';
    # };
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

  # # - [wireplumber camera battery issue (likely to be fixed in a while)](https://old.reddit.com/r/linux/comments/1em8biv/psa_pipewire_has_been_halving_your_battery_life/)
  # services.pipewire.wireplumber.extraConfig = {
  #   "10-disable-camera" = {
  #     "wireplumber.profiles" = {
  #       main = {
  #         "monitor.libcamera" = "disabled";
  #       };
  #     };
  #   };
  # };

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
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      # CPU_SCALING_GOVERNOR_ON_AC = "performance";
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
    modesetting.enable = true;

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
    open = true;
    # if 'nvidia-smi -L' unable to determine device
    # some nvidia forums said to use non-open drivers

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    # - [nvidia-setting broken](https://github.com/TLATER/dotfiles/blob/0310be00fda729b4880ec55e48eb4f81d4ed0b75/nixos-config/hosts/yui/nvidia/default.nix#L17)
    # nvidiaSettings = lib.mkForce false;
    nvidiaSettings = true;

    # package = config.boot.kernelPackages.nvidiaPackages.production;
    # - [TLATER nix config](https://github.com/TLATER/dotfiles/blob/9122f514f747f4366b26ebc12573403ea87685f4/nixos-config/hosts/yui/nvidia/default.nix#L12)
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "555.58.02";
      sha256_64bit = "sha256-xctt4TPRlOJ6r5S54h5W6PT6/3Zy2R4ASNFPu8TSHKM=";
      sha256_aarch64 = "sha256-8hyRiGB+m2hL3c9MDA/Pon+Xl6E788MZ50WrrAGUVuY=";
      openSha256 = "sha256-8hyRiGB+m2hL3c9MDA/Pon+Xl6E788MZ50WrrAGUVuY=";
      settingsSha256 = "sha256-ZpuVZybW6CFN/gz9rx+UJvQ715FZnAOYfHn5jt5Z2C8=";
      persistencedSha256 = "sha256-xctt4TPRlOJ6r5S54h5W6PT6/3Zy2R4ASNFPu8TSHKM=";
    };
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
    get-session
    is-wayland
    is-x11
  ];
}
