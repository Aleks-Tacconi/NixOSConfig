{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.services.sunshine;
  sunshineConfig = (pkgs.formats.keyValue { }).generate "sunshine.conf" cfg.settings;
  windowConfig = pkgs.writeText "sunshine-openbox.xml" ''
    <openbox_config xmlns="http://openbox.org/3.4/rc">
      <applications>
        <application class="eden" type="normal">
          <fullscreen>yes</fullscreen>
        </application>
      </applications>
    </openbox_config>
  '';

  # Give Sunshine its own X display, window manager, and audio server.
  session = pkgs.writeShellApplication {
    name = "sunshine-session";
    runtimeInputs = with pkgs; [
      xwayland
      xdpyinfo
      xauth
      util-linux
      openbox
      pulseaudio
    ];
    text = ''
      export DISPLAY=:77
      export XAUTHORITY="$SUNSHINE_RUNTIME/Xauthority"
      export PULSE_SERVER="unix:$SUNSHINE_RUNTIME/pulse"
      export XDG_CURRENT_DESKTOP=Openbox
      export XDG_SESSION_TYPE=x11
      touch "$XAUTHORITY"
      xauth add "$DISPLAY" . "$(mcookie)"
      pulseaudio --daemonize=no --use-pid-file=no --exit-idle-time=-1 -n \
        --load="module-native-protocol-unix socket=$SUNSHINE_RUNTIME/pulse" \
        --load="module-null-sink sink_name=eden" &
      Xwayland "$DISPLAY" -geometry 1920x1080 -nolisten tcp -auth "$XAUTHORITY" &
      unset WAYLAND_DISPLAY
      for _ in {1..100}; do
        if xdpyinfo >/dev/null 2>&1 && pactl info >/dev/null 2>&1; then
          break
        fi
        sleep 0.1
      done
      xdpyinfo >/dev/null
      pactl info >/dev/null
      openbox --config-file ${windowConfig} &
      export LD_LIBRARY_PATH="/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      exec ${lib.getExe cfg.package} ${sunshineConfig}
    '';
  };

  # Hide global input injection; Sunshine then uses XTest on its own X server.
  isolatedSunshine = pkgs.writeShellApplication {
    name = "sunshine-isolated";
    runtimeInputs = with pkgs; [
      bubblewrap
      coreutils
    ];
    text = ''
      SUNSHINE_RUNTIME=$(mktemp -d "$XDG_RUNTIME_DIR/sunshine.XXXXXX")
      export SUNSHINE_RUNTIME
      trap 'rm -rf "$SUNSHINE_RUNTIME"' EXIT
      bwrap --bind / / --dev-bind /dev /dev \
        --tmpfs /tmp --proc /proc \
        --ro-bind /dev/null /dev/uinput \
        --unshare-pid --die-with-parent --new-session \
        --unsetenv DISPLAY --unsetenv WAYLAND_DISPLAY \
        ${pkgs.dbus}/bin/dbus-run-session -- \
        ${pkgs.weston}/bin/weston --backend=headless --renderer=gl \
        --width=1920 --height=1080 --idle-time=0 --no-config \
        --socket=sunshine-wayland -- ${lib.getExe session}
    '';
  };
in
{
  # A separate compositor keeps remote mouse/keyboard focus off the PC desktop.
  services.sunshine = {
    enable = true;
    autoStart = true;
    openFirewall = true;
    settings = {
      capture = "x11";
      output_name = "0";
      gamepad = "switch";
      system_tray = "disabled";
    };
    applications.apps = [
      {
        name = "Eden";
        cmd = lib.getExe pkgs.eden;
        auto-detach = false;
      }
    ];
  };

  # Controllers use UHID while keyboard and mouse remain confined to XTest.
  boot.kernelModules = [ "uhid" ];
  # The menu must start the isolated service, not a second desktop-capturing host.
  home-manager.users.aleks.xdg.desktopEntries."dev.lizardbyte.app.Sunshine" = {
    name = "Sunshine";
    icon = "dev.lizardbyte.app.Sunshine";
    categories = [ "Network" ];
    exec = toString (
      pkgs.writeShellScript "sunshine-open" ''
        set -eu
        ${pkgs.systemd}/bin/systemctl --user start sunshine.service
        exec ${pkgs.xdg-utils}/bin/xdg-open https://localhost:47990
      ''
    );
  };
  systemd.user.services.sunshine.serviceConfig = {
    ExecStart = lib.mkForce (lib.getExe isolatedSunshine);
    Restart = lib.mkForce "always";
  };
}
