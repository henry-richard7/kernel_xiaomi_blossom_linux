#pragma once

#ifndef __BEGIN_DECLS
#if defined(__cplusplus)
#define __BEGIN_DECLS extern "C" {
#define __END_DECLS }
#else
#define __BEGIN_DECLS
#define __END_DECLS
#endif
#endif

#ifndef __LIBC_HIDDEN__
#define __LIBC_HIDDEN__ __attribute__((visibility("hidden")))
#endif

#ifndef __BIONIC_ALIGN
#define __BIONIC_ALIGN(__value, __alignment) (((__value) + (__alignment)-1) & ~((__alignment)-1))
#endif

#ifndef __INTRODUCED_IN
#define __INTRODUCED_IN(x)
#endif
