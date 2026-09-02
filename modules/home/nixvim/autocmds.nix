{
  autoGroups = {
    nixvim-highlight-yank.clear = true;
    nixvim-checktime.clear = true;
    nixvim-last-location.clear = true;
  };

  autoCmd = [
    {
      event = [ "TextYankPost" ];
      desc = "Highlight yanked text";
      group = "nixvim-highlight-yank";
      callback.__raw = ''
        function()
          vim.hl.on_yank()
        end
      '';
    }
    {
      event = [
        "FocusGained"
        "TermClose"
        "TermLeave"
      ];
      desc = "Reload files changed outside Neovim";
      group = "nixvim-checktime";
      callback.__raw = ''
        function()
          if vim.bo.buftype ~= "nofile" then
            vim.cmd("checktime")
          end
        end
      '';
    }
    {
      event = [ "BufReadPost" ];
      desc = "Restore last cursor position";
      group = "nixvim-last-location";
      callback.__raw = ''
        function(event)
          local buf = event.buf
          local excluded = {
            gitcommit = true,
            jjdescription = true,
          }
          if excluded[vim.bo[buf].filetype] or vim.b[buf].nixvim_last_location then
            return
          end

          vim.b[buf].nixvim_last_location = true
          local mark = vim.api.nvim_buf_get_mark(buf, '"')
          local line_count = vim.api.nvim_buf_line_count(buf)
          if mark[1] > 0 and mark[1] <= line_count then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
          end
        end
      '';
    }
  ];
}
