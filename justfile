all: build test
all-release: build-release test-release
genDemo:
    fish_prompt="> " fish_history="exa_history" vhs < docs/tapes/demo.tape
    nsxiv -a docs/images/demo.gif

#----------#
# building #
#----------#

# compile the exa binary
@build:
    cargo build

# compile the exa binary (in release mode)
@build-release:
    cargo build --release --verbose

# produce an HTML chart of compilation timings
@build-time:
    cargo +nightly clean
    cargo +nightly build -Z timings

# check that the exa binary can compile
@check:
    cargo check


#---------------#
# running tests #
#---------------#

# run unit tests
@test:
    cargo test --workspace -- --quiet

# run unit tests (in release mode)
@test-release:
    cargo test --workspace --release --verbose

#-----------------------#
# code quality and misc #
#-----------------------#

# lint the code
@clippy:
    touch src/main.rs
    cargo clippy

# update dependency versions, and checks for outdated ones
@update-deps:
    cargo update
    command -v cargo-outdated >/dev/null || (echo "cargo-outdated not installed" && exit 1)
    cargo outdated

# list unused dependencies
@unused-deps:
    command -v cargo-udeps >/dev/null || (echo "cargo-udeps not installed" && exit 1)
    cargo +nightly udeps

# check that every combination of feature flags is successful
@check-features:
    command -v cargo-hack >/dev/null || (echo "cargo-hack not installed" && exit 1)
    cargo hack check --feature-powerset

# print versions of the necessary build tools
@versions:
    rustc --version
    cargo --version


#---------------#
# documentation #
#---------------#

# build the man pages
@man:
    mkdir -p "${CARGO_TARGET_DIR:-target}/man"
    version=$(awk 'BEGIN { FS = "\"" } ; /^version/ { print $2 ; exit }' Cargo.toml); \
    for page in exa.1 exa_colors.5 exa_colors-explanation.5; do \
        sed "s/\$version/v${version}/g" "man/${page}.md" | pandoc --standalone -f markdown -t man > "${CARGO_TARGET_DIR:-target}/man/${page}"; \
    done;

# build and preview the main man page (exa.1)
@man-1-preview: man
    man "${CARGO_TARGET_DIR:-target}/man/exa.1"

# build and preview the colour configuration man page (exa_colors.5)
@man-5-preview: man
    man "${CARGO_TARGET_DIR:-target}/man/exa_colors.5"

# build and preview the colour configuration man page (exa_colors.5)
@man-5-explanations-preview: man
    man "${CARGO_TARGET_DIR:-target}/man/exa_colors-explanation.5"

#----------------#
#    binaries    #
#----------------#

tar BINARY TARGET:
    tar czvf ./target/"bin-$(convco version)"/{{BINARY}}_{{TARGET}}.tar.gz -C ./target/{{TARGET}}/release/ ./{{BINARY}}

zip BINARY TARGET:
    zip -j ./target/"bin-$(convco version)"/{{BINARY}}_{{TARGET}}.zip ./target/{{TARGET}}/release/{{BINARY}}

tar_static BINARY TARGET:
    tar czvf ./target/"bin-$(convco version)"/{{BINARY}}_{{TARGET}}_static.tar.gz -C ./target/{{TARGET}}/release/ ./{{BINARY}}

zip_static BINARY TARGET:
    zip -j ./target/"bin-$(convco version)"/{{BINARY}}_{{TARGET}}_static.zip ./target/{{TARGET}}/release/{{BINARY}}

binary BINARY TARGET:
    rustup target add {{TARGET}}
    cross build --release --target {{TARGET}}
    just tar {{BINARY}} {{TARGET}}
    just zip {{BINARY}} {{TARGET}}

binary_static BINARY TARGET:
    rustup target add {{TARGET}}
    RUSTFLAGS='-C target-feature=+crt-static' cross build --release --target {{TARGET}}
    just tar_static {{BINARY}} {{TARGET}}
    just zip_static {{BINARY}} {{TARGET}}

binary_no_libgit BINARY TARGET:
    rustup target add {{TARGET}}
    cross build --no-default-features --release --target {{TARGET}}
    just tar {{BINARY}} {{TARGET}}
    just zip {{BINARY}} {{TARGET}}

binary_static_no_libgit BINARY TARGET:
    rustup target add {{TARGET}}
    RUSTFLAGS='-C target-feature=+crt-static' cross build --no-default-features --release --target {{TARGET}}
    just tar_static {{BINARY}} {{TARGET}}
    just zip_static {{BINARY}} {{TARGET}}

checksum:
    @echo "# Checksums"
    @echo "## sha256sum"
    @echo '```'
    @sha256sum ./target/"bin-$(convco version)"/*
    @echo '```'
    @echo "## md5sum"
    @echo '```'
    @md5sum ./target/"bin-$(convco version)"/*
    @echo '```'
    @echo "## blake3sum"
    @echo '```'
    @b3sum ./target/"bin-$(convco version)"/*
    @echo '```'

alias c := cross

# Generate release binaries for EXA
#
# usage: cross
@cross:
    # Setup Output Directory
    mkdir -p ./target/"bin-$(convco version)"

    # Install Toolchains/Targets
    rustup toolchain install stable

    ## Linux
    ### x86
    just binary exa x86_64-unknown-linux-gnu
    # just binary_static exa x86_64-unknown-linux-gnu
    just binary exa x86_64-unknown-linux-musl
    # just binary_static exa x86_64-unknown-linux-musl

    ### aarch
    just binary_no_libgit exa aarch64-unknown-linux-gnu
    # BUG: just binary_static exa aarch64-unknown-linux-gnu

    ### arm
    just binary_no_libgit exa arm-unknown-linux-gnueabihf
    # just binary_static exa arm-unknown-linux-gnueabihf

    ## MacOS
    # TODO: just binary exa x86_64-apple-darwin

    ## Windows
    ### x86
    just binary exa.exe x86_64-pc-windows-gnu
    # just binary_static exa.exe x86_64-pc-windows-gnu
    # TODO: just binary exa.exe x86_64-pc-windows-gnullvm
    # TODO: just binary exa.exe x86_64-pc-windows-msvc

    # Generate Checksums
    # TODO: moved to gh-release just checksum

@mangen:
    # Setup Output Directory
    mkdir -p ./target/"man-$(convco version)"
    pandoc --standalone -f markdown -t man man/exa.1.md > ./target/"man-$(convco version)"/exa.1
    pandoc --standalone -f markdown -t man man/exa_colors.5.md > ./target/"man-$(convco version)"/exa_colors.5
    pandoc --standalone -f markdown -t man man/exa_colors-explanation.5.md > ./target/"man-$(convco version)"/exa_colors-explanation.5
    tar czvf ./target/"man-$(convco version)".tar.gz ./target/"man-$(convco version)"

@completions:
    # Setup Output Directory
    mkdir -p ./target/"completions-$(convco version)"
    cp completions/*/* ./target/"completions-$(convco version)"/
    tar czvf ./target/"completions-$(convco version)".tar.gz ./target/"completions-$(convco version)"
