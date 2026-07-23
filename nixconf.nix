# /etc/nixos/configuration.nix

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
  boot.loader.efi.canTouchEfiVariables = false;

  # Ядро посвежее для встроенной графики Intel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # =========================================================================
  # POWER MANAGEMENT & THUNDERBOLT MAX POWER (Для постоянной отдачи питания на RPi 5)
  # =========================================================================
  # Полностью отключаем усыпление USB/Thunderbolt на уровне ядра Linux
  boot.kernelParams = [ 
    "usbcore.autosuspend=-1" 
    "typec.autosuspend=0"
  ];

  # Включаем службу управления Thunderbolt, чтобы контроллер всегда был активен
  services.hardware.bolt.enable = true;

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
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Статический IP для прямого подключения Raspberry Pi по Ethernet (enp0s31f6)
  networking.interfaces.enp0s31f6.ipv4.addresses = [{
    address = "10.0.0.1";
    prefixLength = 24;
  }];

  # Включение mDNS (Avahi) для поиска устройств .local (Raspberry Pi)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  # НАСТРОЙКА ФАЕРВОЛА ДЛЯ ИГРЫ ПО СЕТИ И MDNS
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 25565 ];             # Стандартный порт Minecraft
    allowedUDPPorts = [ 25565 44452 5353 ];  # Порт майна + LAN + mDNS (5353)
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
  # GRAPHICS (Intel i5-8350U), DISPLAY MANAGER, AND HYPRLAND
  # =========================================================================
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # 32Bit libs
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
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

  # Var Wayland / Electron
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    # Libs for Wine / Proton
    LD_LIBRARY_PATH = lib.mkForce (lib.concatStringsSep ":" [
      "${pkgs.libunwind}/lib"
      "${pkgs.freetype}/lib"
      "${pkgs.libglvnd}/lib"
      "${pkgs.vulkan-loader}/lib"
      "${pkgs.alsa-lib}/lib"
      "${pkgs.glib.out}/lib"
      "${pkgs.libpulseaudio}/lib"
      "${pkgs.wayland}/lib"
      "${pkgs.xorg.libX11}/lib"
      "${pkgs.xorg.libXext}/lib"
      "${pkgs.libxkbcommon}/lib"
      "${pkgs.udev}/lib"
      "${pkgs.gst_all_1.gstreamer}/lib"
      "${pkgs.gnutls}/lib"
      "${pkgs.xorg.libXinerama}/lib"
      "/nix/store/0dzsg0f8id2yki5vqd6zgfrwmb4cf8cd-pipewire-1.4.9-jack/lib"
    ]);
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
      # Internet and social media
      viber
      ayugram-desktop
      vesktop
      qbittorrent
      sioyek

      # Music and multimedia
      spotify
      obs-studio

      # Chemical
      kdePackages.kalzium
      avogadro2

      # Developing
      jetbrains.pycharm-oss
      python3
      jetbrains.jdk

      # Embedded
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

  # GameMode — turbo-boost
  programs.gamemode.enable = true;

  # =========================================================================
  # SYS PKGS
  # =========================================================================
  environment.systemPackages = with pkgs; [
    # bootloader
    refind
    efibootmgr

    # Var for Hyprland
    kitty
    rofi
    waybar
    firefox
    dunst
    swww
    xdg-desktop-portal-hyprland
    hyprland-per-window-layout
    brightnessctl

    # Sys soft, CLI progs
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

    # nvim environment
    nodejs
    clang-tools    

    # AVR toolchain
    pkgsCross.avr.buildPackages.gcc
    pkgsCross.avr.buildPackages.binutils
    avrdude
    openocd
    pkgsCross.avr.buildPackages.gdb
    simavr
    gdb

    # arm toolchain
    gcc-arm-embedded
    picotool
    minicom
    
    # Screenshots
    grim
    slurp
    swappy
    wl-clipboard

    # Audio control
    pavucontrol

    # Compilers / interpreters
    gcc
    clang
    cargo
    rustc
    jdk21
    
    # Package managers
    wget
    curl
    librsvg

    # Альтернативный инструмент для кастомизации и блокировки рекламы в Spotify
    spicetify-cli
  ];

  # =========================================================================
  # SYS DAEMONS AND SYS VERSION
  # =========================================================================
  services.dbus.enable = true;
  services.flatpak.enable = true;

  # ВКЛЮЧАЕМ СЛУЖБУ ZEROTIER
  services.zerotierone.enable = true;

  # Настройка энергосбережения TLP (сохраняем пороги батареи + отключаем засыпание USB)
  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = 75;
      START_CHARGE_THRESH_BAT1 = 75;

      STOP_CHARGE_THRESH_BAT0 = 80;
      STOP_CHARGE_THRESH_BAT1 = 80;

      RESTORE_THRESHOLDS_ON_BAT = 1;
      NATACPI_ENABLE = 1;

      # Запрещаем TLP выключать питание на USB-портах
      USB_AUTOSUSPEND = 0;
    };
  };

  # Version NixOS. DO NOT TOUCH!.
  system.stateVersion = "24.11";
}
