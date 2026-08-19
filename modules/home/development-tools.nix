{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nixfmt
    devenv
    uv
    python3
    nodejs_24
    bun
    just
    watchexec
    zed-editor

  ];

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      git.colocate = true;
      user = {
        name = "zaviro";
        email = "1264166738a@gmail.com";
      };
    };
  };
}
