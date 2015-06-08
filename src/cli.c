#include <assert.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>

#include "scrypt.h"

#include "src/util.h"
#include "src/version.h"


static const int kDeriveScryptN = 1024;
static const int kDeriveScryptR = 8;
static const int kDeriveScryptP = 4;


static const char long_flags[] = "d:n:r:p:hv";
static struct option long_options[] = {
  { "help", 0, NULL, 'h' },
  { "version", 0, NULL, 'v' },
  { "domain", 1, NULL, 'd' },
  { "n", 1, NULL, 'n' },
  { "r", 1, NULL, 'r' },
  { "p", 1, NULL, 'p' },
  { NULL, 0, NULL, 0 }
};


static void print_version() {
  fprintf(stdout,
          "v%d.%d.%d\n",
          DERIVEPASS_VERSION_MAJOR,
          DERIVEPASS_VERSION_MINOR,
          DERIVEPASS_VERSION_PATCH);
}


static void print_help(int argc, char** argv) {
  fprintf(stdout, "Usage: %s [options]\n\n", argv[0]);
  fprintf(stdout, "options:\n");
  fprintf(stdout, "  --version, -v              Print version\n");
  fprintf(stdout,
          "  --domain host, -d host     Use domain for KDF (required)\n");
  fprintf(stdout,
          "  -n <num>                   N number for scrypt (default: 1024)\n");
  fprintf(stdout,
          "  -r <num>                   R number for scrypt (default: 8)\n");
  fprintf(stdout,
          "  -p <num>                   P number for scrypt (default: 4)\n");
  fprintf(stdout, "\n");
}


static char* derive(scrypt_state_t* state,
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


int main(int argc, char** argv) {
  char* secret;
  char* domain;
  char* output;
  int c;
  scrypt_state_t state;

  state.n = kDeriveScryptN;
  state.r = kDeriveScryptR;
  state.p = kDeriveScryptP;
  domain = NULL;

  do {
    c = getopt_long(argc, argv, long_flags, long_options, NULL);
    switch (c) {
      case 'v':
        print_version();
        exit(0);
        break;
      case 'd':
        domain = optarg;
        break;
      case 'n':
      case 'r':
      case 'p':
        {
          int val;

          val = atoi(optarg);
          if (c == 'n')
            state.n = val;
          else if (c == 'r')
            state.r = val;
          else
            state.p = val;

          break;
        }
      default:
        if (domain != NULL)
          break;

        print_help(argc, argv);
        exit(0);
        break;
    }
  } while (c != -1);

  secret = getpass("Secret: ");

  output = derive(&state, secret, domain);
  assert(output != NULL);

  fprintf(stdout, "%s\n", output);

  free(secret);
  free(output);

  return 0;
}
