{
  description = "Neovim plugin overlay";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    catppuccin-theme = {
      url = "github:catppuccin/nvim";
      flake = false;
    };
    nightfox-theme = {
      url = "github:EdenEast/nightfox.nvim";
      flake = false;
    };
    startup = {
      url = "github:startup-nvim/startup.nvim";
      flake = false;
    };
    # diagnostic manager stuff
    trouble = {
      url = "github:folke/trouble.nvim";
      flake = false;
    };
    # system shell instance navigation
    vim-tmux-navigator = {
      url = "github:christoomey/vim-tmux-navigator";
      flake = false;
    };
    smart-splits = { # alternative to above tmux navigator for certain systems
      url = "github:mrjones2014/smart-splits.nvim";
      flake = false;
    };
    # tree sitter
    nvim-treesitter = {
      url = "github:nvim-treesitter/nvim-treesitter";
      flake = false;
    };
    playground = {
      url = "github:nvim-treesitter/playground";
      flake = false;
    };
    # markdown preview
    glow = {
      url = "github:ellisonleao/glow.nvim";
      flake = false;
    };
    symbols-outline = {
      url = "github:simrat39/symbols-outline.nvim";
      flake = false;
    };
    # git line blame visualisation
    gitsigns = {
      url = "github:lewis6991/gitsigns.nvim";
      flake = false;
    };
    # terminal toggle
    toggleterm = {
      url = "github:akinsho/toggleterm.nvim";
      flake = false;
    };
    # file tree visualisation
    nvim-tree = {
      url = "github:nvim-tree/nvim-tree.lua";
      flake = false;
    };
    # indent guide lines
    indent-blankline = {
      url = "github:lukas-reineke/indent-blankline.nvim";
      flake = false;
    };
    # autopair brackets
    nvim-autopairs = {
      url = "github:windwp/nvim-autopairs";
      flake = false;
    };
    # go coverage
    nvim-coverage = {
      url = "github:andythigpen/nvim-coverage";
      flake = false;
    };
    neotest = {
      url = "github:nvim-neotest/neotest";
      flake = false;
    };
    FixCursorHold = {
      url = "github:antoinemadec/FixCursorHold.nvim";
      flake = false;
    };
    neotest-go = {
      url = "github:nvim-neotest/neotest-go";
      flake = false;
    };
    lsp_lines = {
      url = "git+https://git.sr.ht/~whynothugo/lsp_lines.nvim";
      flake = false;
    };
    # -----
    nvim-lspconfig = {
      url = "github:neovim/nvim-lspconfig";
      flake = false;
    };
    plenary = {
      url = "github:nvim-lua/plenary.nvim";
      flake = false;
    };
    telescope = {
      url = "github:nvim-telescope/telescope.nvim";
      flake = false;
    };
    telescope-file-browser = {
      url = "github:nvim-telescope/telescope-file-browser.nvim";
      flake = false;
    };
    nvim-web-devicons = {
      url = "github:nvim-tree/nvim-web-devicons";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, ... }@inputs:
    let
      forAllSystems = nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ];
      overlay = final: prev:
        let
          mkPlugin = name: value:
            prev.pkgs.vimUtils.buildVimPlugin {
              pname = name;
              version = value.lastModifiedDate;
              src = value;
              doCheck = false;
            };
          plugins = prev.lib.filterAttrs (name: _: name != "self" && name != "nixpkgs") inputs;
        in
        {
          nvimPlugins = builtins.mapAttrs mkPlugin plugins;
        };
    in
    {
      formatter = forAllSystems (system: nixpkgs.legacyPackages."${system}".nixpkgs-fmt);
      legacyPackages = forAllSystems (system:
        import inputs.nixpkgs {
          inherit system;
          overlays = [ overlay ];
          config.allowUnfree = true;
        }
      );
      overlays.default = overlay;
      nixosConfigurations.test = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ pkgs, ... }: {
            boot.isContainer = true;
            nixpkgs.overlays = [ overlay ];
            system.stateVersion = "25.05";
            programs.neovim = {
              enable = true;
              configure.packages.myVimPackage = {
                opt = builtins.attrValues pkgs.nvimPlugins;
              };
            };
          })
        ];
      };
    };
}
