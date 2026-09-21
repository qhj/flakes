{
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "uas" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/mapper/luks";
    fsType = "btrfs";
    options = [
      "subvol=@"
      "compress-force=zstd:1"
      "noatime"
    ];
  };

  boot.initrd.luks.devices."luks".device = "/dev/disk/by-uuid/2337625f-eb44-4f25-be5c-710cc37755ed";

  fileSystems."/nix" = {
    device = "/dev/mapper/luks";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "compress-force=zstd:1"
      "noatime"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/mapper/luks";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress-force=zstd:1"
      "noatime"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/06A3-1A1F";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
