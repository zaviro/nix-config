{ pkgs, ... }:

{
  i18n.inputMethod.enable = true;
  i18n.inputMethod.type = "fcitx5";

  i18n.inputMethod.fcitx5 = {
    addons = with pkgs; [
      fcitx5-lua
      fcitx5-rime
      qt6Packages.fcitx5-chinese-addons
    ];

    settings = {
      inputMethod = {
        "Groups/0" = {
          Name = "默认";
          "Default Layout" = "us";
          DefaultIM = "rime";
        };
        "Groups/0/Items/0" = {
          Name = "rime";
          Layout = "";
        };
        "Groups/0/Items/1" = {
          Name = "keyboard-us";
          Layout = "us";
        };
        GroupOrder."0" = "默认";
      };

      globalOptions = {
        Hotkey = {
          EnumerateWithTriggerKeys = true;
          AltTriggerKeys = "";
          EnumerateForwardKeys = "";
          EnumerateBackwardKeys = "";
          EnumerateSkipFirst = false;
        };

        # CapsLock is reserved for switching Chinese/English in Fcitx5.
        # Known limitation: its input-method state can still become out of sync
        # with the keyboard's case state. Keep this mapping for now; resolving
        # that mismatch needs a separate investigation.
        # The Niri/XKB layer intentionally keeps Shift+CapsLock available
        # for the system's case-lock toggle; do not treat Caps_Lock: noop in
        # Rime as disabling that lower-level XKB behavior.
        "Hotkey/TriggerKeys"."0" = "Caps_Lock";
        "Hotkey/EnumerateGroupForwardKeys"."0" = "Super+space";
        "Hotkey/EnumerateGroupBackwardKeys"."0" = "Shift+Super+space";
        "Hotkey/ActivateKeys"."0" = "Hangul_Hanja";
        "Hotkey/DeactivateKeys"."0" = "Hangul_Romaja";
        "Hotkey/PrevPage"."0" = "Up";
        "Hotkey/NextPage"."0" = "Down";
        "Hotkey/PrevCandidate"."0" = "Shift+Tab";
        "Hotkey/NextCandidate"."0" = "Tab";
        "Hotkey/TogglePreedit"."0" = "Control+Alt+P";

        Behavior = {
          ActiveByDefault = false;
          ShareInputState = "All";
          PreeditEnabledByDefault = true;
          ShowInputMethodInformation = true;
          showInputMethodInformationWhenFocusIn = false;
          CompactInputMethodInformation = true;
          ShowFirstInputMethodInformation = true;
          DefaultPageSize = 5;
          OverrideXkbOption = false;
          CustomXkbOption = "";
          EnabledAddons = "";
          DisabledAddons = "";
          PreloadInputMethod = true;
          AllowInputMethodForPassword = false;
          ShowPreeditForPassword = false;
          AutoSavePeriod = 30;
        };
      };

      addons = {
        classicui.globalSection = {
          VerticalCandidateList = false;
          WheelForPaging = true;
          Font = "Sans Serif 15";
          MenuFont = "Sans 10";
          TrayFont = "Sans Bold 10";
          Theme = "default-dark";
          DarkTheme = "default-dark";
          UseDarkTheme = false;
          UseAccentColor = true;
          EnableFractionalScale = true;
        };

        notifications.sections.HiddenNotifications = {
          "0" = "fcitx-rime-deploy";
          "1" = "wayland-diagnose-gnome";
        };

        chttrans = {
          globalSection = {
            Engine = "OpenCC";
            EnabledIM = "";
            OpenCCS2TProfile = "default";
            OpenCCT2SProfile = "default";
          };
          sections.Hotkey."0" = "Control+Shift+F";
        };

        punctuation = {
          globalSection = {
            HalfWidthPuncAfterLetterOrNumber = true;
            TypePairedPunctuationsTogether = false;
            Enabled = true;
          };
          sections.Hotkey."0" = "Control+period";
        };
      };
    };
  };

  xdg.dataFile."fcitx5/rime/default.yaml".source = ./rime/default.yaml;
  xdg.dataFile."fcitx5/rime/default.custom.yaml".source = ./rime/default.custom.yaml;
}
