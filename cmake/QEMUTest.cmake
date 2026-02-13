enable_testing()

set(QEMU_TEST_SCRIPT_DIR "${CMAKE_CURRENT_LIST_DIR}/qemu" CACHE PATH "")
set(QEMU_TEST_DEFAULT_ARCH "x86_64" CACHE STRING "")
set(QEMU_TEST_DEFAULT_VARIANT "dev" CACHE STRING "")
set(QEMU_TEST_DEFAULT_TIMEOUT "120" CACHE STRING "")

function(qemu_add_test)
    set(options DKMS)
    set(oneValueArgs NAME COMMAND ARCH VARIANT TIMEOUT KERNEL_MODULE MODULE_NAME DATA_DIR)
    cmake_parse_arguments(QAT "${options}" "${oneValueArgs}" "" ${ARGN})

    if(NOT QAT_ARCH)
        set(QAT_ARCH "${QEMU_TEST_DEFAULT_ARCH}")
    endif()
    if(NOT QAT_VARIANT)
        set(QAT_VARIANT "${QEMU_TEST_DEFAULT_VARIANT}")
    endif()
    if(NOT QAT_TIMEOUT)
        set(QAT_TIMEOUT "${QEMU_TEST_DEFAULT_TIMEOUT}")
    endif()

    set(_runner "${QEMU_TEST_SCRIPT_DIR}/qemu-runner.sh")
    set(_args
        --arch ${QAT_ARCH}
        --binary $<TARGET_FILE:${QAT_COMMAND}>
        --variant ${QAT_VARIANT}
        --timeout ${QAT_TIMEOUT}
        --build-dir ${CMAKE_BINARY_DIR}
        --gcov-dir ${CMAKE_BINARY_DIR}
    )

    if(QAT_DKMS AND QAT_KERNEL_MODULE)
        list(APPEND _args --kernel-module ${QAT_KERNEL_MODULE} --module-name ${QAT_MODULE_NAME})
    endif()

    if(QAT_DATA_DIR)
        list(APPEND _args --data-dir ${QAT_DATA_DIR})
    endif()

    add_test(
        NAME ${QAT_NAME}
        COMMAND ${_runner} ${_args}
    )

    add_custom_target(run-${QAT_NAME}
        COMMAND ${_runner} ${_args}
        DEPENDS ${QAT_COMMAND}
        COMMENT "Running ${QAT_NAME} in QEMU (${QAT_ARCH}/${QAT_VARIANT})"
        VERBATIM
    )
endfunction()

function(qemu_add_cross_test)
    set(options DKMS)
    set(oneValueArgs NAME COMMAND VARIANT TIMEOUT KERNEL_MODULE MODULE_NAME)
    set(multiValueArgs ARCHS)
    cmake_parse_arguments(QCT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT QCT_ARCHS)
        set(QCT_ARCHS x86_64 i386 aarch64 riscv64)
    endif()

    foreach(_arch IN LISTS QCT_ARCHS)
        set(_test_name "${QCT_NAME}_${_arch}")
        set(_extra_args "")
        if(QCT_DKMS)
            list(APPEND _extra_args DKMS)
        endif()
        if(QCT_KERNEL_MODULE)
            list(APPEND _extra_args KERNEL_MODULE ${QCT_KERNEL_MODULE} MODULE_NAME ${QCT_MODULE_NAME})
        endif()

        qemu_add_test(
            NAME ${_test_name}
            COMMAND ${QCT_COMMAND}
            ARCH ${_arch}
            ${_extra_args}
        )
    endforeach()
endfunction()

function(qemu_add_run_target)
    set(oneValueArgs COVERAGE_DIR)
    cmake_parse_arguments(QRT "" "${oneValueArgs}" "" ${ARGN})

    if(NOT QRT_COVERAGE_DIR)
        set(QRT_COVERAGE_DIR "${CMAKE_BINARY_DIR}/coverage_html")
    endif()

    add_custom_target(tests-run
        COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure -j 12
        COMMAND lcov --capture --directory ${CMAKE_BINARY_DIR} --output-file ${CMAKE_BINARY_DIR}/coverage.info --quiet
        COMMAND genhtml ${CMAKE_BINARY_DIR}/coverage.info --output-directory ${QRT_COVERAGE_DIR} --quiet
        COMMAND git -C ${CMAKE_SOURCE_DIR} test-state save || true
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "run all tests in QEMU; gen cov"
        VERBATIM
    )
endfunction()
