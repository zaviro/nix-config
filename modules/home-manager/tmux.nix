{
  programs.tmux = {
    enable = true;
    mouse = true;
    focusEvents = true;

    extraConfig = ''
      # 鼠标滚轮正常滚动
      bind -T copy-mode-vi WheelUpPane send-keys -X scroll-up
      bind -T copy-mode-vi WheelDownPane send-keys -X scroll-down
      bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "copy-mode -e"

      # Claude Code 终端透传与扩展按键支持
      set -g allow-passthrough on
      set -s extended-keys on
      set -as terminal-features 'xterm*:extkeys'

      # Nord 配色状态栏
      set -g status-style "bg=#2e3440,fg=#d8dee9"
      set -g window-status-current-style "bg=#88c0d0,fg=#2e3440,bold"
    '';
  };
}
