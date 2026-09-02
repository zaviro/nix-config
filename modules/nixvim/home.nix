{
  programs.nixvim = {
    enable = true;
    waylandSupport = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;

    imports = [
      ./core.nix
      ./autocmds.nix
      ./keymaps.nix
      ./diagnostics.nix
      ./lsp.nix
      ./completion.nix
      ./syntax.nix
      ./formatting.nix
      ./editing.nix
      ./navigation.nix
      ./vcs.nix
      ./ui.nix
    ];
  };
}
