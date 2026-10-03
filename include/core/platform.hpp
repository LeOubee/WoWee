#pragma once

// One place to say what kind of device this is.
//
//   WOWEE_IOS     iPhone / iPad (Apple, but not macOS)
//   WOWEE_MOBILE  Android or iOS: a touch screen, a small display, an app that
//                 the OS kills when it uses too much memory.
//
// Code that tunes for a phone tests WOWEE_MOBILE; code that is specific to the
// Android runtime (SDLActivity, bionic, JNI) keeps testing __ANDROID__.
#if defined(__APPLE__)
#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#define WOWEE_IOS 1
#endif
#endif

#if defined(__ANDROID__) || defined(WOWEE_IOS)
#define WOWEE_MOBILE 1
#endif
