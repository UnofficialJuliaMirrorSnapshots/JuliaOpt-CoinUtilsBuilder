# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CoinUtilsBuilder"
version = v"2.10.14"

# Collection of sources required to build CoinUtilsBuilder
sources = [
    "https://github.com/coin-or/CoinUtils/archive/releases/2.10.14.tar.gz" =>
    "929b6eae0aaf62cf4467e506f24dfab1df7ab8d2e5a1ea71e9bab5480e872d84",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd CoinUtils-releases-2.10.14/
update_configure_scripts
# temporary fix
for path in ${LD_LIBRARY_PATH//:/ }; do
    for file in $(ls $path/*.la); do
        echo "$file"
        baddir=$(sed -n "s|libdir=||p" $file)
        sed -i~ -e "s|$baddir|'$path'|g" $file
    done
done
mkdir build
cd build/
## STATIC BUILD START
if [ $target = "x86_64-apple-darwin14" ]; then
  export AR=/opt/x86_64-apple-darwin14/bin/x86_64-apple-darwin14-ar
fi
../configure --prefix=$prefix --with-pic --disable-pkg-config  --host=${target} --disable-shared --enable-static --enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
--with-blas-lib="-L${prefix}/lib -lcoinblas" \
--with-lapack-lib="-L${prefix}/lib -lcoinlapack"
## STATIC BUILD END
## DYNAMIC BUILD START
#../configure --prefix=$prefix --with-pic --disable-pkg-config  --host=${target} --enable-shared --disable-static --enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
#--with-blas="-L${prefix}/lib -lcoinblas" \
#--with-lapack="-L${prefix}/lib -lcoinlapack"
## DYNAMIC BUILD END



make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]
platforms = expand_gcc_versions(platforms)
# To fix gcc4 bug in Windows
push!(platforms, Windows(:i686,compiler_abi=CompilerABI(:gcc6)))
push!(platforms, Windows(:x86_64,compiler_abi=CompilerABI(:gcc6)))

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libCoinUtils", :libCoinUtils)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/juan-pablo-vielma/COINLapackBuilder/releases/download/v1.5.6-1-static/build_COINLapackBuilder.v1.5.6.jl",
    "https://github.com/juan-pablo-vielma/COINBLASBuilder/releases/download/v1.4.6-1-static/build_COINBLASBuilder.v1.4.6.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
