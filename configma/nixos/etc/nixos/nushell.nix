{
  pkgs,
  config,
  ...
}: {
  # - [Nushell - NixOS Wiki](https://nixos.wiki/wiki/Nushell)
  programs = {
    nushell = {
      enable = true;
      # The config.nu can be anywhere you want if you like to edit your Nushell with Nu
      # configFile.source = ./.../config.nu;
      # for editing directly to config.nu
      extraConfig = ''
        let carapace_completer = {|spans|
          carapace $spans.0 nushell $spans | from json
        }
        $env.config = {
         show_banner: false,
         completions: {
           case_sensitive: false # case-sensitive completions
           quick: true    # set to false to prevent auto-selecting completions
           partial: true    # set to false to prevent partial filling of the prompt
           algorithm: "fuzzy"    # prefix or fuzzy
           external: {
               # set to false to prevent nushell looking into $env.PATH to find more suggestions
               enable: true
               # set to lower can improve completion performance at the cost of omitting some options
               max_results: 100
               completer: $carapace_completer # check 'carapace_completer'
             }
           }

          keybindings: [
            # still no fzf tab :(
            # - [Fuzzy Completion Option for nushell · Issue #1275 · nushell/nushell · GitHub](https://github.com/nushell/nushell/issues/1275)
            # - [History (ctrl + r) with fzf](https://github.com/nushell/nushell/issues/1616#issuecomment-1386714173)
            {
              name: fuzzy_history
              modifier: control
              keycode: char_r
              mode: [emacs, vi_normal, vi_insert]
              event: [
                {
                  send: ExecuteHostCommand
                  cmd: "commandline (
                    history
                      | each { |it| $it.command }
                      | uniq
                      | reverse
                      | str join (char -i 0)
                      | fzf --read0 --layout=reverse --height=40% -q (commandline)
                      | decode utf-8
                      | str trim
                  )"
                }
              ]
            }
          ]
        }

        $env.PATH = ($env.PATH |
          split row (char esep) |
          prepend /home/myuser/.apps |
          append /usr/bin/env
        )

        use ~/.cache/starship/init.nu
        # - [starship.nix](https://github.com/NixOS/nixpkgs/blob/nixos-23.11/nixos/modules/programs/starship.nix)
        # $env.STARSHIP_CONFIG = ${(pkgs.formats.toml {}).generate "starship.toml" config.programs.starship.settings}
        $env.STARSHIP_CONFIG = ${(pkgs.formats.toml {}).generate "starship.toml" (import ./starship.nix {})}

        source ~/.cache/nushell/zoxide.nu
      '';
      extraEnv = ''
        mkdir ~/.cache/starship
        starship init nu | save -f ~/.cache/starship/init.nu

        mkdir ~/.cache/nushell
        zoxide init nushell | save -f ~/.cache/nushell/zoxide.nu
      '';
      shellAliases = {
      };
    };
    carapace.enable = true;
    carapace.enableNushellIntegration = true;
  };
}
