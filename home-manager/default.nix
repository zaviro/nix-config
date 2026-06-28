{
  config,
  lib,
  pkgs,
  nixvim,
  ...
}:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "zaviro";
  home.homeDirectory = "/home/zaviro";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "26.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    nh
    nixfmt # Nix 官方格式化器
    git # 版本控制
    devenv # 可复现开发环境
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/zaviro/etc/profile.d/hm-session-vars.sh
  #
  # Let Home Manager install and manage itself.

  # ===================== Nixvim 配置 =====================
  programs.nixvim = {
    enable = true;
    nixpkgs.source = pkgs.path;
    # 核心：设置默认编辑器 + 社区标准别名
    defaultEditor = true; # 设为默认编辑器($EDITOR)
    vimAlias = true; # vim → nvim
    viAlias = true; # vi → nvim
    # 必须在 keymaps 之前设置，否则 <leader> 会以默认的 \ 解析
    globals.mapleader = " ";
    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        transparent_background = false;
      };
    };
    plugins = {
      treesitter.enable = true;
      telescope.enable = true;
      which-key.enable = true;
      gitsigns.enable = true;
      web-devicons.enable = true;
      nvim-ufo.enable = true;

      # LSP 配置
      lsp = {
        enable = true;
        servers = {
          ts_ls = {
            enable = true; # JavaScript / TypeScript
            filetypes = lib.mkForce [
              "javascript"
              "javascriptreact"
              "typescript"
              "typescriptreact"
            ];
          };
          nixd.enable = true; # Nix
          bashls.enable = true; # Bash
          lua_ls.enable = true; # Lua（Neovim 配置语言）
        };
      };
    };
    # ===== 基本编辑器选项 =====
    opts = {
      number = true; # 显示行号
      relativenumber = true; # 相对行号
      tabstop = 2; # Tab 宽度
      shiftwidth = 2; # 缩进宽度
      expandtab = true; # Tab 转空格
      mouse = "a"; # 鼠标支持
      termguicolors = true; # 24-bit 真彩色
      # Treesitter 折叠
      foldmethod = "expr";
      foldexpr = "v:lua.vim.treesitter.foldexpr()";
      foldlevel = 99;
      foldlevelstart = 99;
      foldenable = true;
      foldminlines = 1;
    };

    # ===== 按键映射 =====
    keymaps = [
      {
        mode = "n";
        key = "<leader>ff";
        action = "<cmd>Telescope find_files<cr>";
        options.desc = "Find files";
      }
      {
        mode = "n";
        key = "<leader>fg";
        action = "<cmd>Telescope live_grep<cr>";
        options.desc = "Live grep";
      }
    ];

    # ===== ufo 折叠快捷键（Lua API 调用，无法用 keymaps 描述） =====
    extraConfigLua = ''
      vim.keymap.set("n", "zR", require('ufo').openAllFolds, { desc = "展开所有折叠" })
      vim.keymap.set("n", "zM", require('ufo').closeAllFolds, { desc = "折叠所有内容" })
      vim.keymap.set("n", "zr", require('ufo').openFoldsExceptKinds, { desc = "展开一层折叠" })
      vim.keymap.set("n", "zm", require('ufo').closeFoldsWith, { desc = "折叠一层" })
      vim.keymap.set("n", "za", "za", { desc = "切换当前折叠（原生Vim键）" })
    '';
  };
  # =======================================================

  # ===================== Tmux 配置 =====================
  programs.tmux = {
    enable = true;
    mouse = true;
    focusEvents = true; # 替代 set-option -g focus-events on
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

  programs.home-manager.enable = true;
}
