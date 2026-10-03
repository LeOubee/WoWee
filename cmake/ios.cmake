# iOS support (first pass, untested on a device).
#
# Included from CMakeLists.txt when CMAKE_SYSTEM_NAME is iOS. It does two jobs:
#   1. Makes Vulkan::Vulkan out of MoltenVK, because iOS has no Vulkan loader.
#   2. Defines wowee_ios_configure_bundle(), called once the wowee target exists.
#
# Configure with:
#   cmake -G Xcode -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_ARCHITECTURES=arm64 \
#         -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
#         -DWOWEE_MOLTENVK_DIR=<dir of MoltenVK-ios.tar>/MoltenVK/MoltenVK \
#         -DOPENSSL_ROOT_DIR=<tools/build-ios-deps.sh output> ...

set(WOWEE_MOLTENVK_DIR "" CACHE PATH
    "MoltenVK/MoltenVK folder from MoltenVK-ios.tar (has include/ and dynamic/)")
if(NOT WOWEE_MOLTENVK_DIR OR NOT EXISTS "${WOWEE_MOLTENVK_DIR}/include/vulkan/vulkan.h")
    message(FATAL_ERROR
        "iOS build needs -DWOWEE_MOLTENVK_DIR=<...>/MoltenVK/MoltenVK from MoltenVK-ios.tar "
        "(https://github.com/KhronosGroup/MoltenVK/releases)")
endif()

set(WOWEE_MOLTENVK_FW_DIR "${WOWEE_MOLTENVK_DIR}/dynamic/MoltenVK.xcframework/ios-arm64")

# Linked directly, so the vk* symbols resolve at link time. The framework is
# embedded in the app by wowee_ios_configure_bundle().
if(NOT TARGET Vulkan::Vulkan)
    add_library(Vulkan::Vulkan INTERFACE IMPORTED)
endif()
set_target_properties(Vulkan::Vulkan PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${WOWEE_MOLTENVK_DIR}/include"
    INTERFACE_LINK_LIBRARIES
        "-F${WOWEE_MOLTENVK_FW_DIR};-framework MoltenVK;-framework Metal;-framework QuartzCore;-framework IOSurface;-framework UIKit;-framework CoreGraphics;-framework Foundation")
message(STATUS "iOS: Vulkan via MoltenVK at ${WOWEE_MOLTENVK_FW_DIR}")

# miniaudio's Core Audio backend needs Objective-C on iOS (AVAudioSession).
# audio_engine.cpp is the one unit that compiles its implementation.
set_source_files_properties(src/audio/audio_engine.cpp PROPERTIES
    COMPILE_OPTIONS "-x;objective-c++;-Wno-unused-parameter")

function(wowee_ios_configure_bundle TARGET)
    set_target_properties(${TARGET} PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_SOURCE_DIR}/resources/ios/Info.plist.in"
        MACOSX_BUNDLE_BUNDLE_NAME "Wowee"
        MACOSX_BUNDLE_GUI_IDENTIFIER "com.example.wowee"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}"
        MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
        XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
        XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "NO"
        XCODE_ATTRIBUTE_ENABLE_BITCODE "NO"
        XCODE_ATTRIBUTE_LD_RUNPATH_SEARCH_PATHS "@executable_path/Frameworks")

    target_link_libraries(${TARGET} PRIVATE
        "-framework AVFoundation" "-framework AudioToolbox" "-framework CoreAudio"
        "-framework CoreFoundation" "-framework CoreMotion" "-framework CoreHaptics"
        "-framework GameController" "-framework Metal" "-framework UIKit")

    # Static data the client reads from its working directory (the bundle root).
    # The game's own files are not here: the player copies them into Documents.
    add_custom_command(TARGET ${TARGET} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${CMAKE_SOURCE_DIR}/Data $<TARGET_FILE_DIR:${TARGET}>/Data
        COMMAND ${CMAKE_COMMAND} -E make_directory $<TARGET_FILE_DIR:${TARGET}>/Frameworks
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${WOWEE_MOLTENVK_FW_DIR}/MoltenVK.framework
            $<TARGET_FILE_DIR:${TARGET}>/Frameworks/MoltenVK.framework
        COMMENT "Embedding Data and MoltenVK in the app bundle")
endfunction()
