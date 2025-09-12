{
  description = "Neovim plugin overlay";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
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
