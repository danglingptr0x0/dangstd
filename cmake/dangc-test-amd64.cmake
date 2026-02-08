# dangc-test-amd64.cmake - Test runner for DANGC AMD64 integration tests
# Builds with native toolchain (dangsm + danglnk), validates with NASM + ld

if(NOT DANGCC)
    message(FATAL_ERROR "DANGCC not specified")
endif()

if(NOT TEST_FILE)
    message(FATAL_ERROR "TEST_FILE not specified")
endif()

if(NOT OUT_DIR)
    set(OUT_DIR "${CMAKE_CURRENT_BINARY_DIR}")
endif()

if(NOT CMAKE_DIR)
    get_filename_component(CMAKE_DIR ${CMAKE_CURRENT_LIST_FILE} DIRECTORY)
endif()

# Derive dangsm and danglnk from dangcc location
get_filename_component(TOOLCHAIN_DIR ${DANGCC} DIRECTORY)
set(DANGSM "${TOOLCHAIN_DIR}/dangsm")
set(DANGLNK "${TOOLCHAIN_DIR}/danglnk")

get_filename_component(TEST_NAME ${TEST_FILE} NAME_WE)
set(ASM_FILE "${OUT_DIR}/${TEST_NAME}_amd64.asm")

# Native toolchain outputs
set(IM_FILE "${OUT_DIR}/${TEST_NAME}_amd64.im")
set(NATIVE_EXE "${OUT_DIR}/${TEST_NAME}_amd64_native")

# Reference toolchain outputs (NASM + ld)
set(REF_OBJ "${OUT_DIR}/${TEST_NAME}_amd64.o")
set(REF_EXE "${OUT_DIR}/${TEST_NAME}_amd64_ref")
set(RT_OBJ "${OUT_DIR}/runtime_amd64.o")

file(MAKE_DIRECTORY ${OUT_DIR})

# Parse test file for directives
file(READ ${TEST_FILE} TEST_CONTENT)
set(EXPECTED_EXIT "")
set(EXPECT_FAIL FALSE)
set(HAS_START FALSE)

if(TEST_CONTENT MATCHES "// *EXPECT_FAIL")
    set(EXPECT_FAIL TRUE)
endif()

if(TEST_CONTENT MATCHES "// *EXPECT_AMD64: *([0-9]+)")
    set(EXPECTED_EXIT ${CMAKE_MATCH_1})
elseif(TEST_CONTENT MATCHES "// *EXPECT: *([0-9]+)")
    set(EXPECTED_EXIT ${CMAKE_MATCH_1})
endif()

if(TEST_CONTENT MATCHES "(32|64) _start\\(")
    set(HAS_START TRUE)
endif()

# ============================================================================
# Step 1: Compile DANGC to AMD64 assembly (dangcc)
# ============================================================================
set(ENV{ASAN_OPTIONS} "detect_leaks=0")
execute_process(
    COMMAND ${DANGCC} --amd64 ${TEST_FILE}
    OUTPUT_FILE ${ASM_FILE}
    ERROR_VARIABLE COMPILE_ERROR
    RESULT_VARIABLE COMPILE_RESULT
)

if(EXPECT_FAIL)
    if(COMPILE_RESULT EQUAL 0)
        message(FATAL_ERROR "${TEST_NAME}: Expected compilation to fail, but it succeeded")
    endif()
    message(STATUS "${TEST_NAME} (amd64): OK (expected compilation failure)")
    return()
endif()

if(NOT COMPILE_RESULT EQUAL 0)
    message(FATAL_ERROR "dangcc --amd64 failed: ${COMPILE_ERROR}")
endif()

if(NOT EXISTS ${ASM_FILE})
    message(FATAL_ERROR "Assembly file not created: ${ASM_FILE}")
endif()

file(SIZE ${ASM_FILE} ASM_SIZE)
if(ASM_SIZE EQUAL 0)
    message(FATAL_ERROR "Assembly file is empty: ${ASM_FILE}")
endif()

# ============================================================================
# Step 2: Build with native toolchain (dangsm + danglnk)
# ============================================================================
execute_process(
    COMMAND ${DANGSM} --amd64 -c ${ASM_FILE} -o ${IM_FILE}
    ERROR_VARIABLE DANGSM_ERROR
    RESULT_VARIABLE DANGSM_RESULT
)
if(NOT DANGSM_RESULT EQUAL 0)
    message(FATAL_ERROR "dangsm failed: ${DANGSM_ERROR}")
endif()

