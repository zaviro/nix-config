# This file defines our overlays.
# Overlays are used to customize nixpkgs, for instance to add packages or
# change versions. They are also used to expose custom packages and unstable
# packages to our configurations.
#
# See https://nixos.wiki/wiki/Overlays for more information.
{ inputs, ... }:

{
  # This overlay brings our custom packages from the 'pkgs' directory.
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # This overlay contains whatever modifications we want to apply to nixpkgs.
  # For example, changing versions, adding patches, setting compilation flags,
  # or anything else you want to customize in nixpkgs.
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
  };

  # When using nixpkgs-unstable (current default), this overlay is equivalent
  # to the primary nixpkgs — kept for structural consistency with the standard
  # template. If you switch to a stable nixpkgs later, uncomment the
  # nixpkgs-unstable input in flake.nix to keep accessing bleeding-edge packages
  # via `pkgs.unstable`.
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
