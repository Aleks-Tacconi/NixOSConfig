{ pkgs, inputs, ... }:

let
  rexPkg = inputs.rex.packages.${pkgs.stdenv.hostPlatform.system}.default;
  rexRunePkg = inputs.rex-rune.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (_: {
    doCheck = false;
  });
  tabGoto =
    prefix:
    builtins.genList (i: {
      keys = "${prefix}${toString (i + 1)}";
      action = "client.tab.goto";
      args = {
        index = i + 1;
      };
    }) 9;
  shortcuts = [
    {
      keys = "ctrl+s>c";
      action = "client.tab.new";
    }
    {
      keys = "ctrl+s>shift+5";
      action = "pane.split";
      args = {
        direction = "right";
      };
    }
    {
      keys = "ctrl+s>shift+'";
      action = "pane.split";
      args = {
        direction = "down";
      };
    }
    {
      keys = "ctrl+s>h";
      action = "pane.focus";
      args = {
        direction = "left";
      };
    }
    {
      keys = "ctrl+s>j";
      action = "pane.focus";
      args = {
        direction = "down";
      };
    }
    {
      keys = "ctrl+s>k";
      action = "pane.focus";
      args = {
        direction = "up";
      };
    }
    {
      keys = "ctrl+s>l";
      action = "pane.focus";
      args = {
        direction = "right";
      };
    }
    {
      keys = "ctrl+s>n";
      action = "client.tab.next";
    }
    {
      keys = "ctrl+s>p";
      action = "client.tab.previous";
    }
    {
      keys = "ctrl+s>z";
      action = "pane.zoom";
    }
    {
      keys = "ctrl+s>x";
      action = "pane.close";
    }
    {
      keys = "ctrl+s>shift+7";
      action = "client.tab.close";
    }
    {
      keys = "ctrl+s>,";
      action = "client.tab.rename";
    }
    {
      keys = "ctrl+s>shift+4";
      action = "session.rename";
    }
    {
      keys = "ctrl+s>s";
      action = "session.switch";
    }
    {
      keys = "ctrl+s>r";
      action = "client.config.reload";
    }
    {
      keys = "ctrl+s>ctrl+s";
      action = "pane.send_key";
      args = {
        key = "ctrl+s";
      };
    }
  ]
  ++ tabGoto "ctrl+"
  ++ tabGoto "ctrl+s>";
in
{
  home.packages = [
    rexPkg
    rexRunePkg
  ];

  home.file.".config/rex-rune/shortcuts.json".text = builtins.toJSON { inherit shortcuts; };

  systemd.user.services.rex-server = {
    Unit = {
      Description = "Rex terminal multiplexer server";
      After = [ "default.target" ];
    };
    Service = {
      ExecStart = "${pkgs.bash}/bin/bash -lc 'exec ${rexPkg}/bin/rex server run'";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
