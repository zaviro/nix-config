{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion = {
      enable = true;
      strategy = [ "history" ];
    };
    syntaxHighlighting.enable = true;
    history = {
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
    };
    historySubstringSearch.enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "fzf"
      ];
    };
    shellAliases = {
      ll = "ls -lha";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      cx = "codex";
      oc = "opencode";
      cc = "claude";
      gm = "gemini";
      ot = "openclaw tui";
      hm = "hermes";
      ld = "lazydocker";
      dps = "docker ps";
      dcu = "docker compose up -d";
      dcd = "docker compose down";
      ".." = "cd ..";
      nd = "node";
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
