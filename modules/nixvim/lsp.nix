{ lib, pkgs, ... }:

let
  nixLspDispatch = pkgs.callPackage ../../pkgs/nix-lsp-dispatch.nix { };
in
{
  plugins.lspconfig.enable = true;

  lsp.servers = {
    "*".config.capabilities.__raw = ''
      require("blink-cmp").get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities())
    '';

    ts_ls = {
      enable = true;
      packageFallback = true;
      config.filetypes = lib.mkForce [
        "javascript"
        "javascriptreact"
        "typescript"
        "typescriptreact"
      ];
    };

    nixd = {
      enable = true;
      package = null;
      config = {
        cmd = [ "${nixLspDispatch}/bin/nix-lsp-dispatch" ];
        root_markers = [
          "devenv.nix"
          "flake.nix"
          ".jj"
          ".git"
        ];
      };
    };

    bashls.enable = true;
    lua_ls.enable = true;
  };
}
