{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  home.packages = with pkgs; [ tmux ];

  home.file.".tmux.conf".text = ''
    unbind r
    bind r source-file ~/.tmux.conf

    set -g prefix C-s
    set -g mouse on

    # set-option status off
    set-option -g focus-events on

    set -gq allow-passthrough on
    set -g visual-activity off

    bind-key h select-pane -L
    bind-key j select-pane -D
    bind-key k select-pane -U
    bind-key l select-pane -R

    bind-key o run-shell '
    if tmux list-clients | grep opencode; then
        tmux detach-client
    else
        tmux has-session -t opencode 2>/dev/null || tmux new-session -d -s opencode "opencode"
        tmux display-popup -T "OpenCode" -w 80% -h 80% -E "tmux attach -t opencode"
    fi
    '

    set -g status-left-length 85
    set -g status-left ""
    set -g window-status-current-format "#[fg=cyan]#I:(#W) "
    set -g window-status-format "#[fg=black bg=default]#I:(#W)#[bg=default] "
    set -g status-style bg=default
    set -g status-right "#[fg=magenta] #[bg=default] %b %d %Y %l:%M %p"
    set -g status-right '#(gitmux "#{pane_current_path}")'
    set -g status-justify left
    set -g allow-passthrough on

    set -g default-terminal "tmux-256color"
    set-option -ga terminal-overrides ",xterm-256color:Tc"
  '';
}
