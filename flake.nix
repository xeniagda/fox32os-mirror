{
  description = "fox32os";

  inputs = {
    fox32asm.url = "git+https://githug.xyz/xenia/fox32asm";
    fox32rom.url = "git+https://githug.xyz/xenia/fox32rom";
    foxtools.url = "git+https://githug.xyz/xenia/fox-tools";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, fox32asm, fox32rom, foxtools, flake-utils }:
    flake-utils.lib.eachDefaultSystem (sys:
      let pkgs = import nixpkgs { system = sys; };
          asm = fox32asm.packages.${sys}.fox32asm;
          gfx2inc = foxtools.packages.${sys}.gfx2inc;
          rom-dev = fox32rom.packages.${sys}.fox32rom-dev;

          deps = [ pkgs.lua5_4_compat pkgs.python311 ]; # lua needed for Okameron, python for ryfs.py

          okameron = pkgs.fetchFromGitHub {
            owner = "TalonFloof";
            repo = "okameron";
            rev = "c7499dff866bb6100cc4d5e688c39d1d853389f8";
            hash = "sha256-VQ/ABkiPMFZtA8XKLW2oQTihVkLmq5+gL8IVe5Kfv/I=";
          };

          ryfs = pkgs.stdenv.mkDerivation {
            name = "ryfs";
            src = pkgs.fetchFromGitHub {
              owner = "ry755";
              repo = "ryfs";
              rev = "e5034f4e11250a626388d7e9c1bcbf9af53f5702";
              hash = "sha256-wA89XLHhinxpiaKzGKKqLuRQ6Q4x4uw/NwGK8Hs2+MQ=";
            };
            dontBuild = true;
            nativeBuildInputs = [ pkgs.python311 ];
            # Not sure why we need to run patchShebangs manually, from what I can see in the docs it should patch all output scripts automatically -xenia
            installPhase = ''
              mkdir -p $out/bin
              cp ryfs.py $out/bin/ryfs.py
              chmod u+x $out/bin/ryfs.py
              patchShebangs --build $out/bin/ryfs.py
            '';
          };

          fox32os = pkgs.stdenv.mkDerivation {
            name = "fox32os";
            src = ./.;
            nativeBuildInputs = deps;

            preBuild = ''
              mkdir -p ./fox32rom
              cp ${rom-dev}/dev/fox32rom.def ./fox32rom/fox32rom.def
            '';

            FOX32ASM = "${asm}/bin/fox32asm";
            GFX2INC = "${gfx2inc}/bin/gfx2inc";
            OKAMERON = "${okameron}/okameron.lua";
            RYFS = "${ryfs}/bin/ryfs.py";

            installPhase = ''
              mkdir -p "$out/bin"
              cp fox32os.img romdisk.img "$out/bin"
            '';
            dontFixup = true;
          };

          fox32os-dev = pkgs.runCommand "fox32os-dev" {} ''
            mkdir -p $out/dev
            cp ${./fox32os.def} $out/dev/fox32os.def
          '';
      in rec {
        packages.fox32os = fox32os;
        packages.fox32os-dev = fox32os-dev;
        packages.ryfs = ryfs;
        packages.default = fox32os;

        devShells.default = pkgs.mkShell {
          packages = deps ++ [ asm gfx2inc okameron ] ;
          shellHook = ''
            export FOX32ASM="${asm}/bin/fox32asm";
            export GFX2INC="${gfx2inc}/bin/gfx2inc";
            export OKAMERON="${okameron}/okameron.lua";
            export RYFS="${ryfs}/bin/ryfs.py";

            mkdir -p ./fox32rom
            cp ${rom-dev}/dev/fox32rom.def ./fox32rom/fox32rom.def
        '';
        };
      }
    );
}
