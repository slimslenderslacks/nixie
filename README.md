## Building with [clj-nix][clj-nix]

Nix deriviations should run without network access and should be reproducible. We need to lock the deps.edn file so that clj-nix can generate derivations to pull dependencies into the nix store.

```
nix run github:jlesquembre/clj-nix#deps-lock
```

A few deriviations are available.

```
# output is a compiled uber jar
nix build .#clj
# output is a graal binary compiled from the output of the previous derivation
nix build .#graal
```

[clj-nix]: https://github.com/jlesquembre/clj-nix


