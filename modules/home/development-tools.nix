{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nixfmt
    devenv
    direnv
    uv
    python3
    nodejs_24
    bun
  ];
}
