cmake_minimum_required(VERSION 3.12.4)
set(CMAKE_OSX_DEPLOYMENT_TARGET
    "10.12"
    CACHE STRING "Minimum OS X deployment version")

set(MILL_SOFTWARE_VERSION 1.0.5)
project(crwrite VERSION ${MILL_SOFTWARE_VERSION})

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_BUILD_TYPE RelWithDebInfo)
set(CMAKE_MAP_IMPORTED_CONFIG_MINSIZEREL MinSizeRel Release)
set(CMAKE_MAP_IMPORTED_CONFIG_RELWITHDEBINFO "RelWithDebInfo;Release;")

if(WIN32)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /std:c++17 /MP")
  #set(CMAKE_GENERATOR_PLATFORM "Win32")
  string(REPLACE "/MD" "/MT" CMAKE_CXX_FLAGS_RELEASE
                 "${CMAKE_CXX_FLAGS_RELEASE}")
  string(REPLACE "/MD" "/MT" CMAKE_CXX_FLAGS_RELWITHDEBINFO
                 "${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")
else(WIN32)
  if(APPLE)
    set(CMAKE_CXX_FLAGS
        "${CMAKE_CXX_FLAGS} -std=c++17 -stdlib=libc++ -Wdeprecated-declarations -Wnonportable-include-path"
    )
    set(CMAKE_EXE_LINKER_FLAGS
        "${CMAKE_EXE_LINKER_FLAGS} -framework CoreFoundation -framework IOKit")
  else(APPLE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17")
  endif(APPLE)
endif(WIN32)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${CMAKE_BUILD_TYPE})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Dependencies
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/CMake)
string(TOUPPER "${CMAKE_BUILD_TYPE}" BUILD_TYPE_SUFFIX)
if(BUILD_TYPE_SUFFIX MATCHES "DEBUG")
  set(IMPORT_BUILD_TYPE "DEBUG")
else()
  set(IMPORT_BUILD_TYPE "RELEASE")
endif()

find_package(Boost REQUIRED COMPONENTS iostreams system thread filesystem)
find_package(Catch2 CONFIG REQUIRED)

if(NOT APPLE)
  find_package(Filesystem REQUIRED)
endif(NOT APPLE)

find_package(jsoncpp CONFIG REQUIRED)
# Support both old vcpkg (jsoncpp_lib) and new vcpkg (JsonCpp::JsonCpp)
if(TARGET jsoncpp_lib)
  get_target_property(jsoncpp_LIBRARIES jsoncpp_lib IMPORTED_LOCATION_${IMPORT_BUILD_TYPE})
  set(jsoncpp_LIBRARY_FILE "${jsoncpp_LIBRARIES}")
  else()
    add_library(jsoncpp_lib ALIAS JsonCpp::JsonCpp)
    get_target_property(jsoncpp_LIBRARIES JsonCpp::JsonCpp IMPORTED_LOCATION_${IMPORT_BUILD_TYPE})
    if(NOT jsoncpp_LIBRARIES)
      get_target_property(jsoncpp_LIBRARIES JsonCpp::JsonCpp IMPORTED_LOCATION)
    endif()
    if(jsoncpp_LIBRARIES)
      set(jsoncpp_LIBRARY_FILE "${jsoncpp_LIBRARIES}")
    else()
      # JsonCpp::JsonCpp is INTERFACE-only in this vcpkg; do not add to MILL_SOFTWARE_SRC
      set(jsoncpp_LIBRARY_FILE "")
    endif()
  endif()
find_package(minizip CONFIG REQUIRED)
get_target_property(minizip_LIBRARIES minizip::minizip IMPORTED_LOCATION_${IMPORT_BUILD_TYPE})
if(NOT minizip_LIBRARIES)
  get_target_property(minizip_LIBRARIES minizip::minizip IMPORTED_LOCATION)
