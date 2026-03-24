# gametracer_jll_build_test

This repository tests a fix for the Windows DLL-load failure in `gametracer_jll`.

## The error

On Windows, calling `using GameTracer` (or `Libdl.dlopen` on `libgametracer.dll`) fails with an error like:

```
ERROR: InitError: could not load library "libgametracer"
The specified module could not be found.
```

### Root cause

`libgametracer.dll` is built from C++ sources
([`QuantEcon/gametracer` c_api](https://github.com/QuantEcon/gametracer/tree/main/c_api))
using the MinGW cross-compiler toolchain that BinaryBuilder uses for
`x86_64-w64-mingw32` targets.  By default the resulting DLL is dynamically
linked against the GCC C++ runtime (`libstdc++-6.dll`).  That runtime DLL is
part of the MSYS2/MinGW toolchain and is **not** bundled with Julia or with
the `gametracer_jll` artifact, so Windows cannot find it at load time.

### Fix

Rebuild the Windows DLL with the linker flag `-static-libstdc++` so that the
C++ runtime is statically linked into `libgametracer.dll` itself, making the
artifact self-contained:

```julia
# builder/build_tarballs.jl  (relevant excerpt)
if [[ "${target}" == *-mingw* ]]; then
    extra_cmake_flags+=(-DCMAKE_SHARED_LINKER_FLAGS=-static-libstdc++)
fi
```

## What this repo does

`builder/build_tarballs.jl` rebuilds `libgametracer.dll` for
`x86_64-w64-mingw32` with the fix applied.  The
`windows-jll-smoke-test` workflow:

1. Builds the patched tarball on an Ubuntu runner (using Docker via BinaryBuilder).
2. Uploads the tarball as a GitHub Actions artifact.
3. Downloads it on a Windows runner, installs it via an `Overrides.toml`
   override, and runs `using GameTracer` and the package test-suite to confirm
   that the DLL loads correctly.
