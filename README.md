# rtsan-libs-cmake

## Introduction

`rtsan-libs-cmake` is a CMake helper for easy inclusion of RTSan in your CMake project. For background information, see https://github.com/realtime-sanitizer/rtsan/issues/47.

`rtsan-libs-cmake` makes use of the precompiled standalone RTSan libraries at https://github.com/realtime-sanitizer/rtsan-libs/releases/tag/v20.1.1.2, in combination with the header at https://github.com/realtime-sanitizer/rtsan/raw/e2dab730337e736f12c0bb2c9b37d3e15aa335ec/include/rtsan_standalone/rtsan_standalone.h.

To my knowledge, `rtsan_standalone.h` is currently not subject to any versioning scheme. Hence this helper uses hash-pinning for grabbing the right header file, in combination with tag-pinning for grabbing the right the binary assets.

## Requirements

* Linux or macOS.

## Usage

Example `CMakeLists.txt`:

```cmake
cmake_minimum_required(VERSION 3.22)
project(hello)
include(FetchContent)
FetchContent_Declare(
  rtsan
  GIT_REPOSITORY https://github.com/izzyreal/rtsan-libs-cmake.git
  GIT_TAG main
)
FetchContent_MakeAvailable(rtsan)
add_executable (hello main.cpp)
rtsan_libs_enable(TARGET hello)
```

In a typical JUCE project, use the name of your shared library in the `rtsan_libs_enable` invocation. So if your JUCE project has targets `crazySynth`, `crazySynth_VST3` and `crazySynth_Standalone`, you do:

```
rtsan_libs_enable(TARGET crazySynth) # Correct
```

and not

```
rtsan_libs_enable(TARGET crazySynth_VST3) # Wrong
```

For the C++ side of things, here's a `main.cpp` example:

```cpp
#include <rtsan_standalone/rtsan_standalone.h>

int main() {
    __rtsan::Initialize();
    ...
}

void my_real_time_function() {
    __rtsan::ScopedSanitizeRealtime ssr;
    ...
}
```

In a typical JUCE plugin, you can invoke `__rtsan::Initialize();` in the `AudioProcessor`'s constructor, and put `__rtsan::ScopedSanitizeRealtime ssr;` at the top of your `processBlock` implementation.

Also see https://github.com/realtime-sanitizer/rtsan?tab=readme-ov-file#using-rtsan-standalone-with-compilers-other-than-clang-20.

If you've been reading about RTSan and you're wondering where the `[[clang::nonblocking]]` attribute is; the `[[...]]` attributes are **not** used by https://github.com/realtime-sanitizer/rtsan-libs. See https://github.com/realtime-sanitizer/rtsan?tab=readme-ov-file#using-rtsan-standalone-with-compilers-other-than-clang-20 for more info.

## Plugin without standalone wrapper on macOS

On macOS, you can RTSan your VST3 (and presumably LV2 and Audio Unit) plugins directly in a host. You will need to start the host like this:

```
DYLD_INSERT_LIBRARIES=/absolute/path/to/libclang_rt.rtsan_osx_dynamic.dylib /Applications/REAPER.app/Contents/MacOS/REAPER 
```

Of course replace the first path to the actual location of the `.dylib` that is reeled in by `rtsan-libs-cmake`. In a typical CMake setup, it will be in `<your_repo_root>/build/_rtsan/libclang_rt.rtsan_osx_dynamic.dylib`.

## Open issues

* On Linux, debugging a plugin directly (without any kind of standalone executable wrapping) in a host.
* Parameterize enablement. Currently, RTSan is enabled whenever you do `rtsan_libs_enable(TARGET crazySynth)`. It would be nice to have a flag that can be passed to the CMake generation invocation that would enable or disable `rtsan_libs` inclusion. But this requires a bit more thought about how to keep the code compilable. Some preprocessor guards would probably work, like

  ```
  #if RTSAN_LIBS_ENABLED
  #include <rtsan_standalone/rtsan_standalone.h>
  #endif
  
  int main() {
  #if RTSAN_LIBS_ENABLED
      __rtsan::Initialize();
  #endif
      ...
  }
  
  void my_real_time_function() {
  #if RTSAN_LIBS_ENABLED
      __rtsan::ScopedSanitizeRealtime ssr;
  #endif
      ...
  }
  ```

  And disabling linking based on a CMake flag should be trivial.
