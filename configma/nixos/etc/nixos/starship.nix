{}: {
  # - [Configuration | Starship](https://starship.rs/config/#prompt)
  # - [Customize Linux Terminal Prompt](https://www.maketecheasier.com/customize-linux-terminal-prompt-using-starship/)

  # check logs in ~/.cache/starship

  "$schema" = "https://starship.rs/config-schema.json";
  add_newline = true;
  format = "\${directory}\${nix_shell}\${custom.fhs_shell}\${python}\${shell}\${character}";
  # right_format = "$all";
  right_format = "\${git_branch}\${git_commit}\${git_state}\${git_metrics}\${git_status}";

  # ❯ ➜ ➤
  character = {
    format = " $symbol ";
    success_symbol = "[➤](bold green)";
    error_symbol = "[➤](bold red)";
  };
  shell = {
    disabled = false;
    zsh_indicator = "";
    format = "[ $indicator]($style)";
  };
  nix_shell = {
    format = "[ $symbol]($style)";
    symbol = "❄️";
  };
  custom.fhs_shell = {
    format = "[ \\(FHS\\)]($style)";
    style = "bold blue";
    when = ''test "$FHS" = "1" '';
  };
  python = {
    version_format = "";
    format = "[( \\(\$virtualenv\\))]($style)";
  };
  directory = {
    format = "[ $path]($style)";
    truncation_length = 1;
    truncation_symbol = "…/";
  };

  # Here is how you can shorten some long paths by text replacement
  # similar to mapped_locations in Oh My Posh:
  directory.substitutions = {
    "Documents" = "󰈙 ";
    "Downloads" = " ";
    "Music" = " ";
    "Pictures" = " ";
    # Keep in mind that the order matters. For example:
    # "Important Documents" = " 󰈙 "
    # will not be replaced, because "Documents" was already substituted before.
    # So either put "Important Documents" before "Documents" or use the substituted version:
    # "Important 󰈙 " = " 󰈙 "
  };
  git_branch = {
    format = "[$symbol$branch(:$remote_branch)]($style) ";
  };
  username = {
    show_always = true;
    style_user = "bg:#9A348E";
    style_root = "bg:#9A348E";
    format = "[$user]($style)";
    disabled = true;
  };
  os = {
    format = "[$symbol]($style)";
    disabled = true; # Disabled by default
  };
}