endif()
find_package(OpenSSL REQUIRED)
find_package(spdlog CONFIG REQUIRED)
get_target_property(spdlog_LIBRARIES spdlog::spdlog IMPORTED_LOCATION_${IMPORT_BUILD_TYPE})
if(NOT spdlog_LIBRARIES)
  get_target_property(spdlog_LIBRARIES spdlog::spdlog IMPORTED_LOCATION)
endif()
find_package(Threads REQUIRED)
# vcpkg: newer ports use tiny-process-library (target tiny-process-library::...); old use unofficial-tiny-process-library
find_package(tiny-process-library CONFIG QUIET)
if(NOT tiny-process-library_FOUND)
  find_package(unofficial-tiny-process-library CONFIG REQUIRED)
endif()
# Prefer tiny-process-library:: (new port); fall back to unofficial:: (old port)
if(TARGET tiny-process-library::tiny-process-library)
  set(TINYPROCESS_LIBRARY_TARGET tiny-process-library::tiny-process-library)
elseif(TARGET unofficial::tiny-process-library::tiny-process-library)
  set(TINYPROCESS_LIBRARY_TARGET unofficial::tiny-process-library::tiny-process-library)
else()
  message(FATAL_ERROR "tiny-process-library: no known target found")
endif()
# ALIAS so subdirs (e.g. Mill/Firmware) always link to the same target
add_library(crwrite::tiny-process-library ALIAS ${TINYPROCESS_LIBRARY_TARGET})
get_target_property(tinyprocesslibrary_LIBRARIES ${TINYPROCESS_LIBRARY_TARGET} IMPORTED_LOCATION_${IMPORT_BUILD_TYPE})
if(NOT tinyprocesslibrary_LIBRARIES)
  get_target_property(tinyprocesslibrary_LIBRARIES ${TINYPROCESS_LIBRARY_TARGET} IMPORTED_LOCATION)
endif()
find_package(ZLIB REQUIRED)

include(NodeJS)
nodejs_init()

add_definitions(-DMILL_SOFTWARE_VERSION="${MILL_SOFTWARE_VERSION}")

if(WIN32)
  add_definitions(-DWIN32_LEAN_AND_MEAN)
endif()

include_directories(
  ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/deps/ghc/include
  ${CMAKE_CURRENT_SOURCE_DIR}/deps/optional/include)

set(CMAKE_INSTALL_NAME_DIR "@executable_path")
set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)

add_subdirectory(Common)
add_subdirectory(Mill)
add_subdirectory(Files)
add_subdirectory(Services)
add_subdirectory(Settings)

if(WIN32)
  set(MILL_SOFTWARE_SRC "")
else(WIN32)
  # Only add single library file paths (no generator-style "optimized;path;debug;path")
  set(MILL_SOFTWARE_SRC "")
  if(jsoncpp_LIBRARY_FILE)
    list(APPEND MILL_SOFTWARE_SRC "${jsoncpp_LIBRARY_FILE}")
  endif()
  if(minizip_LIBRARIES AND NOT minizip_LIBRARIES MATCHES ";")
    list(APPEND MILL_SOFTWARE_SRC "${minizip_LIBRARIES}")
  endif()
  if(OPENSSL_CRYPTO_LIBRARY AND NOT OPENSSL_CRYPTO_LIBRARY MATCHES ";")
    list(APPEND MILL_SOFTWARE_SRC "${OPENSSL_CRYPTO_LIBRARY}" "${OPENSSL_SSL_LIBRARY}")
  endif()
  if(tinyprocesslibrary_LIBRARIES AND NOT tinyprocesslibrary_LIBRARIES MATCHES ";")
    list(APPEND MILL_SOFTWARE_SRC "${tinyprocesslibrary_LIBRARIES}")
  endif()
  if(ZLIB_LIBRARIES AND NOT ZLIB_LIBRARIES MATCHES ";")
    list(APPEND MILL_SOFTWARE_SRC "${ZLIB_LIBRARIES}")
  endif()
  if(spdlog_LIBRARIES AND NOT spdlog_LIBRARIES MATCHES ";")
    list(APPEND MILL_SOFTWARE_SRC "${spdlog_LIBRARIES}")
  endif()
