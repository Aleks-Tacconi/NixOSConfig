{
  config,
  pkgs,
  lib,
  ...
}:

let
  secondBrainPath = "${config.home.homeDirectory}/SecondBrain";

  pullScript = pkgs.writeShellScript "secondbrain-pull" ''
    cd "${secondBrainPath}" || exit 1
    ${pkgs.git}/bin/git pull origin main
  '';

  syncScript = pkgs.writeShellScript "secondbrain-sync" ''
    cd "${secondBrainPath}" || exit 1

    # Only sync if there are changes
    if [ -n "$(${pkgs.git}/bin/git status --porcelain)" ]; then
      ${pkgs.git}/bin/git add -A
      ${pkgs.git}/bin/git commit -m "Auto-sync: $(date '+%Y-%m-%d %H:%M:%S')"
      ${pkgs.git}/bin/git push origin main
    fi
  '';
in
{
  # Pull on startup
  systemd.user.services.secondbrain-pull = {
    Unit = {
      Description = "Pull SecondBrain on startup";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${pullScript}";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # Hourly sync service
  systemd.user.services.secondbrain-sync = {
    Unit = {
      Description = "Sync SecondBrain if changes exist";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${syncScript}";
    };
  };

  # Timer for hourly sync
  systemd.user.timers.secondbrain-sync = {
    Unit = {
      Description = "Hourly SecondBrain sync";
    };

    Timer = {
      OnBootSec = "1h";
      OnUnitActiveSec = "1h";
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
