{
  globals = {
    mapleader = " ";
    maplocalleader = " ";
  };

  opts = {
    number = true;
    relativenumber = true;
    tabstop = 2;
    shiftwidth = 2;
    expandtab = true;
    mouse = "a";
    termguicolors = true;

    autoread = true;
    breakindent = true;
    undofile = true;
    ignorecase = true;
    smartcase = true;
    signcolumn = "yes";
    updatetime = 250;
    timeoutlen = 300;
    splitright = true;
    splitbelow = true;
    splitkeep = "screen";
    list = true;
    listchars.__raw = "{ tab = '» ', trail = '·', nbsp = '␣' }";
    inccommand = "split";
    cursorline = true;
    scrolloff = 8;
    confirm = true;
    wrap = false;

    foldcolumn = "1";
    foldlevel = 99;
    foldlevelstart = 99;
    foldenable = true;
    foldminlines = 1;
  };
}
