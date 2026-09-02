{
  plugins = {
    guess-indent.enable = true;

    mini = {
      enable = true;
      modules = {
        ai.n_lines = 500;
        surround.mappings = {
          add = "gza";
          delete = "gzd";
          find = "gzf";
          find_left = "gzF";
          highlight = "gzh";
          replace = "gzr";
          update_n_lines = "gzn";
        };
      };
    };
  };
}
