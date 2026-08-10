{
  claudeCodePackage,
  codexPackage,
  lib,
  nixvim,
  ...
}:

{
  home-manager.users.zaviro = {
    imports = [
      nixvim.homeModules.nixvim
      ../../modules/home/bundles/terminal.nix
      ../../modules/home/bundles/desktop.nix
      ../../modules/home/development-tools.nix
      ../../modules/home/clash-verge.nix
    ];

    home = {
      username = "zaviro";
      homeDirectory = "/home/zaviro";
      stateVersion = "26.05";
      packages = [
        claudeCodePackage
        codexPackage
      ];
    };

    programs.home-manager.enable = true;
    programs.nh = {
      enable = true;
      osFlake = "/home/zaviro/nix-config";
    };

    programs.zsh = {
      oh-my-zsh.plugins = lib.mkAfter [ "jj" ];
      initContent = ''
        # Prefer JJ's current change in colocated repositories. Plain Git
        # repositories retain the theme's original branch indicator.
        function jj_prompt_info() {
          local change bookmarks

          command jj --ignore-working-copy root >/dev/null 2>&1 || return 1
          change=$(command jj --ignore-working-copy log --no-pager --no-graph -r @ -T 'change_id.shortest(8)' 2>/dev/null) || return 1
          bookmarks=$(command jj --ignore-working-copy bookmark list --no-pager -r @ -T 'name ++ "\\n"' 2>/dev/null)
          bookmarks=''${bookmarks//$'\n'/, }
          bookmarks=''${bookmarks%, }

          print -nr -- "%{$fg_bold[magenta]%}jj:(%{$fg[red]%}$change%{$fg_bold[blue]%}''${bookmarks:+ $bookmarks}%{$reset_color%}) "
        }

        functions[_git_prompt_info]="''${functions[git_prompt_info]}"
        function git_prompt_info() {
          jj_prompt_info || _git_prompt_info
        }
      '';
    };
  };
}
