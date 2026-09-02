{
  programs.nixvim = {
    enable = true;
    waylandSupport = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;

    imports = [
      ./nixvim/core.nix
      ./nixvim/autocmds.nix
      ./nixvim/keymaps.nix
      ./nixvim/diagnostics.nix
      ./nixvim/lsp.nix
      ./nixvim/completion.nix
      ./nixvim/syntax.nix
      ./nixvim/formatting.nix
      ./nixvim/editing.nix
      ./nixvim/navigation.nix
      ./nixvim/vcs.nix
      ./nixvim/ui.nix
    ];
  };
}
