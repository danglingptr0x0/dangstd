set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

if(NOT CMAKE_SYSTEM_NAME STREQUAL "Windows")
    add_compile_definitions(_POSIX_C_SOURCE=200809L)
endif()

option(STD_DEBUG "Enable debug mode with -g, -O0" OFF)
option(STD_NO_INSTR "Disable sanitizers and coverage instrumentation" OFF)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -pedantic -Wall -Wextra -Werror -fanalyzer -Wnull-dereference -Wshadow -Wstrict-prototypes -Wmissing-prototypes -Wsign-conversion -Wconversion -Wformat=2 -Wcast-align -Wwrite-strings -Wundef -Wunused -Wuninitialized -Wpointer-arith -Wdouble-promotion -Wfloat-equal -Wswitch-enum -Wswitch-default -Wstrict-overflow=5 -Winit-self -Wlogical-op -Wredundant-decls -Wno-main")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fstack-protector-strong")
if(NOT CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fstack-clash-protection -fcf-protection=full")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-z,relro -Wl,-z,now -Wl,-z,noexecstack")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-z,relro -Wl,-z,now -Wl,-z,noexecstack")
endif()

if(STD_DEBUG)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g -O0")
    if(NOT STD_NO_INSTR)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} --coverage -fprofile-arcs -ftest-coverage -fsanitize=undefined,address,leak")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage -fsanitize=undefined,address,leak")
    endif()
else()
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3")
    add_compile_definitions(_FORTIFY_SOURCE=3)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wformat-overflow=2 -Wformat-truncation=2 -Wformat-signedness -Walloca -Wvla -Wtrampolines -Wbidi-chars=any -Warray-bounds=2 -Wstringop-overflow=4 -Wimplicit-fallthrough=5 -Wduplicated-cond -Wduplicated-branches -Wrestrict -Wnested-externs -Wold-style-definition -Wjump-misses-init -Wshift-overflow=2 -Wdate-time -Wstack-usage=1024")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fno-common -fno-delete-null-pointer-checks -ftrivial-auto-var-init=zero")
    if(NOT CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fPIE -pie")
    else()
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fcf-protection=full")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--dynamicbase -Wl,--nxcompat -Wl,--high-entropy-va")
        set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--dynamicbase -Wl,--nxcompat -Wl,--high-entropy-va")
    endif()
endif()

include(QEMUTest)

set(STD_TEST_TARGETS "" CACHE INTERNAL "")

function(std_register_test TARGET)
    set(STD_TEST_TARGETS "${STD_TEST_TARGETS};${TARGET}" CACHE INTERNAL "")
endfunction()

function(std_invalidate_test_state TARGET)
    add_custom_target(invalidate-test-state
        COMMAND ${CMAKE_COMMAND} -E remove -f ${CMAKE_SOURCE_DIR}/.test-state
        COMMENT "Invalidating test state"
    )
    add_dependencies(${TARGET} invalidate-test-state)
endfunction()

if(NOT STD_DEBUG)
    find_program(SPATCH_EXE spatch REQUIRED)
    message(STATUS "Running Coccinelle checks...")
    execute_process(
        COMMAND $ENV{HOME}/.config/git/cocci/run-all.sh ${CMAKE_SOURCE_DIR}/src --short
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        RESULT_VARIABLE COCCI_RESULT
    )
    if(NOT COCCI_RESULT EQUAL 0)
        message(FATAL_ERROR "Coccinelle checks failed - fix issues before building")
    endif()
endif()
