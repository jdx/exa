#!/bin/bash -e

REPO_URL="https://github.com/jdx/exa"
NAME="exa"
DESTDIR=/usr/bin
DOCDIR=/usr/share/man/

COMMIT=$(git rev-parse --abbrev-ref HEAD)

TAG=$(git describe --tags "$(git rev-list --tags --max-count=1)")
if [ -n "$1" ]; then
    TAG=$1
fi

VERSION=${TAG:1}

echo "checkout tag ${TAG}"
git checkout --quiet "${TAG}"

echo "build man pages"
just man

declare -A TARGETS
TARGETS["amd64"]="x86_64-unknown-linux-gnu"

for ARCH in "${!TARGETS[@]}"; do
    echo "building ${ARCH} package:"

    DEB_TMP_DIR="${NAME}_${VERSION}_${ARCH}"
    DEB_PACKAGE="${NAME}_${VERSION}_${ARCH}.deb"

    TARGET=${TARGETS[$ARCH]}
    ARCHIVE="${NAME}-${TAG}-${TARGET}.tar.gz"
    echo " -> downloading ${TARGET} archive"
    wget -q "${REPO_URL}/releases/download/${TAG}/${ARCHIVE}"
    wget -q "${REPO_URL}/releases/download/${TAG}/${ARCHIVE}.sha256"

    echo " -> verifying ${TARGET} archive"
    sha256sum --check "${ARCHIVE}.sha256"
    echo "    checksum ok"

    echo " -> creating directory structure"
    mkdir -p "${DEB_TMP_DIR}"
    mkdir -p "${DEB_TMP_DIR}${DESTDIR}"
    mkdir -p "${DEB_TMP_DIR}${DOCDIR}"
    mkdir -p "${DEB_TMP_DIR}${DOCDIR}/man1"
    mkdir -p "${DEB_TMP_DIR}${DOCDIR}/man5"
    mkdir -p "${DEB_TMP_DIR}/DEBIAN"
    mkdir -p "${DEB_TMP_DIR}/usr/share/doc/${NAME}"
    mkdir -p "${DEB_TMP_DIR}/usr/share/bash-completion/completions/"
    mkdir -p "${DEB_TMP_DIR}/usr/share/fish/vendor_completions.d/"
    mkdir -p "${DEB_TMP_DIR}/usr/share/zsh/vendor-completions/"
    chmod 755 -R "${DEB_TMP_DIR}"

    echo " -> extract executable"
    tar -xzf "${ARCHIVE}" --strip-components=1 "${NAME}-${TAG}-${TARGET}/${NAME}"
    cp "${NAME}" "${DEB_TMP_DIR}${DESTDIR}"
    chmod 755 "${DEB_TMP_DIR}${DESTDIR}/${NAME}"

    echo " -> compress man pages"
    gzip -cn9 target/man/exa.1 > "${DEB_TMP_DIR}${DOCDIR}man1/exa.1.gz"
    gzip -cn9 target/man/exa_colors.5 > "${DEB_TMP_DIR}${DOCDIR}man5/exa_colors.5.gz"
    gzip -cn9 target/man/exa_colors-explanation.5 > "${DEB_TMP_DIR}${DOCDIR}man5/exa_colors-explanation.5.gz"
    chmod 644 "${DEB_TMP_DIR}${DOCDIR}"/**/*.gz

    echo " -> copy completions"
    cp completions/bash/exa "${DEB_TMP_DIR}/usr/share/bash-completion/completions/"
    cp completions/fish/exa.fish "${DEB_TMP_DIR}/usr/share/fish/vendor_completions.d/"
    cp completions/zsh/_exa "${DEB_TMP_DIR}/usr/share/zsh/vendor-completions/"

    echo " -> create control file"
    touch "${DEB_TMP_DIR}/DEBIAN/control"
    cat > "${DEB_TMP_DIR}/DEBIAN/control" <<EOM
Package: ${NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Depends: libc6
Maintainer: jdx <jdx@users.noreply.github.com>
Description: Modern replacement for ls
 exa is a modern replacement for ls.  It uses colours for information by
 default, helping you distinguish between many types of files, such as whether
 you are the owner, or in the owning group.
 .
 It also has extra features not present in the original ls, such as viewing the
 Git status for a directory, or recursing into directories with a tree view.
EOM
    chmod 644 "${DEB_TMP_DIR}/DEBIAN/control"

    echo " -> copy changelog"
    cp CHANGELOG.md "${DEB_TMP_DIR}/usr/share/doc/${NAME}/changelog"
    gzip -cn9 "${DEB_TMP_DIR}/usr/share/doc/${NAME}/changelog" > "${DEB_TMP_DIR}/usr/share/doc/${NAME}/changelog.gz"
    rm "${DEB_TMP_DIR}/usr/share/doc/${NAME}/changelog"
    chmod 644 "${DEB_TMP_DIR}/usr/share/doc/${NAME}/changelog.gz"

    echo " -> create copyright file"
    touch "${DEB_TMP_DIR}/usr/share/doc/${NAME}/copyright"
    cat > "${DEB_TMP_DIR}/usr/share/doc/${NAME}/copyright" << EOM
Format: http://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: ${NAME}
Upstream-Contact: jdx <jdx@users.noreply.github.com>
Source: https://github.com/jdx/exa/releases

Files: *
License: MIT
Copyright: 2014 Benjamin Sago

Files: debian/*
License: MIT
Copyright: 2026 jdx

License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
EOM
    chmod 644 "${DEB_TMP_DIR}/usr/share/doc/${NAME}/copyright"

    echo " -> build ${ARCH} package"
    dpkg-deb --build --root-owner-group "${DEB_TMP_DIR}" > /dev/null

    echo " -> cleanup"
    rm -rf "${DEB_TMP_DIR}" "${ARCHIVE}" "${ARCHIVE}.sha256" "${NAME}"

    # This does not work on every architecture, and
    #          i'm verifying on the repo host anyway thus the || true
    echo " -> lint ${ARCH} package"
    lintian "${DEB_PACKAGE}" || true
done

echo "return to original commit"
git checkout --quiet "${COMMIT}"
