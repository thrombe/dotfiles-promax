{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "sd_mod" "sr_mod" "rtsx_pci_sdmmc"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/ad0ef280-0c6d-40fc-a5b6-6fe14b547bd2";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/68D7-B0A1";
    fsType = "vfat";
  };

  fileSystems."/mnt/blouk" = {
    device = "/dev/disk/by-uuid/4fbfc40c-9181-4599-9e23-e5de2082816a";
    fsType = "ext4";
  };

  fileSystems."/mnt/jaro" = {
    device = "/dev/disk/by-uuid/a5585e75-fdcd-4e79-91e7-f3eefb4b5188";
    fsType = "ext4";
  };

  # - [swap - NisOS wiki](https://nixos.wiki/wiki/Swap)
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 1024 * 16;
    }
  ];


  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp3s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp2s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Bootloader.
  boot.loader = {
    efi.canTouchEfiVariables = true;
    # detect other operating systems in grub
    # https://discourse.nixos.org/t/nixos-managed-grub-not-detecting-another-distribution-fedora/5777/2
    # https://github.com/NixOS/nixpkgs/issues/7406
    # - [Dual Booting NixOS and Windows - NixOS Wiki](https://nixos.wiki/wiki/Dual_Booting_NixOS_and_Windows)
    grub.efiSupport = true;
    grub.enable = true;
    grub.devices = ["nodev"];
    # find the efi partition uuid using 'lsblk' and 'ls -l /dev/disk/by-uuid/'
    grub.extraEntries = ''
      menuentry "Manjaro" --class manjaro --class os {
      	insmod part_gpt
      	insmod ext2
      	insmod fat
        insmod search_fs_uuid
        insmod chain
      	search --no-floppy --fs-uuid --set=root 68D7-B0A1
      	chainloader /EFI/Manjaro/grubx64.efi
      }
      menuentry "Windows" {
        insmod part_gpt
        insmod fat
        insmod search_fs_uuid
        insmod chain
        search --fs-uuid --set=root 68D7-B0A1
        chainloader /EFI/Microsoft/Boot/bootmgfw.efi
      }
    '';
  };

  # nvidia stuff
  # - [Nvidia - NixOS Wiki](https://nixos.wiki/wiki/Nvidia)

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # Modesetting is needed most of the time
    modesetting.enable = true;

    # Enable power management (do not disable this unless you have a reason to).
    # Likely to cause problems on laptops and with screen tearing if disabled.
    powerManagement.enable = true;

    # Use the NVidia open source kernel module (which isn't “nouveau”).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    open = false;

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

      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
