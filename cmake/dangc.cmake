# dangc.cmake - CMake module for building DANGC programs
#
# Provides functions for compiling, assembling, and linking DANGC source files
# using the native dangc toolchain (dangcc, dangsm, danglnk).
#
# Usage:
#   include(Dangc)
#   dangc_add_executable(myprogram source.dngc)
#   dangc_add_executable(myprogram source.dngc ARCH amd64)
#
# Variables:
#   DANGC_ROOT        - Path to dangc installation (auto-detected if not set)
#   DANGC_ARCH        - Default architecture (amd64 or i386, default: amd64)
#   DANGCC            - Path to dangcc compiler
#   DANGSM            - Path to dangsm assembler
#   DANGLNK           - Path to danglnk linker
#
# Functions:
#   dangc_find_toolchain()           - Locate dangcc, dangsm, danglnk
#   dangc_add_executable(name src)   - Build executable from DANGC source
#   dangc_add_object(name src)       - Build object file (.im) from DANGC source
#   dangc_link_executable(name objs) - Link object files into executable

include_guard(GLOBAL)

# Default architecture
if(NOT DEFINED DANGC_ARCH)
    set(DANGC_ARCH "amd64" CACHE STRING "DANGC target architecture (amd64 or i386)")
endif()

# Find the dangc toolchain
function(dangc_find_toolchain)
    # Try DANGC_ROOT first
    if(DEFINED DANGC_ROOT)
        set(_search_paths "${DANGC_ROOT}/bin" "${DANGC_ROOT}/build/bin" "${DANGC_ROOT}")
    else()
        # Auto-detect: check common locations
        set(_search_paths
            "${CMAKE_CURRENT_SOURCE_DIR}/build/bin"
            "${CMAKE_CURRENT_SOURCE_DIR}/../dangc/build/bin"
            "$ENV{HOME}/git/dangc/build/bin"
            "/usr/local/bin"
            "/usr/bin"
        )
    endif()

    # Find dangcc
    find_program(DANGCC dangcc PATHS ${_search_paths} NO_DEFAULT_PATH)
    if(NOT DANGCC)
        find_program(DANGCC dangcc)
    endif()
    if(NOT DANGCC)
        message(FATAL_ERROR "dangcc not found. Set DANGC_ROOT or add to PATH.")
    endif()

    # Find dangsm
    find_program(DANGSM dangsm PATHS ${_search_paths} NO_DEFAULT_PATH)
    if(NOT DANGSM)
        find_program(DANGSM dangsm)
    endif()
    if(NOT DANGSM)
        message(FATAL_ERROR "dangsm not found. Set DANGC_ROOT or add to PATH.")
    endif()

    # Find danglnk
    find_program(DANGLNK danglnk PATHS ${_search_paths} NO_DEFAULT_PATH)
    if(NOT DANGLNK)
        find_program(DANGLNK danglnk)
    endif()
    if(NOT DANGLNK)
        message(FATAL_ERROR "danglnk not found. Set DANGC_ROOT or add to PATH.")
    endif()

    # Export to parent scope
    set(DANGCC ${DANGCC} PARENT_SCOPE)
    set(DANGSM ${DANGSM} PARENT_SCOPE)
    set(DANGLNK ${DANGLNK} PARENT_SCOPE)

    message(STATUS "DANGC toolchain found:")
    message(STATUS "  dangcc:  ${DANGCC}")
    message(STATUS "  dangsm:  ${DANGSM}")
    message(STATUS "  danglnk: ${DANGLNK}")
endfunction()

# Compile DANGC source to assembly
# dangc_compile(OUTPUT_VAR source.dngc [ARCH arch])
function(dangc_compile OUTPUT_VAR SOURCE)
    cmake_parse_arguments(ARG "" "ARCH" "" ${ARGN})

    if(NOT ARG_ARCH)
        set(ARG_ARCH ${DANGC_ARCH})
    endif()

    get_filename_component(_name ${SOURCE} NAME_WE)
    get_filename_component(_src_abs ${SOURCE} ABSOLUTE)
    set(_asm_file "${CMAKE_CURRENT_BINARY_DIR}/${_name}_${ARG_ARCH}.asm")

    add_custom_command(
        OUTPUT ${_asm_file}
        COMMAND ${CMAKE_COMMAND} -E env ASAN_OPTIONS=detect_leaks=0
                ${DANGCC} --${ARG_ARCH} ${_src_abs} > ${_asm_file}
        DEPENDS ${_src_abs}
        COMMENT "Compiling ${SOURCE} to ${ARG_ARCH} assembly"
        VERBATIM
    )

    set(${OUTPUT_VAR} ${_asm_file} PARENT_SCOPE)
