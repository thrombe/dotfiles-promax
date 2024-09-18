{username, ...}: let
  # To add additional extensions, find it on addons.mozilla.org, find
  # the short ID in the url (like https://addons.mozilla.org/en-US/firefox/addon/!SHORT_ID!/)
  # You can install it then find the UUID in about:debugging#/runtime/this-firefox
  extension = shortId: extension-id: {
    name = extension-id;
    value = {
      install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
      installation_mode = "normal_installed";
    };
  };

  extensions = builtins.listToAttrs [
    # (extension "tree-style-tab" "treestyletab@piro.sakura.ne.jp")
    (extension "sidebery" "{3c078156-979c-498b-8990-85f7987dd929}") # opensource :)

    (extension "ublock-origin" "uBlock0@raymondhill.net")
    # (extension "umatrix" "uMatrix@raymondhill.net")
    (extension "foxytab" "foxytab@eros.man")
    (extension "new-tab-override" "newtaboverride@agenedia.com")
    # (extension "" "simple-youtube-age-restriction-bypass@zerody.one")
    (extension "auto-tab-discard" "{c2c003ee-bd69-42a2-b0e9-6f34222cb046}")
    (extension "darkreader" "addon@darkreader.org")
    # (extension "greasemonkey" "{e4a8a97b-f2ed-450b-b12d-ee082ba24781}")
    # (extension "vimium-ff" "{d7742d87-e61d-4b78-b8a1-b469842139fa}")
    (extension "popup-blocker" "{de22fd49-c9ab-4359-b722-b3febdc3a0b0}")
    (extension "i-dont-care-about-cookies" "jid1-KKzOGWgsW3Ao4Q@jetpack")
  ];
in {
  # - [Declare Firefox extensions and settings](https://discourse.nixos.org/t/declare-firefox-extensions-and-settings/36265/7)
  # - [nixpkgs/nixos/modules/programs/firefox.nix](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/programs/firefox.nix)
  programs.firefox = {
    enable = true;

    # about:config
    preferences = {
      "media.hardware-video-decoding.force-enabled" = true;
    };

    # - [Mozilla's documentation](https://mozilla.github.io/policy-templates/)
    policies = {
      DontCheckDefaultBrowser = true;
      DisplayBookmarksToolbar = "newtab";
      ExtensionSettings = extensions;
      Preferences = {
        "browser.contentblocking.category" = {
          Value = "strict";
          Status = "locked";
        };
        "browser.aboutConfig.showWarning" = false;
      };
    };
  };
  # - [home-manager/modules/programs/firefox.nix](https://github.com/nix-community/home-manager/blob/master/modules/programs/firefox.nix)
  home-manager.users."${username}" = {...}: {
    programs.firefox = {
      enable = true;
      profiles = {
        test = {
          # path = name;
          id = 0; # 0 is default
          settings = {
            "browser.startup.homepage" = "https://nixos.org";
            "browser.newtabpage.pinned" = [
              {
                title = "NixOS";
                url = "https://nixos.org";
              }
            ];
          };
          # - [nur-combined/repos/rycee/pkgs/firefox-addons/addons.json](https://github.com/nix-community/nur-combined/blob/cac5a762ec7c40a8489e8ba4efa4820ad4b23575/repos/rycee/pkgs/firefox-addons/addons.json)
          # extensions = [];
        };
      };
    };
  };
}
