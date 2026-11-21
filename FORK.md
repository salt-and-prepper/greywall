# salt-and-prepper/greywall

A fork of [GreyhavenHQ/greywall](https://github.com/GreyhavenHQ/greywall)
that keeps greywall's dependencies, and the tun2socks binary it embeds,
current. Releases come from the `release/<minor>` branches (`release/0.3`
starts at upstream's v0.3.7); `main` tracks upstream.

What differs from upstream v0.3.7:

- **Dependencies:** Go toolchain and `golang.org/x/sys` updated. No
  functional changes.
- **tun2socks:** upstream downloads tun2socks v2.5.2 release binaries
  (2023, no checksum) at build time and embeds them. This fork builds
  tun2socks v2.7.0 from source at a pinned commit with current
  `golang.org/x` modules ([`scripts/build-tun2socks.sh`](scripts/build-tun2socks.sh));
  `make download-tun2socks` runs it. The embedded binaries are invisible to
  vulnerability scanners, so each release also attaches them separately.
  tun2socks v2.6+ parses flags with pflag, so the sandbox starts it with
  `--device`/`--proxy` (the single-dash forms upstream uses are read as
  `-d evice`/`-p roxy`); fixed in `v0.3.7-ellwood.2`.
- **Releases:** tags `v<upstream version>-ellwood.<n>` build static
  `linux/amd64` and `linux/arm64` archives with
  [`.github/workflows/release.yml`](.github/workflows/release.yml), after the
  Linux test suite. Archives keep upstream's names and layout, are not
  UPX-packed, and carry build provenance attestations:

  ```sh
  gh attestation verify greywall_<version>_Linux_x86_64.tar.gz --repo salt-and-prepper/greywall
  ```
- **Workflows:** upstream's goreleaser (UPX, Homebrew) and docs-notification
  workflows are removed; `main.yml` also runs for `release/**`.

Consumer: the coder-templates `greywall` module.
