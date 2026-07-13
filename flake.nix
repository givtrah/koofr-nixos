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
      packages.${system}.koofr-desktop = pkgs.stdenv.mkDerivation rec {
        pname = "koofr-desktop";
        version = "41a82e7"; # Taken from your tarball filename

        src = pkgs.fetchurl {
          url = "https://app.koofr.net/dl/apps/linux64";
          # Replace this with the output of: nix store prefetch-file https://app.koofr.net/dl/apps/linux64
          hash = "sha256-+jSnTjHzttFF8wDlR90Nkrxik2NOsKi18kQkQKIWuxo=";  # Updated 2026-07-13
        };

        # Tells Nix to look inside the extracted 'koofr' directory
        sourceRoot = "koofr";

        nativeBuildInputs = with pkgs; [
          autoPatchelfHook
          makeWrapper
          copyDesktopItems
        ];

        # Dynamic libraries required by the Koofr binaries
        buildInputs = with pkgs; [
          gtk3
          glib
          xorg.libX11
        ];

        # Declaratively builds the .desktop entry for your application menu
        desktopItems = [
          (pkgs.makeDesktopItem {
            name = "koofr";
            exec = "koofr-desktop";
            icon = "koofr";
            comment = "Hybrid storage cloud";
            desktopName = "Koofr";
            genericName = "Hybrid storage cloud";
            categories = [ "Network" "FileTransfer" "Internet" ];
          })
        ];

        installPhase = ''
          runHook preInstall

          # 1. Create the necessary directory structures inside the Nix store
          mkdir -p $out/share/koofr
          mkdir -p $out/bin
          mkdir -p $out/share/icons/hicolor/256x256/apps

          # 2. Copy all extracted contents to the share directory
          cp -r * $out/share/koofr/

          # 3. Install the app icon to the standard Linux path
          cp icon.png $out/share/icons/hicolor/256x256/apps/koofr.png

          # 4. Wrap the main GUI and CLI binaries to expose them to your system PATH
          makeWrapper $out/share/koofr/storagegui $out/bin/koofr-desktop
          makeWrapper $out/share/koofr/storagecmd $out/bin/koofr-cmd

          runHook postInstall
        '';
      };

      packages.${system}.default = self.packages.${system}.koofr-desktop;
    };
}
