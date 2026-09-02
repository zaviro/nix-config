{ lib, ... }:

{
  keymaps = [
    {
      mode = "n";
      key = "<Esc>";
      action = "<cmd>nohlsearch<cr>";
      options.desc = "Clear search highlight";
    }
    {
      mode = "n";
      key = "<C-h>";
      action = "<C-w><C-h>";
      options.desc = "Focus left window";
    }
    {
      mode = "n";
      key = "<C-j>";
      action = "<C-w><C-j>";
      options.desc = "Focus lower window";
    }
    {
      mode = "n";
      key = "<C-k>";
      action = "<C-w><C-k>";
      options.desc = "Focus upper window";
    }
    {
      mode = "n";
      key = "<C-l>";
      action = "<C-w><C-l>";
      options.desc = "Focus right window";
    }
    {
      mode = "x";
      key = ">";
      action = ">gv";
      options.desc = "Indent and reselect";
    }
    {
      mode = "x";
      key = "<";
      action = "<gv";
      options.desc = "Unindent and reselect";
    }
    {
      mode = [
        "n"
        "x"
      ];
      key = "<leader>cf";
      action = lib.nixvim.mkRaw ''
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end
      '';
      options.desc = "Format buffer";
    }
  ];
}
