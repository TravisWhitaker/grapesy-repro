with import <nixpkgs> {};
let hs = haskell.packages.ghc9103.ghcWithPackages
    (p: with p; [cabal-install haskell-language-server proto-lens-protoc snappy-c]);
    plugin = haskell.packages.ghc9103.proto-lens-protoc;
in mkShell
{
    packages = [ hs
                 protobuf
               ];
    shellHook = ''
        export PLUGIN=protoc-gen-haskell-protolens=${plugin}/bin/proto-lens-protoc
    '';
}
