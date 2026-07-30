{ lib, ... }:

{
  programs.nixvim = {
    enable = true;
    # 复用 Home Manager 的包集，避免 Nixvim 再导入自身锁定的 nixpkgs。
    nixpkgs.useGlobalPackages = true;

    # 同时设置默认编辑器和常用兼容别名。
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;

    # 必须先定义 leader，否则后续映射会按 Vim 默认值解析。
    globals.mapleader = " ";

    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        transparent_background = false;
      };
    };

    plugins = {
      treesitter.enable = true;
      telescope.enable = true;
      which-key.enable = true;
      gitsigns.enable = true;
      web-devicons.enable = true;
      nvim-ufo.enable = true;

      lsp = {
        enable = true;
        servers = {
          ts_ls = {
            enable = true;
            # 限定前端文件类型，避免与其他语言服务器重复接管缓冲区。
            filetypes = lib.mkForce [
              "javascript"
              "javascriptreact"
              "typescript"
              "typescriptreact"
            ];
          };
          nixd.enable = true;
          bashls.enable = true;
          lua_ls.enable = true;
        };
      };
    };

    opts = {
      number = true;
      relativenumber = true;
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
      mouse = "a";
      termguicolors = true;

      # Treesitter 提供折叠范围，启动时默认展开全部层级。
      foldmethod = "expr";
      foldexpr = "v:lua.vim.treesitter.foldexpr()";
      foldlevel = 99;
      foldlevelstart = 99;
      foldenable = true;
      foldminlines = 1;
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>ff";
        action = "<cmd>Telescope find_files<cr>";
        options.desc = "Find files";
      }
      {
        mode = "n";
        key = "<leader>fg";
        action = "<cmd>Telescope live_grep<cr>";
        options.desc = "Live grep";
      }
    ];

    # nvim-ufo 的 Lua API 无法用声明式 keymaps 完整表达。
    extraConfigLua = ''
      vim.keymap.set("n", "zR", require('ufo').openAllFolds, { desc = "展开所有折叠" })
      vim.keymap.set("n", "zM", require('ufo').closeAllFolds, { desc = "折叠所有内容" })
      vim.keymap.set("n", "zr", require('ufo').openFoldsExceptKinds, { desc = "展开一层折叠" })
      vim.keymap.set("n", "zm", require('ufo').closeFoldsWith, { desc = "折叠一层" })
      vim.keymap.set("n", "za", "za", { desc = "切换当前折叠（原生Vim键）" })
    '';
  };
}
