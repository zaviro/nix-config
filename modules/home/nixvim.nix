{ lib, pkgs, ... }:

let
  nixLspDispatch = pkgs.callPackage ../../pkgs/nix-lsp-dispatch.nix { };
in
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
      # 语法高亮、缩进与原生代码折叠共享同一套 Tree-sitter 解析结果。
      treesitter = {
        enable = true;
        highlight.enable = true;
        indent.enable = true;
        folding.enable = true;
      };

      # LSP 补全 UI；默认配置会自动使用已启用语言服务器的能力。
      blink-cmp.enable = true;

      # 紧凑的项目文件树；连续的单子目录会折叠为一条路径。
      nvim-tree = {
        enable = true;
        openOnSetup = true;
        settings.renderer.group_empty = true;
      };

      telescope.enable = true;
      which-key.enable = true;
      gitsigns.enable = true;
      web-devicons.enable = true;
      # 使用 Neovim 内建 LSP API；取代即将移除的 plugins.lsp 接口。
      lspconfig.enable = true;
    };

    lsp.servers = {
      # nvim-lspconfig 尚未自动传播 Blink 的 completion capabilities。
      "*".config.capabilities.__raw = ''
        require("blink-cmp").get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities())
      '';

      ts_ls = {
        enable = true;
        # devshell 中的 TypeScript LSP 优先，Nixvim 自带版本只作 fallback。
        packageFallback = true;
        # 限定前端文件类型，避免与其他语言服务器重复接管缓冲区。
        config.filetypes = lib.mkForce [
          "javascript"
          "javascriptreact"
          "typescript"
          "typescriptreact"
        ];
      };
      nixd = {
        enable = true;
        # nixd 由 Home Manager 全局提供；统一入口负责 devenv 项目分流。
        package = null;
        config = {
          cmd = [ "${nixLspDispatch}/bin/nix-lsp-dispatch" ];
          root_markers = [
            "devenv.nix"
            "flake.nix"
            ".git"
          ];
        };
      };
      bashls.enable = true;
      lua_ls.enable = true;
    };

    opts = {
      number = true;
      relativenumber = true;
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
      mouse = "a";
      termguicolors = true;

      # Tree-sitter 接管原生折叠；启动时默认展开，并显示可点击折叠栏。
      foldcolumn = "1";
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
      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>NvimTreeToggle<cr>";
        options.desc = "File explorer";
      }
    ];
  };
}
