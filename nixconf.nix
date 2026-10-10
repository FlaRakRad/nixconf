# /etc/nixos/configuration.nix

{ config, pkgs, lib, ... }:

{
  imports =
    [ # DO NOT CHANGE
      ./hardware-configuration.nix
    ];

  # =========================================================================
  # OVERLAYS & WRAPPERS (Fix Viber SSL & Environment)
  # =========================================================================
  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    (final: prev: {
      viber = prev.viber.overrideAttrs (oldAttrs: {
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ prev.makeWrapper ];
        postInstall = (oldAttrs.postInstall or "") + ''
          wrapProgram $out/bin/viber \
            --set SSL_CERT_FILE "/etc/ssl/certs/ca-certificates.crt" \
            --set NIX_SSL_CERT_FILE "/etc/ssl/certs/ca-certificates.crt" \
            --set SSL_CERT_DIR "/etc/ssl/certs"
        '';
      });
    })
  ];

  # =========================================================================
  # ZSHELL & POWERLEVEL10K
  # =========================================================================
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    # Автоматична ініціалізація Powerlevel10k
    promptInit = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
    '';
  };

  # =========================================================================
  # FONTS (JetBrains Mono Nerd Font)
  # =========================================================================
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # =========================================================================
  # KITTY CONFIG 
  # =========================================================================
  environment.etc."xdg/kitty/kitty.conf".text = ''
    font_family      JetBrainsMono Nerd Font Mono
    bold_font        auto
    italic_font      auto
    bold_italic_font auto
    font_size        12.0

    foreground           #cdd6f4
    background           #1e1e2e
    selection_foreground #1e1e2e
    selection_background #f5e0dc

    cursor               #f5e0dc
    cursor_shape         block
    cursor_beam_thickness 1.5

    background_opacity   0.95
    window_padding_width 10
    hide_window_decorations no

    tab_bar_style        powerline
    active_tab_foreground   #11111b
    active_tab_background   #cba6f7

    map ctrl+equal change_font_size all +2.0
    map ctrl+minus change_font_size all -2.0
    map ctrl+t new_tab
    map ctrl+w close_tab
  '';

  # =========================================================================
  # BOOTLOADER & KERNEL
  # =========================================================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = 0;
  boot.loader.efi.canTouchEfiVariables = false;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Microcode
  hardware.cpu.intel.updateMicrocode = true;

  # Power Management & Thunderbolt
  boot.kernelParams = [ 
    "usbcore.autosuspend=-1" 
    "typec.autosuspend=0"
  ];

  services.hardware.bolt.enable = true;

  # Sysctl
  boot.kernel.sysctl."vm.max_map_count" = 2147483642;

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
  # NETWORK, BLUETOOTH, LOCALES, FIREWALL
  # =========================================================================
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Статична IP для Raspberry Pi (enp0s31f6)
  networking.interfaces.enp0s31f6.ipv4.addresses = [{
    address = "10.0.0.1";
    prefixLength = 24;
  }];

  # mDNS (Avahi)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  # Фаєрвол
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 25565 4244 5242 5243 7985 5252 ];
    allowedUDPPorts = [ 25565 44452 5353 4244 5242 5243 7985 5252 ];
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Timezone & Locales
  time.timeZone = "Europe/Kyiv";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "uk_UA.UTF-8/UTF-8"
    "ru_RU.UTF-8/UTF-8"
    "it_IT.UTF-8/UTF-8"
  ];

  # Console (TTY)
  console = {
    font = "Lat2-TermMinus16";
    keyMap = "us";
  };

  # =========================================================================
  # GRAPHICS, DISPLAY MANAGER, HYPRLAND
  # =========================================================================
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
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

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    VULKAN_SDK = "${pkgs.vulkan-headers}";
    VK_LAYER_PATH = "${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d";
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
  # USERS
  # =========================================================================
  users.users.tabarejka = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "tabarejka";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" "libvirtd" "kvm" ];
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
      freecad
    ];
  };

  # =========================================================================
  # GAMING
  # =========================================================================
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
    gamescopeSession.enable = true;
  };

  programs.gamemode.enable = true;

  # =========================================================================
  # SYSTEM PACKAGES
  # =========================================================================
  envir
