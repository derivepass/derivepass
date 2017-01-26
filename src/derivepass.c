#include <assert.h>
#include <string.h>

#include "derivepass.h"
#include "src/util.h"

char* derive(scrypt_state_t* state,
             const char* secret,
             const char* domain) {
  uint8_t out[18];
  char base_out[24];
  int err;

  err = scrypt_state_init(state);
  assert(err == 0);

  scrypt(state,
         (const uint8_t*) secret,
         strlen(secret),
         (const uint8_t*) domain,
         strlen(domain),
         out,
         sizeof(out));
  scrypt_state_destroy(state);

  base64_encode(out, sizeof(out), base_out);

  return strndup(base_out, sizeof(base_out));
}
