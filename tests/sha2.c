#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#include "KritiC/kritic.h"

#include "sha2.h"

KRITIC_TEST(sha2, sha256_partial_block) {
    uint8_t digest[32];
    uint8_t data[] = "abc";
    uint8_t expected[] = {
        0xba, 0x78, 0x16, 0xbf, 0x8f, 0x01, 0xcf, 0xea,
        0x41, 0x41, 0x40, 0xde, 0x5d, 0xae, 0x22, 0x23,
        0xb0, 0x03, 0x61, 0xa3, 0x96, 0x17, 0x7a, 0x9c,
        0xb4, 0x10, 0xff, 0x61, 0xf2, 0x00, 0x15, 0xad
    };

    libcrypto_sha256(data, sizeof(data) - 1, digest);    
    KRITIC_ASSERT(memcmp(digest, expected, 32) == 0);
}

KRITIC_TEST(sha2, sha256_chained_partial_blocks) {
    uint8_t digest[32];
    uint8_t data[] = "abcdefghabcdefghabcdefghabcdefghabcdefghabcdefghabcdefgh";
    uint8_t expected[] = {
        0x8a, 0x26, 0x17, 0x44, 0xce, 0x59, 0x5c, 0x50,
        0x43, 0x1d, 0x19, 0xc6, 0xd4, 0xf6, 0x8e, 0xd2,
        0x49, 0x95, 0xed, 0x11, 0xf7, 0xe1, 0xd8, 0x8f,
        0xe3, 0x53, 0x60, 0x8f, 0x06, 0x55, 0xee, 0x53
    };

    libcrypto_sha256(data, sizeof(data) - 1, digest);
    KRITIC_ASSERT(memcmp(digest, expected, 32) == 0);
}

KRITIC_TEST(sha2, sha256_full_blocks) {
    uint8_t digest[32];
    uint8_t data[] = "abcdefghabcdefghabcdefghabcdefghabcdefghabcdefghabcdefghabcdefghabcdefghabcdefghabcdefghabcdefghabcdefghabcdefghabcdefghabcdefghabcdefghabcdefghabcdefghabcdefghabcdefghabcdefghabcdefghabcdefgh";
    uint8_t expected[] = {
        0x96, 0xbf, 0x20, 0xd8, 0x82, 0x41, 0xae, 0x9e,
        0x6a, 0x29, 0x9d, 0x02, 0x8f, 0x6a, 0x65, 0x41,
        0xd6, 0x44, 0xf3, 0xb8, 0x34, 0x4b, 0x33, 0x17,
        0x8f, 0x7d, 0x2b, 0x30, 0x9e, 0x15, 0x72, 0x29
    };

    libcrypto_sha256(data, sizeof(data) - 1, digest);
    KRITIC_ASSERT(memcmp(digest, expected, 32) == 0);
}

KRITIC_TEST(sha2, sha256_full_and_partial_blocks) {
    uint8_t digest[32];
    uint8_t data[] =
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. "
        "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. "
        "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. "
        "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";

    uint8_t expected[] = {
        0x2d, 0x8c, 0x2f, 0x6d, 0x97, 0x8c, 0xa2, 0x17,
        0x12, 0xb5, 0xf6, 0xde, 0x36, 0xc9, 0xd3, 0x1f,
        0xa8, 0xe9, 0x6a, 0x4f, 0xa5, 0xd8, 0xff, 0x8b,
        0x01, 0x88, 0xdf, 0xb9, 0xe7, 0xc1, 0x71, 0xbb
    };

    libcrypto_sha256(data, sizeof(data) - 1, digest);
    KRITIC_ASSERT(memcmp(digest, expected, 32) == 0);
}
