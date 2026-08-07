{ lib, pkgs, ... }:

{
  # Git 的稳定个人偏好由 Home Manager 统一生成，认证材料仍由 gh 自行保管。
  programs.git = {
    enable = true;

    settings = [
      {
        user = {
          name = "zaviro";
          email = "1264166738a@gmail.com";
        };

        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        fetch.prune = true;
        rerere.enabled = true;

        alias = {
          co = "checkout";
          st = "status";
          lg = "log --oneline --graph --decorate";
        };
      }

      # 先清空已有 helper，再委托 gh 按其独立保存的认证状态提供凭证。
      {
        credential."https://github.com".helper = "";
      }
      {
        credential."https://github.com".helper = "!${lib.getExe pkgs.gh} auth git-credential";
      }
      {
        credential."https://gist.github.com".helper = "";
      }
      {
        credential."https://gist.github.com".helper = "!${lib.getExe pkgs.gh} auth git-credential";
      }
    ];
  };
}
