#include <assert.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>

#include "scrypt.h"
#include "derivepass.h"

#include "src/util.h"
#include "src/version.h"


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
  fprintf(
      stdout,
      "  -n <num>                   N number for scrypt (default: 32768)\n");
  fprintf(stdout,
          "  -r <num>                   R number for scrypt (default: 8)\n");
  fprintf(stdout,
          "  -p <num>                   P number for scrypt (default: 4)\n");
  fprintf(stdout, "\n");
}


int main(int argc, char** argv) {
  char* secret;
  char* secret_check;
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

  secret = strdup(getpass("Secret: "));
  secret_check = strdup(getpass("Secret (just checking): "));
  if (strcmp(secret, secret_check) != 0) {
    memset(secret, 0, strlen(secret));
    memset(secret_check, 0, strlen(secret_check));
    fprintf(stderr, "Secrets do not match\n");
    return 1;
  }
  memset(secret_check, 0, strlen(secret_check));
  free(secret_check);

  output = derive(&state, secret, domain);
  memset(secret, 0, strlen(secret));
  assert(output != NULL);

  fprintf(stdout, "%s\n", output);

  free(secret);
  free(output);

  return 0;
}
