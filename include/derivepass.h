#ifndef SRC_DERIVEPASS_H_
#define SRC_DERIVEPASS_H_
#ifdef __cplusplus
extern "C" {
#endif

#include "scrypt.h"

static const int kDeriveScryptN = 32768;
static const int kDeriveScryptR = 8;
static const int kDeriveScryptP = 4;


char* derive(scrypt_state_t* state, const char* secret, const char* domain);

#ifdef __cplusplus
}
#endif
#endif  /* SRC_DERIVEPASS_H_ */