endif(WIN32)

list(
  APPEND
  MILL_SOFTWARE_SRC
  "${CMAKE_CURRENT_SOURCE_DIR}/MillDaemon.cpp"
  $<TARGET_OBJECTS:crwrite-common>
  $<TARGET_OBJECTS:crwrite-files>
  $<TARGET_OBJECTS:crwrite-firmware>
  $<TARGET_OBJECTS:crwrite-mill>
  $<TARGET_OBJECTS:crwrite-mill-drivers>
  $<TARGET_OBJECTS:crwrite-mill-display>
  $<TARGET_OBJECTS:crwrite-services>
  $<TARGET_OBJECTS:crwrite-settings>
  $<TARGET_OBJECTS:crwrite-mill-grbl>)

add_library(MillDaemon STATIC ${MILL_SOFTWARE_SRC})
set_property(TARGET MillDaemon PROPERTY POSITION_INDEPENDENT_CODE 1)
target_link_libraries(
  MillDaemon
  INTERFACE jsoncpp_lib
  PRIVATE jsoncpp_lib
          ZLIB::ZLIB
          minizip::minizip
          crwrite::tiny-process-library
          OpenSSL::Crypto
          OpenSSL::SSL
          Threads::Threads
          Boost::system
          Boost::thread
          Boost::filesystem
          spdlog::spdlog)

if(NOT APPLE)
  target_link_libraries(MillDaemon PRIVATE std::filesystem)
endif(NOT APPLE)

if(WIN32)
  target_link_libraries(MillDaemon PRIVATE setupapi crypt32)
endif(WIN32)

add_nodejs_module(${PROJECT_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/NodeWrapper.cpp")
set_target_properties(
  ${PROJECT_NAME}
  PROPERTIES MACOSX_RPATH ON
             BUILD_WITH_INSTALL_RPATH 1
             INSTALL_NAME_DIR "@executable_path")
target_link_libraries(${PROJECT_NAME} PRIVATE MillDaemon)
# When deps are INTERFACE-only or path not found (new vcpkg), crwrite must link them directly
if(NOT jsoncpp_LIBRARY_FILE)
  target_link_libraries(${PROJECT_NAME} PRIVATE jsoncpp_lib)
endif()
if(NOT minizip_LIBRARIES OR minizip_LIBRARIES MATCHES ";")
  target_link_libraries(${PROJECT_NAME} PRIVATE minizip::minizip)
endif()
if(NOT OPENSSL_CRYPTO_LIBRARY OR OPENSSL_CRYPTO_LIBRARY MATCHES ";")
  target_link_libraries(${PROJECT_NAME} PRIVATE OpenSSL::Crypto OpenSSL::SSL)
endif()
if(NOT tinyprocesslibrary_LIBRARIES OR tinyprocesslibrary_LIBRARIES MATCHES ";")
  target_link_libraries(${PROJECT_NAME} PRIVATE crwrite::tiny-process-library)
endif()
if(NOT ZLIB_LIBRARIES OR ZLIB_LIBRARIES MATCHES ";")
  target_link_libraries(${PROJECT_NAME} PRIVATE ZLIB::ZLIB)
endif()
if(NOT spdlog_LIBRARIES OR spdlog_LIBRARIES MATCHES ";")
  target_link_libraries(${PROJECT_NAME} PRIVATE spdlog::spdlog)
endif()

add_executable(MillUtil "MillTest.cpp")
target_link_libraries(MillUtil MillDaemon)

#add_subdirectory(Tests)

add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:crwrite> ${CMAKE_CURRENT_LIST_DIR}/../UI/app/Backend/crwrite.node
)
