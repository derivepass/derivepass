#ifndef SRC_UTIL_H_
#define SRC_UTIL_H_

#include <stdint.h>
#include <stdlib.h>

static void base64_encode(const uint8_t* src, size_t slen, char* dst) {
  unsigned a;
  unsigned b;
  unsigned c;
  unsigned i;
  unsigned k;
  unsigned n;

  static const char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                              "abcdefghijklmnopqrstuvwxyz"
                              "0123456789_.";

  i = 0;
  k = 0;
  n = (unsigned) ((slen / 3) * 3);

  while (i < n) {
    a = src[i + 0] & 0xff;
    b = src[i + 1] & 0xff;
    c = src[i + 2] & 0xff;

    dst[k + 0] = table[a >> 2];
    dst[k + 1] = table[((a & 3) << 4) | (b >> 4)];
    dst[k + 2] = table[((b & 0x0f) << 2) | (c >> 6)];
    dst[k + 3] = table[c & 0x3f];

    i += 3;
    k += 4;
  }
}

#endif  /* SRC_UTIL_H_ */
