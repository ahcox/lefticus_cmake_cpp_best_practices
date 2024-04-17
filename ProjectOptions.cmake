include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(lefticus_cmake_cpp_best_practices_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(lefticus_cmake_cpp_best_practices_setup_options)
  option(lefticus_cmake_cpp_best_practices_ENABLE_HARDENING "Enable hardening" ON)
  option(lefticus_cmake_cpp_best_practices_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    lefticus_cmake_cpp_best_practices_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    lefticus_cmake_cpp_best_practices_ENABLE_HARDENING
    OFF)

  lefticus_cmake_cpp_best_practices_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR lefticus_cmake_cpp_best_practices_PACKAGING_MAINTAINER_MODE)
    option(lefticus_cmake_cpp_best_practices_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(lefticus_cmake_cpp_best_practices_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(lefticus_cmake_cpp_best_practices_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(lefticus_cmake_cpp_best_practices_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(lefticus_cmake_cpp_best_practices_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(lefticus_cmake_cpp_best_practices_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(lefticus_cmake_cpp_best_practices_ENABLE_PCH "Enable precompiled headers" OFF)
    option(lefticus_cmake_cpp_best_practices_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(lefticus_cmake_cpp_best_practices_ENABLE_IPO "Enable IPO/LTO" ON)
    option(lefticus_cmake_cpp_best_practices_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(lefticus_cmake_cpp_best_practices_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(lefticus_cmake_cpp_best_practices_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(lefticus_cmake_cpp_best_practices_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(lefticus_cmake_cpp_best_practices_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(lefticus_cmake_cpp_best_practices_ENABLE_PCH "Enable precompiled headers" OFF)
    option(lefticus_cmake_cpp_best_practices_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      lefticus_cmake_cpp_best_practices_ENABLE_IPO
      lefticus_cmake_cpp_best_practices_WARNINGS_AS_ERRORS
      lefticus_cmake_cpp_best_practices_ENABLE_USER_LINKER
      lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_ADDRESS
      lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_LEAK
      lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_UNDEFINED
      lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_THREAD
      lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_MEMORY
      lefticus_cmake_cpp_best_practices_ENABLE_UNITY_BUILD
      lefticus_cmake_cpp_best_practices_ENABLE_CLANG_TIDY
      lefticus_cmake_cpp_best_practices_ENABLE_CPPCHECK
      lefticus_cmake_cpp_best_practices_ENABLE_COVERAGE
      lefticus_cmake_cpp_best_practices_ENABLE_PCH
      lefticus_cmake_cpp_best_practices_ENABLE_CACHE)
  endif()

  lefticus_cmake_cpp_best_practices_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_ADDRESS OR lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_THREAD OR lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(lefticus_cmake_cpp_best_practices_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(lefticus_cmake_cpp_best_practices_global_options)
  if(lefticus_cmake_cpp_best_practices_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    lefticus_cmake_cpp_best_practices_enable_ipo()
  endif()

  lefticus_cmake_cpp_best_practices_supports_sanitizers()

  if(lefticus_cmake_cpp_best_practices_ENABLE_HARDENING AND lefticus_cmake_cpp_best_practices_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_UNDEFINED
       OR lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_ADDRESS
       OR lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_THREAD
       OR lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${lefticus_cmake_cpp_best_practices_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_UNDEFINED}")
    lefticus_cmake_cpp_best_practices_enable_hardening(lefticus_cmake_cpp_best_practices_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(lefticus_cmake_cpp_best_practices_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(lefticus_cmake_cpp_best_practices_warnings INTERFACE)
  add_library(lefticus_cmake_cpp_best_practices_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  lefticus_cmake_cpp_best_practices_set_project_warnings(
    lefticus_cmake_cpp_best_practices_warnings
    ${lefticus_cmake_cpp_best_practices_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(lefticus_cmake_cpp_best_practices_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    lefticus_cmake_cpp_best_practices_configure_linker(lefticus_cmake_cpp_best_practices_options)
  endif()

  include(cmake/Sanitizers.cmake)
  lefticus_cmake_cpp_best_practices_enable_sanitizers(
    lefticus_cmake_cpp_best_practices_options
    ${lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_ADDRESS}
    ${lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_LEAK}
    ${lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_UNDEFINED}
    ${lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_THREAD}
    ${lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_MEMORY})

  set_target_properties(lefticus_cmake_cpp_best_practices_options PROPERTIES UNITY_BUILD ${lefticus_cmake_cpp_best_practices_ENABLE_UNITY_BUILD})

  if(lefticus_cmake_cpp_best_practices_ENABLE_PCH)
    target_precompile_headers(
      lefticus_cmake_cpp_best_practices_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(lefticus_cmake_cpp_best_practices_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    lefticus_cmake_cpp_best_practices_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(lefticus_cmake_cpp_best_practices_ENABLE_CLANG_TIDY)
    lefticus_cmake_cpp_best_practices_enable_clang_tidy(lefticus_cmake_cpp_best_practices_options ${lefticus_cmake_cpp_best_practices_WARNINGS_AS_ERRORS})
  endif()

  if(lefticus_cmake_cpp_best_practices_ENABLE_CPPCHECK)
    lefticus_cmake_cpp_best_practices_enable_cppcheck(${lefticus_cmake_cpp_best_practices_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(lefticus_cmake_cpp_best_practices_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    lefticus_cmake_cpp_best_practices_enable_coverage(lefticus_cmake_cpp_best_practices_options)
  endif()

  if(lefticus_cmake_cpp_best_practices_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(lefticus_cmake_cpp_best_practices_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(lefticus_cmake_cpp_best_practices_ENABLE_HARDENING AND NOT lefticus_cmake_cpp_best_practices_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_UNDEFINED
       OR lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_ADDRESS
       OR lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_THREAD
       OR lefticus_cmake_cpp_best_practices_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    lefticus_cmake_cpp_best_practices_enable_hardening(lefticus_cmake_cpp_best_practices_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
