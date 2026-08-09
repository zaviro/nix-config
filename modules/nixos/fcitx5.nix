{ pkgs, ... }:

{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      addons = [ pkgs.fcitx5-rime ];
      waylandFrontend = true;
    };
  };

  # 非 KWin 桌面的 Qt 仍需要 fcitx im module 回退。
  environment.variables.QT_IM_MODULE = "fcitx";
}
