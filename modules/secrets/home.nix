{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  cachixPush = pkgs.writeShellApplication {
    name = "cachix-push";
    runtimeInputs = [ pkgs.cachix ];
    text = ''
      token_file=${lib.escapeShellArg config.sops.secrets."cachix-auth-token".path}

      if [[ ! -r "$token_file" ]]; then
        echo "cachix-push: sops-nix token is unavailable" >&2
        exit 1
      fi

      token="$(<"$token_file")"
      if [[ -z "$token" ]]; then
        echo "cachix-push: sops-nix token is empty" >&2
        exit 1
      fi

      export CACHIX_AUTH_TOKEN="$token"
      exec cachix push zaviro "$@"
    '';
  };
in

{
  nix.extraOptions = ''
    !include ${osConfig.sops.templates."nix-access-tokens.conf".path}
  '';

  home.packages = with pkgs; [
    age
    cachix
    cachixPush
    sops
  ];

  sops = {
    age.keyFile = "/home/zaviro/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;
    secrets.cachix-auth-token = { };
  };
}
