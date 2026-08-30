{
  config,
  lib,
  pkgs,
  ...
}:

let
  # This module is the only writer of niri/config.kdl. It serializes the
  # resolved policy from keybindings.nix and retains niri's upstream defaults.
  renderBool = value: if value then "true" else "false";
  renderBinding =
    binding:
    let
      properties = lib.concatStrings [
        (lib.optionalString (binding.repeat != null) " repeat=${renderBool binding.repeat}")
        (lib.optionalString binding.allowWhenLocked " allow-when-locked=true")
        (lib.optionalString (
          binding.title != null
        ) " hotkey-overlay-title=${builtins.toJSON binding.title}")
      ];
      body =
        if binding.command != null then
          "spawn ${lib.concatMapStringsSep " " builtins.toJSON binding.command};"
        else
          "${binding.action};";
    in
    "    ${binding.key}${properties} { ${body} }";

  renderedBindings =
    lib.concatMapStringsSep "\n" renderBinding config.zaviro.keybindings.bindings + "\n";
  renderedBindingsFile = pkgs.writeText "niri-custom-bindings.kdl" renderedBindings;

  niriConfig = pkgs.runCommand "niri-config.kdl" { } ''
    install -m 0644 ${pkgs.niri.doc}/share/doc/niri/default-config.kdl "$out"
    substituteInPlace "$out" \
      --replace-fail 'spawn-at-startup "waybar"' 'spawn-at-startup "noctalia"' \
      --replace-fail 'Mod+T hotkey-overlay-title="Open a Terminal: alacritty" { spawn "alacritty"; }' "" \
      --replace-fail 'Mod+D hotkey-overlay-title="Run an Application: fuzzel" { spawn "fuzzel"; }' "" \
      --replace-fail 'Super+Alt+L hotkey-overlay-title="Lock the Screen: swaylock" { spawn "swaylock"; }' ""
    substituteInPlace "$out" --replace-fail '    gaps 16' '    gaps 0'
    sed -i '/^    focus-ring {$/,/^    }$/ s/^        \/\/ off$/        off/' "$out"
    grep -qx 'binds {' "$out"
    sed -i '/^binds {$/r ${renderedBindingsFile}' "$out"
    ${lib.getExe pkgs.niri} validate --config "$out"
  '';
in

{
  xdg.configFile."niri/config.kdl".source = niriConfig;
}
