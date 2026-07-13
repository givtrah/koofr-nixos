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
            name = "koofr.tar.gz";
            url = "https://app.koofr.net/dl/apps/linux64";
            hash = "sha256-+jSnTjHzttFF8wDlR90Nkrxik2NOsKi18kQkQKIWuxo=";
          };

          sourceRoot = "koofr";

          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
            makeWrapper
            copyDesktopItems
          ];

          buildInputs = with pkgs; [
            gtk3
            glib
            libx11
            nss
            nspr
            libudev0-shim
            sqlite
          ];

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

            # Copy all files so autoPatchelfHook catches all 4 binaries together
            cp -r * $out/share/koofr/
            cp icon.png $out/share/icons/hicolor/256x256/apps/koofr.png

            # Wrap all 4 original binaries into $out/bin under their exact native names
            # and prefix the PATH so they can effortlessly locate each other.
            for bin in storagegui storagecmd storagedevice storagesync; do
              makeWrapper $out/share/koofr/$bin $out/bin/$bin \
                --chdir $out/share/koofr \
                --prefix PATH : $out/bin
            done

            # Provide the convenient binary alias expected by the desktop shortcut
            ln -s $out/bin/storagegui $out/bin/koofr-desktop

            runHook postInstall
          '';
        };

        default = self.packages.${system}.koofr-desktop;
      };
    };
}
