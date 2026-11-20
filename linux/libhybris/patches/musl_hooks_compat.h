#ifndef MUSL_HOOKS_COMPAT_H
#define MUSL_HOOKS_COMPAT_H

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#ifndef _LARGEFILE64_SOURCE
#define _LARGEFILE64_SOURCE
#endif

#include <sys/types.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>
#include <dirent.h>
#include <unistd.h>
#include <limits.h>

#ifndef __THROW
#define __THROW
#endif

#ifndef off64_t
typedef off_t off64_t;
#endif

#ifndef fpos64_t
typedef off_t fpos64_t;
#endif

#ifndef __GLIBC__

#ifndef mmap64
#define mmap64 mmap
#endif

#ifndef fopen64
#define fopen64 fopen
#endif

#ifndef freopen64
#define freopen64 freopen
#endif

#ifndef fseeko64
#define fseeko64 fseeko
#endif

#ifndef ftello64
#define ftello64 ftello
#endif

static inline int pthread_attr_setstackaddr(pthread_attr_t *attr, void *stackaddr) {
    size_t stacksize;
    pthread_attr_getstacksize(attr, &stacksize);
    return pthread_attr_setstack(attr, stackaddr, stacksize);
}

static inline int pthread_attr_getstackaddr(const pthread_attr_t *attr, void **stackaddr) {
    size_t stacksize;
    return pthread_attr_getstack((pthread_attr_t *)attr, stackaddr, &stacksize);
}

static inline int pthread_cond_clockwait(pthread_cond_t *cond, pthread_mutex_t *mutex, clockid_t clock_id, const struct timespec *abstime) {
    return pthread_cond_timedwait(cond, mutex, abstime);
}

static inline int pthread_rwlockattr_setkind_np(pthread_rwlockattr_t *attr, int pref) {
    return 0;
}

static inline int pthread_rwlockattr_getkind_np(const pthread_rwlockattr_t *attr, int *pref) {
    if (pref) *pref = 0;
    return 0;
}

static inline void *pvalloc(size_t size) {
    size_t page_mask = 4096 - 1;
    return valloc((size + page_mask) & ~page_mask);
}

struct mallinfo {
    int arena, ordblks, smblks, hblks, hblkhd, usmblks, fsmblks, uordblks, fordblks, keepcost;
};
static inline struct mallinfo mallinfo(void) {
    struct mallinfo m = {0};
    return m;
}

static inline wchar_t *wmempcpy(wchar_t *dest, const wchar_t *src, size_t n) {
    return (wchar_t *)wmemcpy(dest, src, n) + n;
}

static inline int scandirat(int fd, const char *dir, struct dirent ***namelist,
              int (*filter)(const struct dirent *),
              int (*compar)(const struct dirent **, const struct dirent **))
{
    char cwd[PATH_MAX];
    getcwd(cwd, sizeof(cwd));
    fchdir(fd);
    int res = scandir(dir, namelist, filter, compar);
    chdir(cwd);
    return res;
}

#endif /* !__GLIBC__ */

#endif /* MUSL_HOOKS_COMPAT_H */

#include <errno.h>

#ifndef TEMP_FAILURE_RETRY
#define TEMP_FAILURE_RETRY(exp) ({         \
    __typeof__(exp) _rc;                   \
    do {                                   \
        _rc = (exp);                       \
    } while (_rc == -1 && errno == EINTR); \
    _rc; })
#endif

#ifndef __GLIBC__
#define __vsprintf_chk(s, flag, slen, format, args) vsprintf(s, format, args)
#define __vsnprintf_chk(s, n, flag, slen, format, args) vsnprintf(s, n, format, args)
#endif
