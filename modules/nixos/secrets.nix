{
  config,
  sops-nix,
  ...
}:

{
  imports = [ sops-nix.nixosModules.sops ];

  sops = {
    age.keyFile = "/home/zaviro/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;

    secrets.nix-github-token = {
      owner = "zaviro";
      mode = "0400";
    };

    templates."nix-access-tokens.conf" = {
      content = ''
        access-tokens = github.com=${config.sops.placeholder.nix-github-token}
      '';
      owner = "zaviro";
      mode = "0400";
    };
  };
}
