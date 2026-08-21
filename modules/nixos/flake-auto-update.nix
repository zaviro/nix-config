{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.nixos-flake-update;
  hmPackages = lib.attrByPath [ "home-manager" "users" cfg.user "home" "packages" ] [ ] config;
  trackedPackageNames = lib.unique (
    map lib.getName (config.environment.systemPackages ++ hmPackages) ++ cfg.extraTrackedPackages
  );
  trackedPackagesFile = pkgs.writeText "nixos-flake-update-tracked-packages" (
    lib.concatStringsSep "\n" trackedPackageNames
  );
  updater = pkgs.writeShellApplication {
    name = "nixos-flake-update";
    runtimeInputs = [
      config.nix.package
      pkgs.coreutils
      pkgs.dix
      pkgs.diffutils
      pkgs.jq
      pkgs.jujutsu
      pkgs.libnotify
      pkgs.nh
    ];
    text = ''
      repo=${lib.escapeShellArg cfg.repo}
      host=${lib.escapeShellArg cfg.host}
      interval_seconds=$(( ${toString cfg.intervalDays} * 86400 ))
      state_dir="$STATE_DIRECTORY"
      last_success="$state_dir/last-success"
      candidate="$state_dir/candidate.lock"
      dix_json="$state_dir/last-dix.json"
      dix_diff="$state_dir/last-dix.diff"
      message_file="$state_dir/message"
      tracked_packages=${lib.escapeShellArg trackedPackagesFile}
      sudo=/run/wrappers/bin/sudo
      nh=${lib.escapeShellArg (lib.getExe pkgs.nh)}
      nix_env=${lib.escapeShellArg "${config.nix.package}/bin/nix-env"}
      update_change=""
      update_commit=""
      lock_change=""
      created_update_change=0
      phase="candidate"
      deferred=0
      failure_summary="Updater exited unexpectedly"

      notify() {
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus" \
          notify-send --app-name="NixOS flake update" "$1" "$2" \
          || log "warning: desktop notification failed: $1"
      }

      log() {
        printf '%s\n' "$*"
      }

      fail() {
        failure_summary="$1"
        log "failed: $failure_summary"
        exit 1
      }

      defer() {
        deferred=1
        log "defer: $1"
        exit 1
      }

      mark_success() {
        date +%s > "$last_success"
      }

      safe_abandon_update() {
        if [[ -z "$update_change" ]]; then
          return 0
        fi

        current_update_commit=$(jj log --no-graph -r "$update_change" -T 'commit_id' 2>/dev/null || true)
        if [[ "$current_update_commit" != "$update_commit" ]]; then
          log "preserve: update change was modified concurrently; refusing to abandon $update_change"
          return 1
        fi

        log "abandon update change $update_change"
        if ! jj abandon "$update_change"; then
          log "critical: failed to abandon update change $update_change"
          return 1
        fi
      }

      restore_uncommitted_lock() {
        current_lock_change=$(jj log --no-graph -r @ -T 'change_id' 2>/dev/null || true)
        if [[ "$current_lock_change" != "$lock_change" ]]; then
          log "preserve: working copy moved while the lock candidate was uncommitted"
          return 1
        fi
        if ! cmp -s flake.lock "$candidate"; then
          log "preserve: flake.lock changed concurrently; leaving it untouched"
          return 1
        fi

        jj restore --from @- flake.lock
        jj status >/dev/null
        log "restored uncommitted flake.lock candidate"

        if (( created_update_change )); then
          remaining_files=$(jj diff --name-only -r @)
          remaining_description=$(jj log --no-graph -r @ -T 'description')
          if [[ -z "$remaining_files" && -z "$remaining_description" ]]; then
            jj abandon @
            log "removed empty automatic JJ change"
          fi
        fi
      }

      restore_exact_generation() {
        recovery_link="/nix/var/nix/profiles/system-$old_generation-link"
        if [[ ! -x "$recovery_link/bin/switch-to-configuration" ]]; then
          log "critical: recovery generation $old_generation is unavailable"
          return 1
        fi
        if [[ "$(readlink -f "$recovery_link")" != "$old_system" ]]; then
          log "critical: recovery generation $old_generation no longer matches $old_system"
          return 1
        fi

        log "rollback: restoring exact NixOS generation $old_generation"
        if ! "$sudo" "$nix_env" \
          --profile /nix/var/nix/profiles/system \
          --switch-generation "$old_generation"; then
          log "critical: failed to restore the persistent system profile"
          return 1
        fi
        if ! "$sudo" "$recovery_link/bin/switch-to-configuration" switch; then
          log "critical: failed to reactivate recovery generation $old_generation"
          return 1
        fi
        if [[ "$(readlink -f /run/current-system)" != "$old_system" ]]; then
          log "critical: active system does not match recovered generation $old_generation"
          return 1
        fi
        if [[ "$(readlink -f /nix/var/nix/profiles/system)" != "$old_system" ]]; then
          log "critical: persistent profile does not match recovered generation $old_generation"
          return 1
        fi
      }

      cleanup() {
        rc=$?
        trap - EXIT TERM INT

        if (( rc == 0 )); then
          exit 0
        fi

        cleanup_ok=1
        activation_interrupted=0

        case "$phase" in
          working-lock)
            if ! restore_uncommitted_lock; then
              cleanup_ok=0
            fi
            ;;
          validating)
            if ! safe_abandon_update; then
              cleanup_ok=0
            fi
            ;;
          activating)
            activation_interrupted=1
            log "critical: updater stopped during activation; preserving update change for recovery"
            ;;
        esac

        if (( deferred && cleanup_ok )); then
          exit 0
        fi

        if (( ! cleanup_ok )); then
          failure_summary="$failure_summary; automatic cleanup also failed"
        fi

        if (( activation_interrupted )); then
          notify \
            "Flake update needs review" \
            "Updater was interrupted during activation; preserving its update change."
        else
          notify \
            "Flake update failed" \
            "$failure_summary. Check: journalctl -u nixos-flake-update.service -e"
        fi

        exit "$rc"
      }

      trap cleanup EXIT
      trap 'exit 143' TERM
      trap 'exit 130' INT

      cd "$repo"

      now=$(date +%s)
      if [[ -s "$last_success" ]]; then
        previous=$(cat "$last_success")
        if [[ "$previous" =~ ^[0-9]+$ ]] && (( now - previous < interval_seconds )); then
          log "skip: last successful check is less than ${toString cfg.intervalDays} days old"
          exit 0
        fi
      fi

      log "start flake input update"
      jj status >/dev/null
      initial_commit=$(jj log --no-graph -r @ -T 'commit_id')
      initial_files=$(jj diff --name-only -r @)
      initial_description=$(jj log --no-graph -r @ -T 'description')

      rm -f "$candidate"
      if ! nix flake update --output-lock-file "$candidate"; then
        fail "nix flake update"
      fi

      jj status >/dev/null
      if [[ "$(jj log --no-graph -r @ -T 'commit_id')" != "$initial_commit" ]]; then
        defer "working-copy change moved while resolving the candidate lock"
      fi

      if cmp -s flake.lock "$candidate"; then
        mark_success
        log "success: flake.lock is already current"
        exit 0
      fi

      if [[ -n "$initial_files" || -n "$initial_description" ]]; then
        jj new
        created_update_change=1
        log "created a new JJ change for the automatic update"
      fi

      lock_change=$(jj log --no-graph -r @ -T 'change_id')
      phase="working-lock"
      cp "$candidate" flake.lock
      jj status >/dev/null

      changed_files=$(jj diff --name-only -r @)
      if [[ "$changed_files" != "flake.lock" ]]; then
        defer "concurrent working-copy changes appeared before source freeze"
      fi

      if ! archive_json=$(nix flake archive --json --no-update-lock-file .); then
        fail "freeze flake source in the Nix store"
      fi
      source_path=$(printf '%s\n' "$archive_json" | jq -r '.path')
      if [[ -z "$source_path" || "$source_path" == "null" || ! -d "$source_path" ]]; then
        fail "could not resolve frozen flake source in the Nix store"
      fi

      jj status >/dev/null
      changed_files=$(jj diff --name-only -r @)
      if [[ "$changed_files" != "flake.lock" ]]; then
        defer "concurrent working-copy changes appeared while freezing source"
      fi

      jj describe -m "chore: update flake inputs"
      update_change=$(jj log --no-graph -r @ -T 'change_id')
      update_commit=$(jj log --no-graph -r @ -T 'commit_id')
      jj new
      phase="validating"
      log "candidate: $update_change ($update_commit)"
      log "source: $source_path"
      old_system=$(readlink -f /run/current-system)
      old_profile_system=$(readlink -f /nix/var/nix/profiles/system)
      old_profile_link=$(readlink /nix/var/nix/profiles/system)
      if [[ "$old_profile_link" =~ ^system-([0-9]+)-link$ ]]; then
        old_generation="''${BASH_REMATCH[1]}"
      else
        fail "resolve current NixOS generation"
      fi
      if [[ "$old_profile_system" != "$old_system" ]]; then
        fail "active system and persistent profile differ before validation"
      fi
      log "recovery: generation $old_generation ($old_system)"

      if ! nix flake check "path:$source_path"; then
        fail "nix flake check"
      fi
      log "check: ok"

      if ! eval_hosts_json=$(
        nix eval --json \
          --apply 'configs: builtins.attrNames configs' \
          "path:$source_path#nixosConfigurations"
      ); then
        fail "enumerate nixosConfigurations"
      fi
      if ! eval_hosts_text=$(printf '%s\n' "$eval_hosts_json" | jq -r '.[]'); then
        fail "parse nixosConfigurations list"
      fi

      while IFS= read -r eval_host; do
        if [[ -z "$eval_host" || "$eval_host" == "$host" ]]; then
          continue
        fi
        if ! nix eval --raw \
          "path:$source_path#nixosConfigurations.$eval_host.config.system.build.toplevel.drvPath" \
          >/dev/null; then
          fail "evaluate $eval_host system toplevel"
        fi
        log "eval: $eval_host ok"
      done <<< "$eval_hosts_text"

      if ! new_system=$(nix build \
        --no-link \
        --print-out-paths \
        "path:$source_path#nixosConfigurations.$host.config.system.build.toplevel"); then
        fail "build $host system toplevel"
      fi
      log "build: $new_system"

      current_update_commit=$(jj log --no-graph -r "$update_change" -T 'commit_id' 2>/dev/null || true)
      if [[ "$current_update_commit" != "$update_commit" ]]; then
        phase="preserve"
        defer "update change was modified concurrently; no history or system action taken"
      fi

      direct_changes=""
      if ! dix --force-correctness "$old_system" "$new_system" | tee "$dix_diff"; then
        log "warning: dix human diff failed"
      fi

      if dix --force-correctness --output json "$old_system" "$new_system" > "$dix_json"; then
        if ! direct_changes=$(
          jq -r --rawfile tracked "$tracked_packages" '
            ($tracked | split("\n") | map(select(length > 0))) as $names
            | .diffs[]
            | select(.name as $name | $names | index($name))
            | .name as $name
            | .versions[]
            | if .kind == "changed" then
                "\($name): \(.old.name) -> \(.new.name)"
              elif .kind == "added" then
                "\($name): +\(.version.name)"
              elif .kind == "removed" then
                "\($name): -\(.version.name)"
              elif .kind == "amount_changed" then
                "\($name): \(.version.name) (\(.old_amount) -> \(.new_amount))"
              else empty
              end
          ' "$dix_json"
        ); then
          direct_changes=""
          log "warning: failed to parse dix JSON; continuing without a commit-body summary"
        fi
      else
        log "warning: dix JSON output failed; continuing without a commit-body summary"
      fi

      {
        printf '%s\n' "chore: update flake inputs"
        if [[ -n "$direct_changes" ]]; then
          printf '\nSystem changes:\n'
          printf '%s\n' "$direct_changes"
        fi
      } > "$message_file"
      jj describe -r "$update_change" --stdin < "$message_file"
      update_commit=$(jj log --no-graph -r "$update_change" -T 'commit_id')

      if [[ "$old_system" == "$new_system" ]]; then
        phase="done"
        mark_success
        log "success: inputs updated; $host system toplevel is unchanged"
        notify "Flake inputs updated" "Validation passed; the active system is unchanged."
        exit 0
      fi

      if [[ "$(readlink -f /run/current-system)" != "$old_system" ]]; then
        defer "current system changed during validation"
      fi

      current_update_commit=$(jj log --no-graph -r "$update_change" -T 'commit_id' 2>/dev/null || true)
      if [[ "$current_update_commit" != "$update_commit" ]]; then
        phase="preserve"
        defer "update change was modified before activation"
      fi

      phase="activating"
      if ! NH_ELEVATION_STRATEGY="$sudo" "$nh" os test "$new_system"; then
        failure_summary="nh os test"
        log "failed: $failure_summary"
        if ! restore_exact_generation; then
          phase="preserve"
          failure_summary="nh os test failed and exact recovery failed; update change preserved for manual recovery"
          log "critical: $failure_summary"
          exit 1
        fi
        phase="validating"
        exit 1
      fi
      if [[ "$(readlink -f /run/current-system)" != "$new_system" ]]; then
        failure_summary="nh os test did not activate the exact built system"
        log "failed: $failure_summary"
        if ! restore_exact_generation; then
          phase="preserve"
          failure_summary="$failure_summary and exact recovery failed; update change preserved for manual recovery"
          log "critical: $failure_summary"
          exit 1
        fi
        phase="validating"
        exit 1
      fi
      if [[ "$(readlink -f /nix/var/nix/profiles/system)" != "$old_system" ]]; then
        failure_summary="nh os test changed the persistent system profile"
        log "failed: $failure_summary"
        if ! restore_exact_generation; then
          phase="preserve"
          failure_summary="$failure_summary and exact recovery failed; update change preserved for manual recovery"
          log "critical: $failure_summary"
          exit 1
        fi
        phase="validating"
        exit 1
      fi
      log "test: $new_system"

      if ! NH_ELEVATION_STRATEGY="$sudo" "$nh" os switch "$new_system"; then
        failure_summary="nh os switch"
        log "failed: $failure_summary"
        if ! restore_exact_generation; then
          phase="preserve"
          failure_summary="nh os switch failed and exact recovery failed; update change preserved for manual recovery"
          log "critical: $failure_summary"
          exit 1
        fi
        phase="validating"
        exit 1
      fi
      if [[ "$(readlink -f /run/current-system)" != "$new_system" ]] \
        || [[ "$(readlink -f /nix/var/nix/profiles/system)" != "$new_system" ]]; then
        failure_summary="nh os switch did not activate the exact built system"
        log "failed: $failure_summary"
        if ! restore_exact_generation; then
          phase="preserve"
          failure_summary="$failure_summary and exact recovery failed; update change preserved for manual recovery"
          log "critical: $failure_summary"
          exit 1
        fi
        phase="validating"
        exit 1
      fi

      phase="done"
      mark_success
      log "success: switched $host to $new_system"
      notify "Flake inputs updated" "Validation and system switch completed."
    '';
  };
in
{
  options.services.nixos-flake-update = {
    enable = lib.mkEnableOption "periodic local flake input updates with JJ history and NixOS validation";

    repo = lib.mkOption {
      type = lib.types.str;
      description = "Absolute path to the colocated Jujutsu/Git NixOS flake repository.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      description = "User that owns the repository and Jujutsu working copy.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = "nixosConfigurations attribute to build and activate.";
    };

    intervalDays = lib.mkOption {
      type = lib.types.ints.positive;
      default = 7;
      description = "Minimum number of days between successful update checks.";
    };

    extraTrackedPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional package names whose dix changes should be included in the JJ description.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.nixos-flake-update = {
      description = "Update, validate, and activate Nix flake inputs";
      restartIfChanged = false;
      stopIfChanged = false;
      unitConfig.X-StopOnRemoval = false;
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        WorkingDirectory = cfg.repo;
        StateDirectory = "nixos-flake-update";
        Nice = 19;
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
        TimeoutStartSec = "4h";
        UMask = "0077";
        ExecStart = lib.getExe updater;
      };
    };

    systemd.timers.nixos-flake-update = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "1h";
        Unit = "nixos-flake-update.service";
      };
    };
  };
}
