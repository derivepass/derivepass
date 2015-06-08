#ifndef SRC_COMMON_H_
#define SRC_COMMON_H_

#include "scrypt.h"

static const int kDeriveScryptN = 32768;
static const int kDeriveScryptR = 8;
static const int kDeriveScryptP = 4;


char* derive(scrypt_state_t* state, const char* secret, const char* domain);

#endif  /* SRC_COMMON_H_ */
