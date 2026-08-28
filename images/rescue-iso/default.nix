{
  claudeCodePackage,
  modulesPath,
  pkgs,
  ...
}:

let
  claudeSettingsTemplate = pkgs.writeText "claude-live-settings.json" (
    builtins.toJSON {
      env = {
        ANTHROPIC_BASE_URL = "https://api.deepseek.com/anthropic";
        ANTHROPIC_DEFAULT_SONNET_MODEL = "deepseek-v4-pro";
        ANTHROPIC_DEFAULT_HAIKU_MODEL = "deepseek-v4-flash";
      };
      model = "haiku";
    }
  );

  claudeLiveSetup = pkgs.writeShellApplication {
    name = "claude-live-setup";
    runtimeInputs = with pkgs; [
      coreutils
      jq
      util-linux
    ];
    text = ''
      if [[ $EUID -ne 0 ]]; then
        exec sudo "$0" "$@"
      fi

      source_arg="''${1:-/dev/disk/by-partlabel/disk-main-root}"
      mount_dir=""

      cleanup() {
        if [[ -n "$mount_dir" ]]; then
          umount "$mount_dir" 2>/dev/null || true
          rmdir "$mount_dir" 2>/dev/null || true
        fi
      }
      trap cleanup EXIT

      if [[ -f "$source_arg" ]]; then
        source_settings="$source_arg"
      else
        if [[ ! -b "$source_arg" ]]; then
          echo "claude-live-setup: source is neither a settings file nor a block device: $source_arg" >&2
          exit 1
        fi

        mount_dir="$(mktemp -d /run/claude-live-import.XXXXXX)"
        mount -o ro,subvol=@home "$source_arg" "$mount_dir"
        source_settings="$mount_dir/zaviro/.claude/settings.json"
      fi

      if [[ ! -r "$source_settings" ]]; then
        echo "claude-live-setup: cannot read $source_settings" >&2
        exit 1
      fi

      destination_dir=/home/nixos/.claude
      destination="$destination_dir/settings.json"
      temporary="$(mktemp /run/claude-live-settings.XXXXXX)"
      trap 'rm -f "$temporary"; cleanup' EXIT

      jq -s '
        .[1].env.ANTHROPIC_AUTH_TOKEN as $token
        | if ($token | type) != "string" or ($token | length) == 0 then
            error("ANTHROPIC_AUTH_TOKEN is missing or empty")
          else
            .[0] | .env.ANTHROPIC_AUTH_TOKEN = $token
          end
      ' ${claudeSettingsTemplate} "$source_settings" > "$temporary"

      install -d -m 0700 -o nixos -g users "$destination_dir"
      install -m 0600 -o nixos -g users "$temporary" "$destination"

      echo "Claude Code configuration imported into volatile Live-system storage."
      echo "Run as the nixos user: claude"
    '';
  };
in

{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

  boot.zfs.forceImportRoot = false;

  networking.hostName = "atlas-rescue";

  environment.systemPackages = with pkgs; [
    btrfs-progs
    parted
    gptfdisk
    nvme-cli
    smartmontools
    efibootmgr
    dosfstools
    jq
    git
    ripgrep
    curl
    claudeCodePackage
    claudeLiveSetup
  ];

  system.stateVersion = "26.05";
}
