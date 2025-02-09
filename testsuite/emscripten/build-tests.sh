#!/usr/bin/env bash

if ! [ -x "$(command -v emcc)" ]; then
  echo "Error: emcc could not be found." >&2
  exit 1
fi

set -e

cd "$1"
shift

# Define default arguments

# JS BigInt to Wasm i64 integration, enabled by default
# https://github.com/WebAssembly/JS-BigInt-integration
WASM_BIGINT=true

# Parse arguments
while [ $# -gt 0 ]; do
  case $1 in
    --disable-wasm-bigint) WASM_BIGINT=false ;;
    *) echo "ERROR: Unknown parameter: $1" >&2; exit 1 ;;
  esac
  shift
done

export CFLAGS="-fPIC -O2 -I../../target/include $EXTRA_CFLAGS"
export CXXFLAGS="$CFLAGS -sNO_DISABLE_EXCEPTION_CATCHING $EXTRA_CXXFLAGS"
export LDFLAGS=" \
    -L../../target/lib/ -lffi \
    -sEXPORT_ALL \
    -sMODULARIZE \
    -sMAIN_MODULE \
    -sNO_DISABLE_EXCEPTION_CATCHING \
    $EXTRA_LD_FLAGS \
"
if [ "$WASM_BIGINT" = "true" ]; then export LDFLAGS+=" -sWASM_BIGINT"; fi

# Rename main functions to test__filename so we can link them together
ls *c | sed 's!\(.*\)\.c!sed -i "s/main/test__\1/g" \0!g' | bash

# Compile
ls *.c | sed 's/\(.*\)\.c/emcc $CFLAGS -c \1.c -o \1.o /g' | bash
ls *.cc | sed 's/\(.*\)\.cc/em++ $CXXFLAGS -c \1.cc -o \1.o /g' | bash

# Link
em++ $LDFLAGS *.o -o test.js
cp ../emscripten/test.html .
