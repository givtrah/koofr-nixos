{
  description = "Koofr Desktop Client Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system} = {
        koofr-desktop = pkgs.stdenv.mkDerivation rec {
          pname = "koofr-desktop";
          version = "41a82e7";

          src = pkgs.fetchurl {
            url = "https://app.koofr.net/dl/apps/linux64";
            hash = "sha256-+jSnTjHzttFF8wDlR90Nkrxik2NOsKi18kQkQKIWuxo=";
          };

          sourceRoot = "koofr";

          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
            makeWrapper
            copyDesktopItems
          ];

          # Updated 'xorg.libX11' to the modern top-level 'libx11'
          buildInputs = with pkgs; [
            gtk3
            glib
            libx11
          ];

          # Cleaned up 'categories' to strictly follow XDG standards
          desktopItems = [
            (pkgs.makeDesktopItem {
              name = "koofr";
              exec = "koofr-desktop";
              icon = "koofr";
              comment = "Access your Koofr hybrid cloud storage";
              desktopName = "Koofr";
              genericName = "Hybrid storage cloud";
              categories = [ "Network" "FileTransfer" ];
            })
          ];

          installPhase = ''
            runHook preInstall

            mkdir -p $out/share/koofr
            mkdir -p $out/bin
            mkdir -p $out/share/icons/hicolor/256x256/apps

            cp -r * $out/share/koofr/
            cp icon.png $out/share/icons/hicolor/256x256/apps/koofr.png

            makeWrapper $out/share/koofr/storagegui $out/bin/koofr-desktop
            makeWrapper $out/share/koofr/storagecmd $out/bin/koofr-cmd

            runHook postInstall
          '';
        };

        default = self.packages.${system}.koofr-desktop;
      };
    };
}
