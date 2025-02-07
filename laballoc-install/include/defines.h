/**
 * @file
 * @brief Defines for memory allocation
 */
#ifndef ALLOC_DEFINES_H
#define ALLOC_DEFINES_H

#include "include/types.h"
#include "include/utils.h"
#include <math.h>
#include <stdint.h>

//! Macro for LD_PRELOAD asserts because normal assert somehow don't work
#define ASSERT(expr)                                                           \
    if (!(expr)) {                                                             \
        a_abort(__FILE__, __LINE__, #expr);                                    \
    }

#endif
