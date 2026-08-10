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
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" ];
    };
    shellAliases = {
      ll = "ls -lha";
      js = "jj status";
      jd = "jj diff";
      jl = "jj log";
      jn = "jj new";
      jc = "jj commit";
      cx = "codex";
      ot = "openclaw tui";
      hm = "hermes";
      zj = "zellij";
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
