{ pkgs, ... }:

let
  niriConfig = pkgs.runCommand "niri-config.kdl" { } ''
    install -m 0644 ${pkgs.niri.doc}/share/doc/niri/default-config.kdl "$out"
    substituteInPlace "$out" \
      --replace-fail 'spawn-at-startup "waybar"' 'spawn-at-startup "noctalia"' \
      --replace-fail 'Mod+T hotkey-overlay-title="Open a Terminal: alacritty" { spawn "alacritty"; }' 'Mod+T hotkey-overlay-title="Open a Terminal: Ghostty" { spawn "ghostty"; }' \
      --replace-fail 'Mod+D hotkey-overlay-title="Run an Application: fuzzel" { spawn "fuzzel"; }' 'Mod+D hotkey-overlay-title="Open Noctalia Launcher" { spawn "noctalia" "msg" "panel-toggle" "launcher"; }' \
      --replace-fail 'Super+Alt+L hotkey-overlay-title="Lock the Screen: swaylock" { spawn "swaylock"; }' 'Super+Alt+L hotkey-overlay-title="Lock the Screen" { spawn "noctalia" "msg" "session" "lock"; }'
    substituteInPlace "$out" --replace-fail '    gaps 16' '    gaps 0'
    sed -i '/^    focus-ring {$/,/^    }$/ s/^        \/\/ off$/        off/' "$out"
    substituteInPlace "$out" --replace-fail 'binds {' 'binds {
      // Noctalia desktop-shell shortcuts.
      Mod+Space hotkey-overlay-title="Open Noctalia Launcher" { spawn "noctalia" "msg" "panel-toggle" "launcher"; }
      Mod+B hotkey-overlay-title="Open Browser: Google Chrome" { spawn "google-chrome"; }
      Mod+E hotkey-overlay-title="Open File Manager: Nautilus" { spawn "nautilus" "--new-window"; }
      Mod+N hotkey-overlay-title="Toggle Control Center" { spawn "noctalia" "msg" "panel-toggle" "control-center"; }
      Mod+Shift+Comma hotkey-overlay-title="Toggle Noctalia Settings" { spawn "noctalia" "msg" "settings-toggle"; }
      Mod+X hotkey-overlay-title="Toggle Session Menu" { spawn "noctalia" "msg" "panel-toggle" "session"; }
      Mod+Alt+V hotkey-overlay-title="Toggle Clipboard Manager" { spawn "noctalia" "msg" "panel-toggle" "clipboard"; }
    '
  '';
in

{
  xdg.configFile."niri/config.kdl".source = niriConfig;
}
