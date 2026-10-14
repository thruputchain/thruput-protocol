/*
 * A line-oriented ML-DSA-65 oracle over mldsa-native, the library hogd
 * verifies with (hogd/external/mldsa-native). check_vectors.py drives it
 * with --mldsa-native to check the ML-DSA bytes in pubkey_auth.json with a
 * third implementation, including the deterministic signatures, which
 * pyca/cryptography cannot make.
 *
 * Build, from a checkout of mldsa-native v2.0.0:
 *
 *   cc -O2 -DMLD_CONFIG_PARAMETER_SET=65 -DMLD_CONFIG_NO_RANDOMIZED_API \
 *      -DMLD_CONFIG_NAMESPACE_PREFIX=oracle \
 *      -I<mldsa-native>/mldsa mldsa_native_oracle.c \
 *      <mldsa-native>/mldsa/mldsa_native.c -o mldsa_native_oracle
 *
 * Each input line is a command with hex arguments; each output line is the
 * answer in hex:
 *
 *   K <seed>             -> <public key>
 *   S <seed> <message>   -> <signature>  deterministic (rnd = 0), pure,
 *                                        empty context
 *   V <pk> <msg> <sig>   -> 1 if the signature verifies (pure, empty
 *                           context), else 0
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mldsa_native.h"

#define PK_BYTES MLDSA_PUBLICKEYBYTES(65)
#define SK_BYTES MLDSA_SECRETKEYBYTES(65)
#define SIG_BYTES MLDSA_BYTES(65)

/* FIPS 204 Algorithm 2 and 3 prefix for pure ML-DSA, empty context:
 * M' = 0x00 || len(ctx) || ctx || M. */
static const uint8_t kPrefix[2] = {0, 0};

static int
unhex(const char *s, uint8_t **out, size_t *len)
{
  size_t n = strlen(s);
  if (n % 2) {
    return -1;
  }
  *out = malloc(n / 2 + 1);
  for (size_t i = 0; i < n / 2; i++) {
    unsigned v;
    if (sscanf(s + 2 * i, "%2x", &v) != 1) {
      return -1;
    }
    (*out)[i] = (uint8_t)v;
  }
  *len = n / 2;
  return 0;
}

static void
puthex(const uint8_t *b, size_t n)
{
  for (size_t i = 0; i < n; i++) {
    printf("%02x", b[i]);
  }
  printf("\n");
}

static void
keypair(const uint8_t *seed, uint8_t pk[PK_BYTES], uint8_t sk[SK_BYTES])
{
  if (oracle_keypair_internal(pk, sk, seed) != 0) {
    fprintf(stderr, "keypair failed\n");
    exit(1);
  }
}

int
main(void)
{
  static char line[1 << 20];
  while (fgets(line, sizeof line, stdin)) {
    line[strcspn(line, "\r\n")] = 0;
    char *cmd = strtok(line, " ");
    if (!cmd) {
      continue;
    }
    uint8_t *a[3] = {0};
    size_t n[3] = {0};
    int argc = 0;
    for (char *t; argc < 3 && (t = strtok(NULL, " ")); argc++) {
      if (unhex(t, &a[argc], &n[argc]) != 0) {
        fprintf(stderr, "bad hex\n");
        return 1;
      }
    }
    static uint8_t pk[PK_BYTES], sk[SK_BYTES], sig[SIG_BYTES];
    if (!strcmp(cmd, "K") && argc == 1 && n[0] == MLDSA_SEEDBYTES) {
      keypair(a[0], pk, sk);
      puthex(pk, PK_BYTES);
    }
    else if (!strcmp(cmd, "S") && argc == 2 && n[0] == MLDSA_SEEDBYTES) {
      static const uint8_t rnd[MLDSA_RNDBYTES] = {0};
      keypair(a[0], pk, sk);
      if (oracle_signature_internal(sig, a[1], n[1], kPrefix, sizeof kPrefix,
                                    rnd, sk, 0) != 0) {
        fprintf(stderr, "sign failed\n");
        return 1;
      }
      puthex(sig, SIG_BYTES);
    }
    else if (!strcmp(cmd, "V") && argc == 3 && n[0] == PK_BYTES &&
             n[2] == SIG_BYTES) {
      int ok = oracle_verify_internal(a[2], a[1], n[1], kPrefix,
                                      sizeof kPrefix, a[0], 0) == 0;
      printf("%d\n", ok);
    }
    else {
      fprintf(stderr, "bad command\n");
      return 1;
    }
    fflush(stdout);
    for (int i = 0; i < 3; i++) {
      free(a[i]);
    }
  }
  return 0;
}
