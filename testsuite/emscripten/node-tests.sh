#!/bin/bash

# JS BigInt to Wasm i64 integration, enabled by default
# https://github.com/WebAssembly/JS-BigInt-integration
WASM_BIGINT=true

if ! [ -x "$(command -v emcc)" ]; then
  echo "Error: emcc could not be found." >&2
  exit 1
fi

# Parse arguments
while [ $# -gt 0 ]; do
  case $1 in
    --disable-wasm-bigint) WASM_BIGINT=false ;;
    *) echo "ERROR: Unknown parameter: $1" >&2; exit 1 ;;
  esac
  shift
done

# Common compiler flags
export CFLAGS="-fPIC $EXTRA_CFLAGS"
if [ "$WASM_BIGINT" = "true" ]; then export CFLAGS+=" -DWASM_BIGINT"; fi
export CXXFLAGS="$CFLAGS -sNO_DISABLE_EXCEPTION_CATCHING $EXTRA_CXXFLAGS"
export LDFLAGS="-sEXPORTED_FUNCTIONS=_main,_malloc,_free -sALLOW_TABLE_GROWTH -sASSERTIONS -sNO_DISABLE_EXCEPTION_CATCHING"
if [ "$WASM_BIGINT" = "true" ]; then export LDFLAGS+=" -sWASM_BIGINT"; fi

# Specific variables for cross-compilation
export CHOST="wasm32-unknown-linux" # wasm32-unknown-emscripten

autoreconf -fiv
emconfigure ./configure --prefix="$(pwd)/target" --host=$CHOST --enable-static --disable-shared \
  --disable-builddir --disable-multi-os-directory --disable-raw-api --disable-docs ||
  (cat config.log && exit 1)
make

EMMAKEN_JUST_CONFIGURE=1 emmake make check \
  RUNTESTFLAGS="LDFLAGS_FOR_TARGET='$LDFLAGS'" || (cat testsuite/libffi.log && exit 1)
