{ pkgs, ... }:
{
  home.packages = [ pkgs.jj-starship ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autocd = true;
    autosuggestion = {
      enable = true;
      strategy = [ "history" ];
    };
    syntaxHighlighting.enable = true;
    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];
    zsh-abbr = {
      enable = true;
      abbreviations = {
        cx = "codex";
        ot = "openclaw tui";
        zj = "zellij";
        dps = "docker ps";
        dcu = "docker compose up -d";
        dcd = "docker compose down";
      };
    };
    initContent = ''
      zstyle ':fzf-tab:*' fzf-flags '--height=50%' '--layout=reverse'
      zstyle ':fzf-tab:*' switch-group '<' '>'
    '';
    history = {
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
    };
    shellAliases.ll = "eza -lah --group-directories-first --git";
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    extraPackages = [ pkgs.jj-starship ];

    settings = {
      git_branch.disabled = true;
      git_commit.disabled = true;
      git_status.disabled = true;

      custom.jj = {
        when = "jj-starship detect";
        shell = [
          "jj-starship"
          "--no-jj-id"
          "--no-jj-prefix"
        ];
        format = "$output ";
      };
    };
  };
}
