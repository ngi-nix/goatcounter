{
  description = "Simple web analytics. No tracking of personal data.";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-20.03";

  # Upstream source tree(s).
  inputs.goatcounter-src = { url = "git+https://github.com/zgoat/goatcounter"; flake = false; };

  outputs = { self, nixpkgs, goatcounter-src }:
    let

      # Generate a user-friendly version numer.
      version = builtins.substring 0 8 goatcounter-src.lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in

    {

      # A Nixpkgs overlay.
      overlay = final: prev: {

        goatcounter = with final; buildGo113Package rec {
          name = "goatcounter-${version}";

          src = goatcounter-src;

          goPackagePath = "zgo.at/goatcounter";
          goDeps = ./deps.nix;

          meta = {
            homepage = "https://www.goatcounter.com/";
            description = "Simple web analytics. No tracking of personal data.";
          };
        };

      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        {
          inherit (nixpkgsFor.${system}) goatcounter;
        });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.goatcounter);

      # A NixOS module, if applicable (e.g. if the package provides a system service).
      nixosModules.goatcounter =
        { pkgs, ... }:
        {
          nixpkgs.overlays = [ self.overlay ];

          environment.systemPackages = [ pkgs.goatcounter ];
        };

      # Tests run by 'nix flake check' and by Hydra.
      checks = forAllSystems (system: {
        inherit (self.packages.${system}) goatcounter;

      });

    };
}
