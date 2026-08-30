{
  jq,
  niri,
  util-linux,
  writeShellApplication,
}:

writeShellApplication {
  name = "window-keybindings";
  runtimeInputs = [
    jq
    niri
    util-linux
  ];
  text = builtins.readFile ./bin/window-keybindings;
}
