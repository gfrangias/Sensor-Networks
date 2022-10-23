#include <gmp.h>
#include <openssl/sha.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

unsigned char Kinit[32];

mpz_t K;
mpz_t K_Inverse;
mpz_t prime;

int N = 4;
mpz_t keys[4];
unsigned long int values[4];

//#define SHA256_DIGEST_LENGTH 32

int result;
mpz_t resultEnc;
mpz_t val1, nodeEnc;

void sha256(char *string, char outputBuffer[65])
{
    unsigned char hash[SHA256_DIGEST_LENGTH];
    SHA256_CTX sha256;
    SHA256_Init(&sha256);
    SHA256_Update(&sha256, string, strlen(string));
    SHA256_Final(hash, &sha256);
    int i = 0;
    for(i = 0; i < SHA256_DIGEST_LENGTH; i++)
    {
        sprintf(outputBuffer + (i * 2), "%02x", hash[i]);
    }
    outputBuffer[64] = 0;
}

void hashAndPrint(mpz_t *K, char *buffer) {
  char output[65];
  char *ptr;

  sha256(buffer, output); 
  mpz_init_set_str (*K, output, 16);
  printf("Key in hex: %s\n", output);
  ptr = mpz_get_str(NULL, 10, *K);
  printf("Key in decimal: %s\n", ptr);
  free(ptr);

  // now see how a secret share would look like
  unsigned char sha1hash[SHA_DIGEST_LENGTH];
  SHA1((unsigned char *)output, sizeof(output), sha1hash);
  printf("Secret share: %s\n", sha1hash);
}

int main() {
  int i, j;

  char buffer[32];

  // compute the prime to use
  mpz_init_set_str(prime, "2", 10);
  mpz_pow_ui(prime, prime, 255);
  mpz_nextprime(prime, prime); 
  char *ptr = mpz_get_str(NULL, 10, prime);
  printf("prime in decimal: %s\n", ptr);
  free(ptr);
  // end of prime computation

  sprintf(buffer, "Global key");
  hashAndPrint(&K, buffer); // create and print key K
  
  for (i = 0; i < N; i++) {
    sprintf(buffer, "Local key for node %d", i);
    hashAndPrint(keys + i, buffer); // create and print local keys 
  }

  int sameResult = 0; // count how many times the encrypted result
                      // is the same as the actual one
  for (j = 0; j < 100; j++) {
    result = 0;
    mpz_init(resultEnc);

    printf("Values of nodes:");
    for (i = 0; i < N; i++) {
      values[i] = random() % 100; // generate random values
      printf(" %lu", values[i]);
      result += values[i];
      mpz_init_set_ui(val1, values[i]);
      mpz_mul(nodeEnc, val1, K);
      mpz_add(nodeEnc, nodeEnc, keys[i]);
      mpz_mod(nodeEnc, nodeEnc, prime);
      mpz_add(resultEnc, resultEnc, nodeEnc);  
    }
    printf("\nResult = %d\n", result);
    for (i = 0; i < N; i++) 
      mpz_sub(resultEnc, resultEnc, keys[i]);  
   
    mpz_invert(K_Inverse, K, prime);

    mpz_mul(resultEnc, resultEnc, K_Inverse);
    mpz_mod(resultEnc, resultEnc, prime);

    // look for other get functions in your application!
    // or try to pick some bits using bitwise AND
    unsigned long int convertedResult = mpz_get_ui(resultEnc);

    printf("Correct result = %d and computed = %ld\n", 
            result, convertedResult);
    if (convertedResult == result)
      sameResult++;
  }
  printf("Same result = %d out of 100 times\n", sameResult);
  return 1;
} 
