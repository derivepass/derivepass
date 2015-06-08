#ifndef SRC_UTIL_H_
#define SRC_UTIL_H_

#include <stdint.h>
#include <stdlib.h>

void base64_encode(const uint8_t* src, size_t slen, char* dst);

#endif  /* SRC_UTIL_H_ */
