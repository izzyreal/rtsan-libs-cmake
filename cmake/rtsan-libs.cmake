function(rtsan_libs_enable)
    cmake_parse_arguments(RTSAN "" "TARGET" "" ${ARGN})
    if(NOT RTSAN_TARGET)
        message(FATAL_ERROR "TARGET required")
    endif()

    if(APPLE)
        if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
            set(_asset "libclang_rt.rtsan_ios_dynamic.dylib")
            set(_sha "d0c04647d9d1b2e130f4f3a3b3cfbcc8787a54895f06c9aeca15040362c45ac2")
        else()
            set(_asset "libclang_rt.rtsan_osx_dynamic.dylib")
            set(_sha "495b5119ff112029df31d54d38188fc2fbd4a514e2885d90e4ca0bf3cf0dba29")
        endif()
        set(_type SHARED)
    elseif(UNIX)
        if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|ARM64")
            set(_asset "libclang_rt.rtsan_linux_aarch64.a")
            set(_sha "404eb138286f485d994d822d7a0b97e1d357848d0512a276561a1f4f1a51b253")
        else()
            set(_asset "libclang_rt.rtsan_x86_64.so")
            set(_sha "9912e4ff10c09d9224665a6247ea8a89f6bac66dde222f5064f0f8810526d273")
        endif()
        set(_type STATIC)
    else()
        message(FATAL_ERROR "Unsupported platform")
    endif()

    set(_hdr_asset "rtsan_standalone.h")
    set(_hdr_sha "271344759463c428522652a54e1beb6cf9cc6d35419d3c998cf25a14bf229b28")
    set(_hdr_url "https://github.com/realtime-sanitizer/rtsan/raw/e2dab730337e736f12c0bb2c9b37d3e15aa335ec/include/rtsan_standalone/rtsan_standalone.h")

    set(_lib_url "https://github.com/izzyreal/rtsan-libs/releases/tag/v20.1.1-dll-linux/${_asset}")

    set(_dir "${CMAKE_BINARY_DIR}/_rtsan")
    set(_lib "${_dir}/${_asset}")
    set(_inc "${_dir}/include")
    set(_hdr_dir "${_inc}/rtsan_standalone")
    set(_hdr "${_hdr_dir}/${_hdr_asset}")

    file(MAKE_DIRECTORY "${_dir}")
    file(MAKE_DIRECTORY "${_hdr_dir}")

    if(NOT EXISTS "${_lib}")
        file(DOWNLOAD
            "${_lib_url}"
            "${_lib}"
	    #EXPECTED_HASH SHA256=${_sha}
            STATUS _st
        )
        list(GET _st 0 _code)
        if(NOT _code EQUAL 0)
            message(FATAL_ERROR "RTSan library download failed")
        endif()
    endif()

    if(NOT EXISTS "${_hdr}")
        file(DOWNLOAD
            "${_hdr_url}"
            "${_hdr}"
            EXPECTED_HASH SHA256=${_hdr_sha}
            STATUS _hst
        )
        list(GET _hst 0 _hcode)
        if(NOT _hcode EQUAL 0)
            message(FATAL_ERROR "RTSan header download failed")
        endif()
    endif()

    if(NOT TARGET RTSan::Standalone)
        add_library(RTSan::Standalone ${_type} IMPORTED)
        set_target_properties(RTSan::Standalone PROPERTIES
            IMPORTED_LOCATION "${_lib}"
            INTERFACE_COMPILE_DEFINITIONS "__SANITIZE_REALTIME"
            INTERFACE_INCLUDE_DIRECTORIES "${_inc}"
        )
    endif()

    target_link_libraries(${RTSAN_TARGET} PRIVATE RTSan::Standalone)
    target_include_directories(${RTSAN_TARGET} PRIVATE "${_inc}")

    get_filename_component(_rtsan_abs "${_dir}" REALPATH)

    if(APPLE)
        target_link_options(${RTSAN_TARGET} PUBLIC 
            "-Wl,-rpath,${_rtsan_abs}"
        )
    endif()    
endfunction()

