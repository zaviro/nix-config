{
  plugins.conform-nvim = {
    enable = true;
    settings = {
      formatters_by_ft = {
        nix = [ "nixfmt" ];
        javascript = [ "biome" ];
        javascriptreact = [ "biome" ];
        typescript = [ "biome" ];
        typescriptreact = [ "biome" ];
      };
      format_on_save = {
        timeout_ms = 1000;
        lsp_format = "fallback";
      };
    };
  };
}
