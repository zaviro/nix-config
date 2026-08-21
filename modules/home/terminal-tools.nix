{ pkgs, ... }:
let
  fzfFiles =
    "fd --type f --hidden"
    + " --exclude .git"
    + " --exclude node_modules"
    + " --exclude .cache"
    + " --exclude .local/share"
    + " --exclude .npm"
    + " --exclude .pnpm-store"
    + " --exclude .devenv";
in
{
  # 所有主机都需要的用户级工具；系统启动所需软件应留在 NixOS 配置中。
  home.packages = with pkgs; [
    # Agent、脚本和 Nixvim 都直接受益的非交互工具。
    ripgrep
    ast-grep
    file
    jq
    gh
    lsof
    xh

    # 日常终端工作流。
    eza
    fd
    htop
    lazygit
    dust
    ouch
    procs
    tree
    unzip
    zip
  ];

  programs = {
    # 保留系统自带的 cat、du、ps 和 top，避免改变脚本或熟悉命令的语义；
    # 新工具使用各自社区通行的命令名。
    bat.enable = true;

    delta = {
      enable = true;
      enableGitIntegration = false;
      enableJujutsuIntegration = false;
    };

    git.settings = [
      {
        core.pager = "${pkgs.delta}/bin/delta";
      }
    ];

    broot = {
      enable = true;
      enableZshIntegration = true;
    };

    yazi = {
      enable = true;
      enableZshIntegration = true;
      # 为常见文件预览提供运行时依赖，全部通过 yazi 的包装器暴露。
      extraPackages = with pkgs; [
        file
        ffmpegthumbnailer
        jq
        p7zip
        poppler-utils
        unzip
      ];
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = fzfFiles;
      fileWidget = {
        command = fzfFiles;
        options = [ "--preview 'bat --color=always --style=numbers --line-range=:500 {}'" ];
      };
      changeDirWidget.command = "";
      historyWidget.command = "";
    };

    atuin = {
      enable = true;
      enableZshIntegration = true;
      flags = [ "--disable-up-arrow" ];
      settings = {
        workspaces = true;
        enter_accept = false;
      };
    };

    bottom.enable = true;
  };
}
