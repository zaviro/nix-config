{
  lib,
  writeShellApplication,
  coreutils,
  devenv,
  nixd,
}:

writeShellApplication {
  name = "nix-lsp-dispatch";
  runtimeInputs = [ coreutils ];
  text = ''
    dir="$PWD"

    while true; do
      if [ -f "$dir/devenv.nix" ]; then
        cd "$dir"
        exec ${lib.getExe devenv} lsp
      fi

      [ "$dir" = "/" ] && break
      dir="$(dirname "$dir")"
    done

    exec ${lib.getExe nixd}
  '';
}
