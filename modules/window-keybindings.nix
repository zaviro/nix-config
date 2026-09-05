{
  config,
  lib,
  pkgs,
  ...
}:

let
  # The package owns the reference semantics; this is Atlas's only deployment
  # adapter, where abstract roles receive real app_ids and launch commands.
  referenceProfile = import ../pkgs/window-keybindings/profiles/v0_7.nix;
  windowKeybindings = pkgs.callPackage ../pkgs/window-keybindings { };
  helper = lib.getExe windowKeybindings;

  bindingType = lib.types.submodule {
    options = {
      key = lib.mkOption {
        type = lib.types.str;
        description = "Compositor key chord.";
      };
      title = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Optional hotkey overlay title.";
      };
      command = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        description = "Command argv for a compositor spawn action.";
      };
      action = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Native compositor action name.";
      };
      repeat = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "Optional compositor repeat policy.";
      };
      allowWhenLocked = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether the binding remains active while locked.";
      };
    };
  };

  implementations = {
    browser = {
      appIdRegex = "^google-chrome$";
      command = [
        "google-chrome"
        "--new-window"
        "chrome://newtab"
      ];
      title = "Browser in Current Workspace";
    };

    terminal = {
      appIdRegex = "^com[.]mitchellh[.]ghostty$";
      command = [ "ghostty" ];
      title = "Terminal in Current Workspace";
    };

    editor = {
      appIdRegex = "^dev[.]zed[.]Zed$";
      command = [
        "zeditor"
        "--new"
      ];
      title = "Editor in Current Workspace";
    };

    agent = {
      appIdRegex = "^Chatgpt$";
      command = [ "chatgpt" ];
      title = "Summon ChatGPT";
    };

    notes = {
      appIdRegex = "^md[.]Obsidian$";
      command = [ "obsidian" ];
      title = "Summon Notes";
    };
  };

  mkRoleBinding =
    roleName: role:
    let
      target = implementations.${roleName};
    in
    {
      key = "${referenceProfile.modifier}+${role.key}";
      title = target.title;
      command = [
        helper
        role.policy
        roleName
        target.appIdRegex
        "--"
      ]
      ++ target.command;
      repeat = false;
    };

  roleBindings = lib.mapAttrsToList mkRoleBinding referenceProfile.roles;
  profileRoleNames = builtins.attrNames referenceProfile.roles;
  implementationRoleNames = builtins.attrNames implementations;
  hasValidRolePolicy =
    roleName:
    builtins.elem referenceProfile.roles.${roleName}.policy referenceProfile.options.rolePolicies;

  bindings = config.zaviro.keybindings.bindings;
  bindingKeys = map (binding: binding.key) bindings;
  nativeBindingKeys = [ referenceProfile.navigation.recent.key ];
  shadowedNativeBindingKeys = builtins.filter (key: builtins.elem key bindingKeys) nativeBindingKeys;
  duplicateKeys = lib.unique (
    builtins.filter (
      key: builtins.length (builtins.filter (candidate: candidate == key) bindingKeys) > 1
    ) bindingKeys
  );
  hasOneAction =
    binding:
    (binding.command != null) != (binding.action != null)
    && (binding.command == null || binding.command != [ ]);
  hasValidKey = binding: builtins.match "[-A-Za-z0-9_+]+" binding.key != null;
  hasValidNativeAction =
    binding: binding.action == null || builtins.match "[-a-z0-9]+" binding.action != null;
in
{
  options.zaviro.keybindings.bindings = lib.mkOption {
    type = lib.types.listOf bindingType;
    default = [ ];
    internal = true;
    description = "Resolved semantic and desktop-shell bindings for the active compositor.";
  };

  config = {
    assertions = [
      {
        assertion = referenceProfile.version == "0.7";
        message = "Atlas window-keybindings adapter expects the v0.7 reference profile";
      }
      {
        assertion =
          referenceProfile.options.rolePolicies == [
            "contextual"
            "singleton"
          ];
        message = "window-keybindings v0.7 must expose only contextual and singleton policies";
      }
      {
        assertion = profileRoleNames == implementationRoleNames;
        message = "window-keybindings profile roles and local implementations must match exactly";
      }
      {
        assertion = lib.all hasValidRolePolicy profileRoleNames;
        message = "window-keybindings reference profile contains an unsupported role policy";
      }
      {
        assertion = duplicateKeys == [ ];
        message = "duplicate custom keybindings: ${lib.concatStringsSep ", " duplicateKeys}";
      }
      {
        assertion = shadowedNativeBindingKeys == [ ];
        message = "custom keybindings shadow native niri bindings: ${lib.concatStringsSep ", " shadowedNativeBindingKeys}";
      }
      {
        assertion = lib.all hasOneAction bindings;
        message = "every custom keybinding must define exactly one non-empty command or native action";
      }
      {
        assertion = lib.all hasValidKey bindings;
        message = "custom keybindings contain an invalid compositor key chord";
      }
      {
        assertion = lib.all hasValidNativeAction bindings;
        message = "custom keybindings contain an invalid native action name";
      }
    ];

    home.packages = [ windowKeybindings ];

    zaviro.keybindings.bindings = roleBindings ++ [
      {
        key = referenceProfile.navigation.search.key;
        title = "Open Noctalia Launcher";
        command = [
          "noctalia"
          "msg"
          "panel-toggle"
          "launcher"
        ];
        repeat = false;
      }
      # Mod+Tab is supplied by niri's enabled-by-default recent-windows
      # switcher. Keeping it out of normal binds preserves the MRU UI and its
      # next/previous behavior instead of shadowing it with an IPC action.
      {
        # Notes owns Mod+N; the displaced Noctalia Control Center lives here.
        key = "Mod+S";
        title = "Toggle Control Center";
        command = [
          "noctalia"
          "msg"
          "panel-toggle"
          "control-center"
        ];
        repeat = false;
      }
      {
        key = "Mod+Shift+Comma";
        title = "Toggle Noctalia Settings";
        command = [
          "noctalia"
          "msg"
          "settings-toggle"
        ];
        repeat = false;
      }
      {
        key = "Mod+X";
        title = "Toggle Session Menu";
        command = [
          "noctalia"
          "msg"
          "panel-toggle"
          "session"
        ];
        repeat = false;
      }
      {
        key = "Mod+Alt+V";
        title = "Toggle Clipboard Manager";
        command = [
          "noctalia"
          "msg"
          "panel-toggle"
          "clipboard"
        ];
        repeat = false;
      }
      {
        key = "Super+Alt+L";
        title = "Lock the Screen";
        command = [
          "noctalia"
          "msg"
          "session"
          "lock"
        ];
        repeat = false;
      }
    ];
  };
}
