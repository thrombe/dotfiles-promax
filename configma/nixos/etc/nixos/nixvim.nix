{
  inputs,
  system,
  ...
}: (inputs.nixvim.legacyPackages.${system}.makeNixvim {
  opts = {
    signcolumn = "yes"; # gutter on the left

    guicursor = "";

    number = true;
    relativenumber = true;

    tabstop = 4;
    softtabstop = 4;
    shiftwidth = 4;
    expandtab = true;

    # wrap = false;

    smartindent = true;

    hlsearch = false;
    incsearch = true;

    termguicolors = true;

    scrolloff = 5;
  };
  globals.mapleader = " ";
  colorschemes.gruvbox.enable = true;

  extraConfigLua =
    /*
    lua
    */
    ''
      -- transparent background char
      vim.cmd('highlight Normal guibg=NONE ctermbg=NONE')

      -- keep yanked stuff in register when pasting over other things
      vim.keymap.set("x", "<leader>p", "\"_dP")

      -- leader y to copy to system clipboard TODO: don't also copy to vim clipboard
      vim.keymap.set("n", "<leader>y", "\"+y")
      vim.keymap.set("v", "<leader>y", "\"+y")
      vim.keymap.set("n", "<leader>Y", "\"+Y")

      -- leader p to paste from system clipboard
      vim.keymap.set("n", "<leader>p", "\"+p")
      vim.keymap.set("v", "<leader>p", "\"+p")
      vim.keymap.set("n", "<leader>P", "\"+P")
      vim.keymap.set("v", "<leader>P", "\"+P")

      -- alt + d to delete without copying
      vim.keymap.set("n", "<M-d>", "\"_d")
      vim.keymap.set("v", "<M-d>", "\"_d")

      -- goto last buffer
      vim.keymap.set("n", "ga", ":b#<CR>")

      -- more gotos
      vim.keymap.set("n", "gh", "0")
      vim.keymap.set("v", "gh", "0")
      vim.keymap.set("n", "gs", "^")
      vim.keymap.set("v", "gs", "^")
      vim.keymap.set("n", "gl", "$")
      vim.keymap.set("v", "gl", "$")
    '';

  plugins = {
    lsp = {
      enable = true;

      # using lsps from outside this flake
      #
      # - [lspconfig configs](https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md)
      # require('lspconfig').clangd.setup{}
      #
      # - [enabledServers - nixvim docs](https://nix-community.github.io/nixvim/plugins/lsp/enabledServers.html)
      enabledServers =
        (map (ls: {
          name = ls;
          extraOptions = {};
        }) ["nil_ls" "clangd"])
        ++ [
        ];

      # - [clangd - nixvim docs](https://nix-community.github.io/nixvim/plugins/lsp/servers/clangd/index.html)
      # lsps sourced from this flake
      servers = {
        # clangd.enable = true;
      };

      keymaps = {
        lspBuf = {
          "<leader>k" = "hover";
          gr = "references";
          gd = "definition";
          gi = "implementation";
          gy = "type_definition";
        };
        diagnostic = {
          "[d" = "goto_prev";
          "]d" = "goto_next";
        };
      };
    };
    cmp = {
      enable = true;
      autoEnableSources = true;
      settings = {
        sources = [
          {name = "nvim_lsp";}
          {name = "buffer";}
        ];
        mapping = {
          "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
          "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
        };
      };
    };
    cmp-buffer.enable = true;
    cmp-path.enable = true;
    cmp-cmdline.enable = true;
    cmp-nvim-lsp.enable = true;
    cmp-treesitter.enable = true;
    bufferline.enable = true;
    telescope = {
      enable = true;
      keymaps = {
        "<leader>F" = "git_files";
        "<leader>f" = "find_files";
        "<leader>b" = "buffers";
        "<leader>/" = "live_grep";
      };
    };
    treesitter = {
      enable = true;
      incrementalSelection = {
        enable = true;
        keymaps = {
          initSelection = "<M-o>";
          nodeDecremental = "<M-i>";
          nodeIncremental = "<M-o>";
          # scopeIncremental = "<C-u>";
        };
      };
    };
    # commentary.enable = true;
    comment = {
      enable = true;
      settings = {
        toggler = {
          block = "<C-b>";
          line = "<C-c>";
        };
        opleader = {
          line = "<C-c>";
          block = "<C-b>";
        };
      };
    };
    gitgutter.enable = true;
    nvim-autopairs.enable = true;
    # TODO: check how to set up keymaps for it
    # undotree = {
    #   enable = true;
    # };

    # clangd-extensions.enable = true;
    # lazy.plugins = [];
  };
  # You can use `extraSpecialArgs` to pass additional arguments to your module files
  # extraSpecialArgs = {
  #   # inherit (inputs) foo;
  # };
})
