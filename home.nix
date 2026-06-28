{ config, pkgs, ... }:
let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

  configs = {
    wallpaper = "wallpaper";
    nvim = "nvim";
    rofi = "rofi";
    kitty = "kitty";
    waybar = "waybar";
    hypr = "hypr";
    starship = "starship";
    swaync = "swaync";
    satty = "satty";
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
      neofetch = "fastfetch";
      cat = "bat --paging=never";
      # Git
      gs = "git status";
      ga = "git add";
      gc = "git commit -m";
      gp = "git push";
      gl = "git log --oneline --graph --decorate";
      gco = "git checkout";
      # eza
      ls = "eza --icons --group-directories-first";
      ll = "eza -lah --git --icons --group-directories-first";
      la = "eza -a --icons --group-directories-first";
      lt = "eza --tree --level=2 --icons";
      ltree = "eza --tree --icons";
      ld = "eza -D --icons";
      lm = "eza -lah --sort=modified --reverse --icons";
      lg = "eza -lah --git --icons";
      # Nix
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles";
      update = "nix flake update ~/nixos-dotfiles";
      hms = "home-manager switch --flake ~/nixos-dotfiles";
      gcn = "sudo nix-collect-garbage -d";
      ns = "nix-shell";
      nd = "nix develop";
    };
    bashrcExtra = ''
      export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
      eval "$(starship init bash)"

      export MANPAGER='nvim +Man!'

      export EXA_ICONS=1
      export LS_COLORS="$(vdircolors --print-database 2>/dev/null)"

      eval "$(fzf --bash)"

      cl() {
        cd "$1" || return
        eza -lah --git --icons
      }

      export EDITOR=nvim

      export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :200 {}'"
      export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap"
      export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons {}'"
    '';
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
    go
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
    brightnessctl
    eza
    bat
    lazygit
    satty
    hyprshot
    swaynotificationcenter
    hyprpolkitagent
    brave
    adwaita-icon-theme
    wl-clipboard
    file
    (python314.withPackages (ps: with ps; [
      debugpy
    ]))
  ];

  xdg.configFile = builtins.mapAttrs
    (name: subpath: {
      source = create_symlink "${dotfiles}/${subpath}";
      recursive = true;
    })
    configs;
}
