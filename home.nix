{ config, pkgs, ... }:
let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

  configs = {
    nvim = "nvim";
    rofi = "rofi";
    kitty = "kitty";
    waybar = "waybar";
    hypr = "hypr";
  };
in
{
  home.stateVersion = "25.11";
  home.username = "danil";
  home.homeDirectory = "/home/danil";

  programs.bash = {
    enable = true;
    shellAliases = {
      btw = "echo i use nixos, btw";
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles";
      vim = "nvim";
    };
  };
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };

  home.packages = with pkgs; [
    neovim
    ripgrep
    gcc
    nodejs
    rofi
    starship
    python3
    unzip
    cargo
    fzf
    tree-sitter
    uv
    lua
    bash-language-server
    lua-language-server
    lua55Packages.luacheck
    lua55Packages.luarocks
    prettierd
    ruff
    pyright
    shellcheck
    shfmt
    stylua
    cava
  ];

  xdg.configFile = builtins.mapAttrs
    (name: subpath: {
      source = create_symlink "${dotfiles}/${subpath}";
      recursive = true;
    })
    configs;
}