endfunction()

# Assemble to intermediate object
# dangc_assemble(OUTPUT_VAR source.asm [ARCH arch])
function(dangc_assemble OUTPUT_VAR ASM_FILE)
    cmake_parse_arguments(ARG "" "ARCH" "" ${ARGN})

    if(NOT ARG_ARCH)
        set(ARG_ARCH ${DANGC_ARCH})
    endif()

    get_filename_component(_name ${ASM_FILE} NAME_WE)
    set(_im_file "${CMAKE_CURRENT_BINARY_DIR}/${_name}.im")

    add_custom_command(
        OUTPUT ${_im_file}
        COMMAND ${DANGSM} --${ARG_ARCH} -c ${ASM_FILE} -o ${_im_file}
        DEPENDS ${ASM_FILE}
        COMMENT "Assembling ${ASM_FILE} to intermediate object"
        VERBATIM
    )

    set(${OUTPUT_VAR} ${_im_file} PARENT_SCOPE)
endfunction()

# Link intermediate objects to ELF executable
# dangc_link(OUTPUT_VAR output_name obj1 [obj2 ...] [ARCH arch])
function(dangc_link OUTPUT_VAR OUTPUT_NAME)
    cmake_parse_arguments(ARG "" "ARCH" "" ${ARGN})

    if(NOT ARG_ARCH)
        set(ARG_ARCH ${DANGC_ARCH})
    endif()

    # Remaining args are object files
    set(_objs ${ARG_UNPARSED_ARGUMENTS})

    set(_exe_file "${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_NAME}")

    add_custom_command(
        OUTPUT ${_exe_file}
        COMMAND ${DANGLNK} --${ARG_ARCH} -o ${_exe_file} ${_objs}
        DEPENDS ${_objs}
        COMMENT "Linking ${OUTPUT_NAME}"
        VERBATIM
    )

    set(${OUTPUT_VAR} ${_exe_file} PARENT_SCOPE)
endfunction()

# Build object file from DANGC source (compile + assemble)
# dangc_add_object(name source.dngc [ARCH arch])
function(dangc_add_object NAME SOURCE)
    cmake_parse_arguments(ARG "" "ARCH" "" ${ARGN})

    if(NOT ARG_ARCH)
        set(ARG_ARCH ${DANGC_ARCH})
    endif()

    # Compile
    dangc_compile(_asm ${SOURCE} ARCH ${ARG_ARCH})

    # Assemble
    dangc_assemble(_im ${_asm} ARCH ${ARG_ARCH})

    # Create target
    add_custom_target(${NAME} ALL DEPENDS ${_im})

    # Store output path for later linking
    set_target_properties(${NAME} PROPERTIES
        DANGC_OBJECT_FILE ${_im}
        DANGC_ARCH ${ARG_ARCH}
    )
endfunction()

# Build executable from DANGC source (compile + assemble + link)
# dangc_add_executable(name source.dngc [ARCH arch] [OBJECTS obj1 obj2 ...])
function(dangc_add_executable NAME SOURCE)
    cmake_parse_arguments(ARG "" "ARCH" "OBJECTS" ${ARGN})

    if(NOT ARG_ARCH)
        set(ARG_ARCH ${DANGC_ARCH})
    endif()

    # Compile
    dangc_compile(_asm ${SOURCE} ARCH ${ARG_ARCH})

    # Assemble
    dangc_assemble(_im ${_asm} ARCH ${ARG_ARCH})

    # Collect all object files
    set(_all_objs ${_im})
    foreach(_obj ${ARG_OBJECTS})
        if(TARGET ${_obj})
            get_target_property(_obj_file ${_obj} DANGC_OBJECT_FILE)
            list(APPEND _all_objs ${_obj_file})
        else()
            list(APPEND _all_objs ${_obj})
        endif()
    endforeach()

    # Link
    dangc_link(_exe ${NAME} ${_all_objs} ARCH ${ARG_ARCH})

    # Create target
    add_custom_target(${NAME} ALL DEPENDS ${_exe})

    # Store output path
    set_target_properties(${NAME} PROPERTIES
        DANGC_EXECUTABLE ${_exe}
        DANGC_ARCH ${ARG_ARCH}
    )
endfunction()

# Auto-find toolchain on include
dangc_find_toolchain()
