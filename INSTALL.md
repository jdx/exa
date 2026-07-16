# Installation

exa supports Linux, macOS, and Windows.

## Release binaries

Each [GitHub release](https://github.com/jdx/exa/releases/latest) includes the
MIT licence and binaries for:

- Linux x86-64: `x86_64-unknown-linux-gnu`
- macOS Intel: `x86_64-apple-darwin`
- macOS Apple Silicon: `aarch64-apple-darwin`
- Windows x86-64: `x86_64-pc-windows-msvc`

Download the archive for your platform, extract it, and place `exa` (or
`exa.exe`) somewhere on your `PATH`.

For example, on Apple Silicon macOS:

```sh
tag=$(curl -fsSL https://api.github.com/repos/jdx/exa/releases/latest | \
  sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p')
curl -fsSLO "https://github.com/jdx/exa/releases/download/${tag}/exa-${tag}-aarch64-apple-darwin.tar.gz"
tar -xzf "exa-${tag}-aarch64-apple-darwin.tar.gz"
sudo install -m 0755 "exa-${tag}-aarch64-apple-darwin/exa" /usr/local/bin/exa
```

Use `x86_64-apple-darwin` instead on an Intel Mac.

## Build from source

Install a stable Rust toolchain, then run:

```sh
git clone https://github.com/jdx/exa.git
cd exa
cargo build --release --locked
sudo install -m 0755 target/release/exa /usr/local/bin/exa
```

To build without Git integration and its native dependencies:

```sh
cargo build --release --locked --no-default-features
```

The package intentionally is not published to crates.io; releases are managed
from this repository using Git tags and GitHub Releases.
