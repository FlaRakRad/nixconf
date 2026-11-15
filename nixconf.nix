{ config, pkgs, lib, ... }:

{
  imports = [
    # DO NOT CHANGE
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

    promptInit = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
      typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
    '';
  };

  # =========================================================================
  # FONTS (JetBrains Mono Nerd Font)
  # =========================================================================
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # =========================================================================
  # KITTY CONFIG (Оптимизация ресайза, кэша и шрифтов)
  # =========================================================================
  environment.etc."xdg/kitty/kitty.conf".text = ''
    font_family JetBrainsMono Nerd Font Mono
    bold_font auto
    italic_font auto
    bold_italic_font auto
    font_size 12.0

    repaint_delay 10
    input_delay 2
    sync_to_monitor yes

    scrollback_lines 10000
    scrollback_pager_history_size 256

    resize_debounce_time 0.05
    resize_draw_strategy static
    remember_window_size no

    update_check_interval 0
    enable_audio_bell no

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
  # ИНТЕРФЕЙС НОЖНИЦ HyDE (Satty Catppuccin Mocha + Sharp Borders)
  # =========================================================================
  environment.etc."xdg/satty/config.toml".text = ''
    [general]
    fullscreen = false
    early-exit = true
    corner-roundness = 0

    [font]
    family = "JetBrainsMono Nerd Font"
    style = "Bold"

    [color-palette]
    palette = [
      "#f38ba8ff",
      "#fab387ff",
      "#f9e2afff",
      "#a6e3a1ff",
      "#89dcebff",
      "#89b4faff",
      "#b4befeff",
      "#cba6f7ff",
      "#cdd6f4ff",
      "#11111bff"
    ]
  '';

  environment.etc."xdg/satty/style.css".text = ''
    window {
      background-color: #1e1e2e;
      color: #cdd6f4;
    }

    .toolbar, headerbar {
      background-color: #181825;
      border: 2px solid #313244;
      border-radius: 0px;
      padding: 4px;
    }

    button {
      background-color: #313244;
      color: #cdd6f4;
      border-radius: 0px;
      border: 1px solid #45475a;
      padding: 6px 10px;
      margin: 2px;
    }

    button:hover {
      background-color: #45475a;
      border-color: #b4befe;
      color: #ffffff;
    }

    button:checked, button:active {
      background-color: #b4befe;
      color: #11111b;
      border-color: #b4befe;
    }
  '';

  # =========================================================================
  # BOOTLOADER & KERNEL (МАКСИМАЛЬНЫЙ ЭНЕРГОСБЕРЕГАЮЩИЙ РЕЖИМ ДЛЯ T480)
  # =========================================================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = 0;
  boot.loader.efi.canTouchEfiVariables = false;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  hardware.cpu.intel.updateMicrocode = true;

  boot.kernelParams = [
    "pcie_aspm=force"
    "snd_hda_intel.power_save=1"
    "snd_hda_intel.power_save_controller=Y"
    "nmi_watchdog=0"
    "i915.enable_fbc=1"
    "i915.enable_psr=1"
  ];

  services.hardware.bolt.enable = true;

  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;
    "vm.dirty_writeback_centisecs" = 6000;
  };

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

  networking.interfaces.enp0s31f6.ipv4.addresses = [{
    address = "10.0.0.1";
    prefixLength = 24;
  }];

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 25565 4244 5242 5243 7985 5252 ];
    allowedUDPPorts = [ 25565 44452 5353 4244 5242 5243 7985 5252 ];
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    settings = {
      General = {
        Experimental = true;
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  time.timeZone = "Europe/Kyiv";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "uk_UA.UTF-8/UTF-8"
    "ru_RU.UTF-8/UTF-8"
  ];

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
    MOZ_ENABLE_WAYLAND = "1";
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
  # AUDIO (PipeWire & WirePlumber)
  # =========================================================================
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
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
      qbittorrent
      (discord.override { withVencord = true; })
      sioyek
      openboard
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
  environment.systemPackages = with pkgs; [
    grim
    slurp
    satty
    wl-clipboard
    libnotify
    imagemagick
    xdg-utils
    cliphist
    powertop

    # --- ПУЛ ТЕРМИНАЛА (0 ms) ---
    (pkgs.writeShellScriptBin "spawn-terminal" ''
      POOL_ADDR=$(hyprctl clients -j | jq -r '.[] | select(.class == "kitty-pool" and (.workspace.name | startswith("special:pool"))) | .address' | head -n 1)
      ACTIVE_WS=$(hyprctl activeworkspace -j | jq -r '.id')

      if [ -n "$POOL_ADDR" ] && [ "$POOL_ADDR" != "null" ]; then
          hyprctl dispatch movetoworkspace "$ACTIVE_WS,address:$POOL_ADDR" >/dev/null 2>&1
          hyprctl dispatch focuswindow "address:$POOL_ADDR" >/dev/null 2>&1
          hyprctl dispatch exec "[workspace special:pool silent] kitty --class kitty-pool" >/dev/null 2>&1
      else
          kitty &
          hyprctl dispatch exec "[workspace special:pool silent] kitty --class kitty-pool" >/dev/null 2>&1
      fi
    '')

    # --- УМНОЕ ПЕРЕКЛЮЧЕНИЕ ФУЛЛСКРИНА И WAYBAR ---
    (pkgs.writeShellScriptBin "toggle-fullscreen" ''
      hyprctl dispatch fullscreen 0
      pkill -SIGUSR1 waybar
    '')

    (pkgs.writeShellScriptBin "waybar-fullscreen-toggle" ''
      IS_FS=$(hyprctl activewindow -j | jq -r '.fullscreen')
      if [ "$IS_FS" = "1" ] || [ "$IS_FS" = "2" ]; then
          pkill -SIGUSR1 waybar
      fi
    '')

    # --- МЕНЮ БУФЕРА ОБМЕНА (10 ПОСЛЕДНИХ) ---
    (pkgs.writeShellScriptBin "cliphist-menu" ''
      ITEM=$(cliphist list | head -n 10 | rofi -dmenu -p "Clipboard" -theme-str 'window {width: 32em; border-radius: 0px;}')
      if [ -n "$ITEM" ]; then
          echo "$ITEM" | cliphist decode | wl-copy
          notify-send -a "Clipboard" "Copied to clipboard" "$(echo "$ITEM" | cut -d' ' -f2- | head -c 50)..."
      fi
    '')

    # --- БЫСТРЫЙ СКРИПТ СКРИНШОТОВ ---
    (pkgs.writeShellScriptBin "screenshot" ''
      save_dir="''${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
      mkdir -p "$save_dir"
      save_path="''${save_dir}/$(date +'%y%m%d_%Hh%Mm%Ss_screenshot.png')"
      temp_file=$(mktemp /tmp/shot_XXXXXX.png)
      rm -f "$save_path"

      case "$1" in
          s|sf) grim -g "$(slurp)" "$temp_file" || { rm -f "$temp_file"; exit 1; } ;;
          m)    grim -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')" "$temp_file" || { rm -f "$temp_file"; exit 1; } ;;
          p)    grim "$temp_file" || { rm -f "$temp_file"; exit 1; } ;;
          *)    echo "Usage: screenshot {s|sf|m|p}"; rm -f "$temp_file"; exit 1 ;;
      esac

      satty --filename "$temp_file" --output-filename "$save_path"

      if [ -f "$save_path" ]; then
          wl-copy < "$save_path"
          notify-send -a "HyDE Alert" -i "$save_path" "Screenshot Saved" "Saved to $save_path"
      else
          if [ -f "$temp_file" ]; then
              wl-copy < "$temp_file"
              notify-send -a "HyDE Alert" -i "$temp_file" "Screenshot Copied" "Copied to clipboard only"
          fi
      fi
      rm -f "$temp_file"
    '')

    # --- 4 ПРОФИЛЯ ПИТАНИЯ (МАКСИМУМ ПО ПОРТАМ ИЛИ 16 ЧАСОВ РАБОТЫ) ---
    (pkgs.writeShellScriptBin "powerprofile-menu" ''
      STATE_FILE="/tmp/tlp_user_profile"

      get_status() {
          mode="auto"
          [ -f "$STATE_FILE" ] && mode=$(cat "$STATE_FILE")

          case "$mode" in
              performance)
                  icon="󰓅"
                  text="Boost"
                  tip="Profile: Performance (Ports & CPU at Maximum)\nClick to change"
                  class="performance"
                  ;;
              deep-eco)
                  icon="󰌨"
                  text="Ultra"
                  tip="Profile: Ultra Eco (Typewriter: Peripherals off, screen untouched)\nClick to change"
                  class="deep-eco"
                  ;;
              powersave)
                  icon="󰌪"
                  text="Eco"
                  tip="Profile: Power Saver (Standard Battery)\nClick to change"
                  class="powersave"
                  ;;
              *)
                  icon="󰾆"
                  text="Auto"
                  tip="Profile: Automatic (TLP Default)\nClick to change"
                  class="auto"
                  ;;
          esac

          printf '{"text":"%s %s", "tooltip":"%s", "class":"%s"}\n' "$icon" "$text" "$tip" "$class"
      }

      set_profile() {
          choice=$(printf "󰓅 Performance (Ports & CPU Max)\n󰾆 Automatic (TLP Default)\n󰌪 Eco (Standard Battery)\n󰌨 Ultra Eco (Typewriter: Peripherals Off)" | rofi -dmenu -p "Power Profile" -theme-str 'window {width: 26em; border-radius: 0px;}')

          case "$choice" in
              *"Performance"*)
                  sudo tlp ac >/dev/null 2>&1
                  rfkill unblock all >/dev/null 2>&1
                  echo "performance" > "$STATE_FILE"
                  notify-send -a "Power" -i "battery-charging" "Performance Mode" "Full continuous power to ports, CPU & GPU maxed"
                  ;;
              *"Automatic"*)
                  sudo tlp auto >/dev/null 2>&1
                  echo "auto" > "$STATE_FILE"
                  notify-send -a "Power" -i "battery" "Automatic Mode" "Default TLP balance restored"
                  ;;
              *"Eco"*)
                  sudo tlp bat >/dev/null 2>&1
                  echo "powersave" > "$STATE_FILE"
                  notify-send -a "Power" -i "battery-low" "Eco Mode" "Standard battery saving enabled"
                  ;;
              *"Ultra"*)
                  sudo tlp bat >/dev/null 2>&1
                  rfkill block bluetooth >/dev/null 2>&1
                  # Отключаем Wi-Fi только если нет подключения
                  if ! ip route | grep -q default; then
                      rfkill block wifi >/dev/null 2>&1
                  fi
                  # Усыпляем аудиочип и переводим CPU в самый холодный пресет
                  echo 1 | sudo tee /sys/module/snd_hda_intel/parameters/power_save >/dev/null 2>&1
                  for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
                      [ -f "$f" ] && echo "power" | sudo tee "$f" >/dev/null 2>&1
                  done
                  # ЯРКОСТЬ ЭКРАНА НЕ ТРОГАЕМ ВООБЩЕ!
                  echo "deep-eco" > "$STATE_FILE"
                  notify-send -a "Power" -i "battery-empty" "Ultra Eco Mode" "Typewriter mode: peripherals suspended, screen untouched"
                  ;;
          esac
          pkill -RTMIN+8 waybar
      }

      case "$1" in
          status) get_status ;;
          select) set_profile ;;
          *) get_status ;;
      esac
    '')

    # DOLPHIN STACK
    kdePackages.dolphin
    kdePackages.ark
    kdePackages.kio-extras
    kdePackages.kdegraphics-thumbnailers
    kdePackages.ffmpegthumbs
    kdePackages.qtsvg

    # USER PACKAGES
    pychess
    stockfish
    lc0
    scid-vs-pc
    cacert
    zsh-powerlevel10k
    cava
    playerctl
    jq
    zoom-us
    refind
    libreoffice
    kdePackages.okular
    zerotierone
    efibootmgr
    kitty
    rofi
    waybar
    firefox
    dunst
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

    pavucontrol
    alsa-utils
    wireplumber

    gcc
    cmake
    clang
    cling
    ninja
    glfw
    vulkan-headers
    vulkan-loader
    vulkan-validation-layers
    pkg-config
    shaderc
    glm

    cargo
    rustc

    jdk21
    wget
    curl
    librsvg
    unzip
    spicetify-cli
    syncplay
    mpv
    socat

    spice
    spice-gtk
    spice-protocol
    virt-viewer

    gamescope
    mangohud
  ];

  # =========================================================================
  # LIBRETRANSLATE
  # =========================================================================
  services.libretranslate = {
    enable = true;
    host = "127.0.0.1";
    port = 5000;
    updateModels = true;
    extraArgs = {
      "load-only" = "en,uk,ru,it";
    };
  };

  systemd.services.libretranslate = {
    wantedBy = lib.mkForce [ ];
    serviceConfig = {
      TimeoutStartSec = "15min";
      MemoryMax = "2G";
      CPUQuota = "200%";
    };
  };

  environment.shellAliases = {
    lt-on = "sudo systemctl start libretranslate";
    lt-off = "sudo systemctl stop libretranslate";
    lt-status = "systemctl status libretranslate";
    lt-log = "journalctl -u libretranslate -f";
  };

  # =========================================================================
  # SERVICES & POWERTOP (АВТОМАТИЧЕСКИЙ ТЮНИНГ ЭНЕРГОПОТРЕБЛЕНИЯ)
  # =========================================================================
  services.dbus.enable = true;
  services.flatpak.enable = true;
  services.zerotierone.enable = true;
  services.thermald.enable = true;

  services.gvfs.enable = true;
  services.udisks2.enable = true;

  powerManagement.powertop.enable = true;

  # ТОНКАЯ НАСТРОЙКА TLP
  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = 75;
      START_CHARGE_THRESH_BAT1 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
      STOP_CHARGE_THRESH_BAT1 = 80;
      RESTORE_THRESHOLDS_ON_BAT = 1;
      NATACPI_ENABLE = 1;

      # Сон USB и портов
      USB_AUTOSUSPEND = 1;
      USB_EXCLUDE_AUDIO = 1;

      # Шины PCIe и SATA/NVMe
      PCIE_ASPM_ON_BAT = "powersupersave";
      PCIE_ASPM_ON_AC = "performance";
      AHCI_RUNTIME_PM_ON_BAT = "auto";

      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_BAT = 60;

      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      INTEL_GPU_MIN_FREQ_ON_AC = 300;
      INTEL_GPU_MAX_FREQ_ON_AC = 1150;
      INTEL_GPU_BOOST_FREQ_ON_AC = 1150;

      INTEL_GPU_MIN_FREQ_ON_BAT = 300;
      INTEL_GPU_MAX_FREQ_ON_BAT = 600;
      INTEL_GPU_BOOST_FREQ_ON_BAT = 600;

      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;
    };
  };

  # =========================================================================
  # SWAP & ZRAM (32 ГБ ФАЙЛ ПОДКАЧКИ + СЖАТИЕ В ОЗУ)
  # =========================================================================
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 32 * 1024; # 32768 МБ (32 ГБ)
    priority = 10;    # Ниже, чем у zram: SSD используется при переполнении ОЗУ
  }];

  zramSwap = {
    enable = true;
    memoryPercent = 50;
    priority = 100;   # Высокий приоритет: сперва сжимаем данные в оперативной памяти
  };

  # =========================================================================
  # VIRTUALIZATION
  # =========================================================================
  programs.dconf.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  programs.virt-manager.enable = true;

  system.stateVersion = "24.11";
}
