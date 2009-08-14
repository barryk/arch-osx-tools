#!/bin/sh

PACKAGEMAKER=/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker
INSTALL_ROOT=~/archroot
PACMAN_CACHE=~/arch-osx.cache/pkg
VERSION=`date +%Y%m%d`

DEPS=(
    bzip2
    zlib
    xz-utils
    expat
    gmp
    libiconv
    openssl
    libarchive
    libfetch
    gettext
    pacman-mirrorlist
)

NONDEPS=(
    pacman
    coreutils
    fakeroot
)

# Setup install root for chroot usage
setup_root() {
    root_path=$1

    mkdir -p "$root_path"{/usr/lib/system,/opt/arch/bin,/bin,/private/etc/paths.d} || exit 1
    mkdir -p "$root_path"/opt/arch/var/lib/pacman/local || exit 1
    cp /usr/lib/{dyld,libSystem.B.dylib,libgcc_s.1.dylib} "$root_path"/usr/lib/ || exit 1
    cp /usr/lib/system/libmathCommon.A.dylib "$root_path"/usr/lib/system/ || exit 1
    cp /opt/arch/bin/bash.minimal "$root_path"/bin/sh || exit 1
    
    echo "/opt/arch/bin" > "$root_path/private/etc/paths.d/arch-osx"
}

cleanup_chroot() {
    chroot_path=$1

    rm "$chroot_path"/usr/lib/{dyld,libSystem.B.dylib,libgcc_s.1.dylib} || exit 1
    rm "$chroot_path"/usr/lib/system/libmathCommon.A.dylib || exit  1
    rm "$chroot_path"/bin/sh || exit 1

    rmdir "$chroot_path"{/bin,/tmp}
    rmdir "$chroot_path"/usr/lib/system
    rmdir "$chroot_path"/usr/lib
    rmdir "$chroot_path"/usr
}



install_package() {
    name=$1
    flag=$2
    file=`find ${PACMAN_CACHE} -name "${name}-[0-9]*" | sort -r | head -n 1`
    echo Installing package: ${name} File: ${file}
    pacman -U ${flag} --noprogressbar -r ${INSTALL_ROOT} -b ${INSTALL_ROOT}/opt/arch/var/lib/pacman ${file} || exit 1
}

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root for chroot privledges to pacman" 1>&2
    exit 1
fi


echo Building ArchOSX Installer ${VERSION}

echo Making install root and chroot environment...
setup_root $INSTALL_ROOT

echo Installing dependencies...
for package in ${DEPS[@]}; do
    install_package ${package} --asdeps
done

echo Installing non-dependencies...
for package in ${NONDEPS[@]}; do
    install_package ${package}
done

echo Cleaning chroot from install root...
cleanup_chroot $INSTALL_ROOT

echo Creating package...
${PACKAGEMAKER} -r ${INSTALL_ROOT} -o ArchOSX-${VERSION}.pkg -i net.twilightlair.arch -n ${VERSION} -t ArchOSX -g 10.5 -h system -b || exit 1

echo Done!
