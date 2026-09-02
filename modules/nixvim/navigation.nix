{ lib, ... }:

{
  dependencies = {
    # 复用 Home Manager 已配置的 CLI，并允许项目环境保持优先。
    fzf.enable = false;
    yazi.enable = false;
  };

  plugins = {
    fzf-lua = {
      enable = true;
      keymaps = {
        "<leader>ff" = {
          action = "files";
          options.desc = "Find files";
        };
        "<leader>fg" = {
          action = "live_grep";
          options.desc = "Live grep";
        };
        "<leader>fb" = {
          action = "buffers";
          options.desc = "Find buffers";
        };
        "<leader>fr" = {
          action = "oldfiles";
          options.desc = "Recent files";
        };
        "<leader>fh" = {
          action = "helptags";
          options.desc = "Help tags";
        };
        "<leader>fk" = {
          action = "keymaps";
          options.desc = "Keymaps";
        };
        "<leader>fs" = {
          action = "lsp_document_symbols";
          options.desc = "Document symbols";
        };
        "<leader>fS" = {
          action = "lsp_workspace_symbols";
          options.desc = "Workspace symbols";
        };
        "<leader>fd" = {
          action = "diagnostics_document";
          options.desc = "Document diagnostics";
        };
        "<leader>fD" = {
          action = "diagnostics_workspace";
          options.desc = "Workspace diagnostics";
        };
      };
    };

    yazi.enable = true;
    flash.enable = true;
  };

  keymaps = [
    {
      mode = "n";
      key = "<leader>e";
      action = "<cmd>Yazi<cr>";
      options.desc = "File manager";
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "s";
      action = lib.nixvim.mkRaw ''
        function()
          require("flash").jump()
        end
      '';
      options.desc = "Flash jump";
    }
  ];
}