execute_process(
    COMMAND ${DANGLNK} --amd64 -o ${NATIVE_EXE} ${IM_FILE}
    ERROR_VARIABLE DANGLNK_ERROR
    RESULT_VARIABLE DANGLNK_RESULT
)
if(NOT DANGLNK_RESULT EQUAL 0)
    message(FATAL_ERROR "danglnk failed: ${DANGLNK_ERROR}")
endif()

# danglnk doesn't set execute permission yet - do it manually
file(CHMOD ${NATIVE_EXE} PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE)

# ============================================================================
# Step 3: Build with reference toolchain (NASM + ld)
# ============================================================================
find_program(NASM nasm)
find_program(LD ld)

set(REF_AVAILABLE TRUE)
if(NOT NASM)
    set(REF_AVAILABLE FALSE)
endif()
if(NOT LD)
    set(REF_AVAILABLE FALSE)
endif()

if(REF_AVAILABLE)
    execute_process(
        COMMAND ${NASM} -f elf64 ${ASM_FILE} -o ${REF_OBJ}
        ERROR_VARIABLE NASM_ERROR
        RESULT_VARIABLE NASM_RESULT
    )
    if(NOT NASM_RESULT EQUAL 0)
        message(FATAL_ERROR "NASM failed: ${NASM_ERROR}")
    endif()

    if(HAS_START)
        execute_process(
            COMMAND ${LD} -m elf_x86_64 -o ${REF_EXE} ${REF_OBJ}
            ERROR_VARIABLE LD_ERROR
            RESULT_VARIABLE LD_RESULT
        )
    else()
        if(NOT EXISTS ${RT_OBJ})
            execute_process(
                COMMAND ${NASM} -f elf64 ${CMAKE_DIR}/runtime_amd64.asm -o ${RT_OBJ}
                ERROR_VARIABLE RT_ERROR
                RESULT_VARIABLE RT_RESULT
            )
            if(NOT RT_RESULT EQUAL 0)
                message(FATAL_ERROR "NASM runtime failed: ${RT_ERROR}")
            endif()
        endif()
        execute_process(
            COMMAND ${LD} -m elf_x86_64 -o ${REF_EXE} ${RT_OBJ} ${REF_OBJ}
            ERROR_VARIABLE LD_ERROR
            RESULT_VARIABLE LD_RESULT
        )
    endif()

    if(NOT LD_RESULT EQUAL 0)
        message(FATAL_ERROR "ld failed: ${LD_ERROR}")
    endif()
endif()

# ============================================================================
# Step 4: Execute and compare
# ============================================================================
if(NOT EXPECTED_EXIT STREQUAL "" OR HAS_START)
    # Run native toolchain binary
    execute_process(
        COMMAND ${NATIVE_EXE}
        RESULT_VARIABLE NATIVE_RESULT
        TIMEOUT 10
    )

    # Run reference binary if available
    if(REF_AVAILABLE)
        execute_process(
            COMMAND ${REF_EXE}
            RESULT_VARIABLE REF_RESULT
            TIMEOUT 10
        )

        # Compare results
        if(NOT NATIVE_RESULT EQUAL REF_RESULT)
            message(FATAL_ERROR "${TEST_NAME}: MISMATCH - native=${NATIVE_RESULT}, ref=${REF_RESULT}")
        endif()
    endif()

    # Check expected exit code
    if(NOT EXPECTED_EXIT STREQUAL "")
        if(NOT NATIVE_RESULT EQUAL ${EXPECTED_EXIT})
            message(FATAL_ERROR "${TEST_NAME}: FAILED - expected ${EXPECTED_EXIT}, got ${NATIVE_RESULT}")
        endif()
        if(REF_AVAILABLE)
            message(STATUS "${TEST_NAME} (amd64): OK (native=${NATIVE_RESULT}, ref=${REF_RESULT}, expected=${EXPECTED_EXIT})")
        else()
            message(STATUS "${TEST_NAME} (amd64): OK (native=${NATIVE_RESULT}, expected=${EXPECTED_EXIT}, ref=N/A)")
        endif()
    else()
        if(REF_AVAILABLE)
            message(STATUS "${TEST_NAME} (amd64): OK (native=${NATIVE_RESULT}, ref=${REF_RESULT})")
        else()
            message(STATUS "${TEST_NAME} (amd64): OK (native=${NATIVE_RESULT}, ref=N/A)")
        endif()
    endif()
else()
    message(STATUS "${TEST_NAME} (amd64): OK (compiled + assembled + linked)")
endif()
