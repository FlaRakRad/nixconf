{ config, pkgs, lib, ... }:

{
  imports =
    [ # НЕ УДАЛЯЙТЕ ЭТУ СТРОКУ, она связывает конфиг с твоим железом
      ./hardware-configuration.nix
    ];

  # =========================================================================
  # ZSHELL
  # =========================================================================
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    promptInit = "";

    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  # =========================================================================
  # ЗАГРУЗЧИК И СИСТЕМА (rEFInd + скрытый systemd-boot)
  # =========================================================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = 0;
  boot.loader.efi.canTouchEfiVariables = true; # На десктопах UEFI обычно доступно для записи

  # Актуальное ядро Linux
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # =========================================================================
  # NIX GARBAGE COLLECTOR
  # =========================================================================
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };

  nix.settings.auto-optimise-store = true;

  # =========================================================================
  # NETWORK, BLUETOOTH, LOCALES, MDNS (AVAHI)
  # =========================================================================
  networking.hostName = "nixos-desktop";
  networking.networkmanager.enable = true;

  # Включение mDNS (Avahi)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  # ФАЕРВОЛ
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 25565 ];
    allowedUDPPorts = [ 25565 44452 5353 ];
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Timezone, locales
  time.timeZone = "Europe/Kyiv";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "uk_UA.UTF-8/UTF-8"
    "ru_RU.UTF-8/UTF-8"
  ];

  # Console font
  console = {
    font = "Lat2-TermMinus16";
    keyMap = "us";
  };

  # =========================================================================
  # HARDWARE (AMD CPU + AMD/NVIDIA GPU)
  # =========================================================================
  hardware.cpu.amd.updateMicrocode = true;

  # Графика (OpenGL / Vulkan / VA-API) для AMD и NVIDIA
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # Поддержка NVIDIA (драйвер и гибридные настройки/Wayland)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false; # Для десктопа лучше выключить
    open = false; # Используем проприетарный драйвер (можно поставить true, если карточка из серии RTX)
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Display manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Переменные среды для Wayland / Electron
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    # Принудительное использование дискретной видеокарты или общие пути для Wine
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  # =========================================================================
  # SECURITY (SUDO)
  # =========================================================================
  security.sudo = {
    enable = true;
    extraRules = [{
      users = [ "tabarejka" ];
      commands = [{
        command = "ALL";
        options = [ "NOPASSWD" ];
      }];
    }];
  };

  # =========================================================================
  # AUDIO (PipeWire)
  # =========================================================================
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # =========================================================================
  # USERS tabarejka
  # =========================================================================
  users.users.tabarejka = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "tabarejka";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" ];
    packages = with pkgs; [
      viber
      ayugram-desktop
      vesktop
      qbittorrent
      sioyek
      spotify
      obs-studio
      kdePackages.kalzium
      avogadro2
      jetbrains.pycharm-oss
      python3
      jetbrains.jdk
      kicad
    ];
  };

  # =========================================================================
  # REPO SETTINGS
  # =========================================================================
  nixpkgs.config.allowUnfree = true;

  # =========================================================================
  # GAYMING
  # =========================================================================
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };

  programs.gamemode.enable = true;

  # =========================================================================
  # SYS PKGS
  # =========================================================================
  environment.systemPackages = with pkgs; [
    refind
    efibootmgr
    kitty
    rofi
    waybar
    firefox
    dunst
    swww
    xdg-desktop-portal-hyprland
    hyprland-per-window-layout
    brightnessctl
    git
    usbutils
    vim
    neovim
    fastfetch
    btop
    sqlite
    gnumake
    arduino-ide
    rpi-imager
    openssl
    nodejs
    clang-tools     
    pkgsCross.avr.buildPackages.gcc
    pkgsCross.avr.buildPackages.binutils
    avrdude
    openocd
    pkgsCross.avr.buildPackages.gdb
    simavr
    gdb
    gcc-arm-embedded
    picotool
    minicom     
    grim
    slurp
    swappy
    wl-clipboard
    pavucontrol
    gcc
    clang
    cargo
    rustc
    jdk21     
    wget
    curl
    librsvg
    spicetify-cli
  ];

  # =========================================================================
  # SYS DAEMONS AND SYS VERSION
  # =========================================================================
  services.dbus.enable = true;
  services.flatpak.enable = true;
  services.zerotierone.enable = true;

  # Version NixOS. DO NOT TOUCH!.
  system.stateVersion = "24.11";
}
