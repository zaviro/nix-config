{ pkgs, ... }:

let
  nixLspDispatch = pkgs.callPackage ../../pkgs/nix-lsp-dispatch.nix { };
in
{
  programs.zed-editor = {
    enable = true;
    extensions = [ "nix" ];

    # 作为非 devenv 项目的 fallback；项目环境中的版本会通过 direnv 优先进入 PATH。
    extraPackages = [ pkgs.typescript-language-server ];

    userSettings = {
      load_direnv = "direct";

      languages = {
        Nix.language_servers = [
          "nixd"
          "!nil"
        ];
        JavaScript.language_servers = [
          "typescript-language-server"
          "!vtsls"
          "..."
        ];
        TypeScript.language_servers = [
          "typescript-language-server"
          "!vtsls"
          "..."
        ];
        TSX.language_servers = [
          "typescript-language-server"
          "!vtsls"
          "..."
        ];
      };

      lsp.nixd.binary = {
        path = "${nixLspDispatch}/bin/nix-lsp-dispatch";
        arguments = [ ];
      };
    };
  };
}
