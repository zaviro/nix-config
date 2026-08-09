{ pkgs, ... }:

let
  niriConfig = pkgs.runCommand "niri-config.kdl" { } ''
    install -m 0644 ${pkgs.niri.doc}/share/doc/niri/default-config.kdl "$out"
    substituteInPlace "$out" \
      --replace-fail 'spawn-at-startup "waybar"' 'spawn-at-startup "dms" "run"' \
      --replace-fail 'Mod+T hotkey-overlay-title="Open a Terminal: alacritty" { spawn "alacritty"; }' 'Mod+T hotkey-overlay-title="Open a Terminal: Ghostty" { spawn "ghostty"; }' \
      --replace-fail 'Mod+D hotkey-overlay-title="Run an Application: fuzzel" { spawn "fuzzel"; }' 'Mod+D hotkey-overlay-title="Open DMS Launcher" { spawn "dms" "ipc" "spotlight" "toggle"; }' \
      --replace-fail 'Super+Alt+L hotkey-overlay-title="Lock the Screen: swaylock" { spawn "swaylock"; }' 'Super+Alt+L hotkey-overlay-title="Lock the Screen" { spawn "dms" "ipc" "lock" "lock"; }'
    substituteInPlace "$out" --replace-fail '    gaps 16' '    gaps 0'
    sed -i '/^    focus-ring {$/,/^    }$/ s/^        \/\/ off$/        off/' "$out"
    substituteInPlace "$out" --replace-fail 'binds {' 'binds {
      // DMS desktop-shell shortcuts.
      Mod+Space hotkey-overlay-title="Open DMS Launcher" { spawn "dms" "ipc" "spotlight" "toggle"; }
      Mod+N hotkey-overlay-title="Toggle Notification Center" { spawn "dms" "ipc" "notifications" "toggle"; }
      Mod+Shift+Comma hotkey-overlay-title="Toggle DMS Settings" { spawn "dms" "ipc" "settings" "toggle"; }
      Mod+P hotkey-overlay-title="Toggle Notepad" { spawn "dms" "ipc" "notepad" "toggle"; }
      Mod+X hotkey-overlay-title="Toggle Power Menu" { spawn "dms" "ipc" "powermenu" "toggle"; }
      Mod+Alt+V hotkey-overlay-title="Toggle Clipboard Manager" { spawn "dms" "ipc" "clipboard" "toggle"; }
      Mod+Alt+M hotkey-overlay-title="Toggle Process List" { spawn "dms" "ipc" "processlist" "toggle"; }
    '
  '';
in

{
  xdg.configFile."niri/config.kdl".source = niriConfig;
}
