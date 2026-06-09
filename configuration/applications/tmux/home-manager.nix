{ ... }:

{
  home.file.".tmux.conf".text = ''
    source-file ~/.config/tmux/tmux.conf
  '';

  programs.tmux = {
    enable = true;

    baseIndex = 1;
    clock24 = false;
    escapeTime = 0;
    keyMode = "vi";
    mouse = true;
    prefix = "C-s";
    terminal = "tmux-256color";

    extraConfig = ''
      unbind r
      bind r source-file ~/.tmux.conf \; display-message "tmux config reloaded"

      set -g focus-events on
      set -g allow-passthrough on
      set -g visual-activity off
      set -g automatic-rename on
      set -g allow-rename off
      set -g renumber-windows on

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      bind o run-shell '
      if tmux list-clients | grep opencode; then
          tmux detach-client
      else
          tmux has-session -t opencode 2>/dev/null || tmux new-session -d -s opencode "opencode" && tmux display-popup -T "OpenCode" -w 80% -h 80% -E "tmux attach -t opencode"
      fi
      '

      set -g pane-border-lines single
      set -g pane-border-style "fg=#232136"
      set -g pane-active-border-style "fg=#393552"

      set -g message-style "fg=#e0def4,bg=#232136"
      set -g mode-style "fg=#e0def4,bg=#232136"
      set -g display-panes-colour "#6e6a86"
      set -g display-panes-active-colour "#c4a7e7"

      set -g status on
      set -g status-position top
      set -g status-interval 5
      set -g status-justify centre
      set -g status-style "fg=#6e6a86,bg=default"
      set -g status-format[1] "#[bg=default] "
      set -g status-left-length 20
      set -g status-right-length 40
      set -g status-left "#[fg=#c4a7e7,bold]#S "
      set -g status-right " %H:%M"

      set -g window-status-separator " "
      set -g window-status-format "#[fg=#393552]#I:#W"
      set -g window-status-current-format "#[fg=#e0def4,nobold]#I:#W"
      set -g window-status-activity-style "fg=#f6c177,bg=default"
      set -g window-status-bell-style "fg=#eb6f92,bg=default"

      set -g default-terminal "tmux-256color"
      set -ga terminal-overrides ",xterm-ghostty:Tc"
      set -ga terminal-overrides ",xterm-256color:Tc"
    '';
  };
}
