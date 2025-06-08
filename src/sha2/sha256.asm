; ============================================= ;
;  > sha256.asm                                 ;
; --------------------------------------------- ;
;                                               ;
;  SHA-256 hash implementation using SHA-NI     ;
;  instructions.                                ;
;                                               ;
;  Author(s)  : Lucas Hufnagel                  ;
;               Mark Devenyi                    ;
;  Created    : 21 Feb 2025                     ;
;  Updated    :  7 Jun 2025                     ;
;  Version    : 1.0.0                           ;
;  License    : MIT                             ;
;  Libraries  : None                            ;
;  Target     : Any                             ;
;  ABI used   : System V                        ;
;  Arch       : x64/AMD64                       ;
;  Extensions : SHA-NI                          ;
;  CPU(s)     : Intel Goldmont                  ;
;               AMD Zen                         ;
;                                               ;
; --------------------------------------------- ;
;                                               ;
;  Exports:                                     ;
;   > [F] libcrypto_sha256                      ;
;                                               ;
; ============================================= ;

%include "include/utils.inc"
%include "src/sha2/sha256_sse_mask_table.inc"

; ===== MACROS ===== ;
; Keeps track of current round (from 0 to 11)
%assign             round 0

; Assumptions:
;  - Used for round < 4 (t < 16)
;  - xmm15 contains shuffle mask
; Effects:
;  - Changes %1
; Arguments:
;  - register: rotating register
%macro shani_shuffle 1
    pshufb          %1, xmm15
    shani_round     %1

    %assign         round round + 1
%endmacro

; Assumptions:
;  - Used for round > 3 (t > 15)
; Effects:
;  - Changes xmm8 and %1
; Arguments:
;  - register: 1st rotating register
;  - register: 2nd rotating register
;  - register: 3rd rotating register
;  - register; 4th rotating register
%macro shani_update 4
    sha256msg1      %1, %2
	movdqu	        xmm8, %4
	palignr	        xmm8, %3, 4
	paddd	        %1, xmm8
	sha256msg2      %1, %4
    shani_round     %1

    %assign         round round + 1
%endmacro

; Effects:
;  - Changes xmm0, xmm1, xmm2
; Arguments:
;  - register: rotating register
%macro shani_round 1
    movdqa          xmm0, %1
    paddd           xmm0, [rel k + 16 * round]
    sha256rnds2     xmm2, xmm1, xmm0
    punpckhqdq      xmm0, xmm0
    sha256rnds2     xmm1, xmm2, xmm0
%endmacro

align 16
section .data
    ; Hash constants (order 0,1,4,5; 2,3,6,7)
    h               dd 0x9b05688c, 0x510e527f, 0xbb67ae85, 0x6a09e667
                    dd 0x5be0cd19, 0x1f83d9ab, 0xa54ff53a, 0x3c6ef372
    ; Round constants
    k               dd 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, \
                       0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, \
                       0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da, \
                       0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, \
                       0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, \
                       0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, \
                       0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3, \
                       0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    ; Block shuffle mask
    shufmask        db 3, 2, 1, 0, 7, 6, 5, 4, 11, 10, 9, 8, 15, 14, 13, 12
    shufmask_digest db 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0
    term_byte       dw 0x0080

section .text
; ============================================= ;
;  > libcrypto_sha256                           ;
; --------------------------------------------- ;
;                                               ;
;  Hashes the input data using SHA-256 and      ;
;  stores the result in the digest.             ;
;                                               ;
;  Author(s)  : Mark Devenyi                    ;
;  Created    : 29 May 2025                     ;
;  Updated    :  7 Jun 2025                     ;
;  Extensions : SHA-NI                          ;
;  Libraries  : None                            ;
;  Target     : Any                             ;
;  ABI used   : System V                        ;
;  Arch       : x64/AMD64                       ;
;                                               ;
; --------------------------------------------- ;
;                                               ;
;  Scope      : Global                          ;
;  Effects    : Changes digest[]                ;
;                                               ;
;  Returns:                                     ;
;   void                                        ;
;                                               ;
;  Arguments:                                   ;
;   > RDI - uint8_t* data[]                     ;
;   > RSI - size_t length                       ;
;   > RDX - uint8_t* digest[32]                 ;
;                                               ;
; ============================================= ;

global libcrypto_sha256
libcrypto_sha256:
    prolog          0, 0

    ; Set up hash state
    movdqa          xmm11, [rel h]
    movdqa          xmm12, [rel h + 16]

    ; Load byte shuffle mask
    movdqa          xmm15, [rel shufmask]

    ; Set partial block flag
    lea             r10, [1024]

    ; Calculate amount of full blocks
    mov             rcx, rsi
    shr             rcx, 6
    jnz             .block_load

.process_partial_block:
    mov             r8, rsi
    and             r8, 63

    ; TODO: Add non-PIE macro
    mov             rax, r8
    shl             rax, 8
    lea             r9, [rel mask_table_begin]
    add             r9, rax

    ; Zero out xmm-s
    pxor            xmm3, xmm3
    pxor            xmm4, xmm4
    pxor            xmm5, xmm5
    pxor            xmm6, xmm6

    ; Masked load (black magic)
    movdqa          xmm0, [r9]
    vpmaskmovd      xmm3, xmm0, [rdi]
    movdqa          xmm0, [r9 + MASK_LENGTH]
    vpmaskmovd      xmm4, xmm0, [rdi + 16]
    movdqa          xmm0, [r9 + 2 * MASK_LENGTH]
    vpmaskmovd      xmm5, xmm0, [rdi + 32]
    movdqa          xmm0, [r9 + 3 * MASK_LENGTH]
    vpmaskmovd      xmm6, xmm0, [rdi + 48]

    ; Merge the terminator and residual cleanup bytes
    movdqa          xmm0, [r9 + 4 * MASK_LENGTH]
    test            rsi, rsi
    cmovnz          ax, [rel term_byte]
    pxor            xmm9, xmm9
    pinsrb          xmm9, al, 0
    pshufb          xmm9, xmm0

    ; Add terminator byte (0x80) and clean up residual bytes
    movdqa          xmm0, [r9 + 5 * MASK_LENGTH]
    pblendvb        xmm3, xmm9, xmm0
    movdqa          xmm0, [r9 + 6 * MASK_LENGTH]
    pblendvb        xmm4, xmm9, xmm0
    movdqa          xmm0, [r9 + 7 * MASK_LENGTH]
    pblendvb        xmm5, xmm9, xmm0
    movdqa          xmm0, [r9 + 8 * MASK_LENGTH]
    pblendvb        xmm6, xmm9, xmm0

    ; Partial block that will need another partial block
    inc             rcx
    test            rsi, rsi
    cmovnz          r10, rsi
    xor             rsi, rsi
    cmp             r8, 56
    jge             .reset_state_regs

    ; Insert length
    lea             rax, [8 * r10]
    bswap           rax
    pinsrq          xmm6, rax, 1

    ; Set loop break conditions
    xor             r10, r10
    jmp             .reset_state_regs

.block_load:

    ; Load full block
    movdqa          xmm3, [rdi + 16 * 0]
    movdqa          xmm4, [rdi + 16 * 1]
    movdqa          xmm5, [rdi + 16 * 2]
    movdqa          xmm6, [rdi + 16 * 3]

.reset_state_regs:

    movdqa          xmm1, xmm11
    movdqa          xmm2, xmm12

.block_shuffle:

    shani_shuffle   xmm3
    shani_shuffle   xmm4
    shani_shuffle   xmm5
    shani_shuffle   xmm6

.block_loop:

    shani_update    xmm3, xmm4, xmm5, xmm6
    shani_update    xmm4, xmm5, xmm6, xmm3
    shani_update    xmm5, xmm6, xmm3, xmm4
    shani_update    xmm6, xmm3, xmm4, xmm5

    shani_update    xmm3, xmm4, xmm5, xmm6
    shani_update    xmm4, xmm5, xmm6, xmm3
    shani_update    xmm5, xmm6, xmm3, xmm4
    shani_update    xmm6, xmm3, xmm4, xmm5

    shani_update    xmm3, xmm4, xmm5, xmm6
    shani_update    xmm4, xmm5, xmm6, xmm3
    shani_update    xmm5, xmm6, xmm3, xmm4
    shani_update    xmm6, xmm3, xmm4, xmm5

    ; Calculate intermediate hash
    paddd           xmm11, xmm1
    paddd           xmm12, xmm2

    add             rdi, 64
    dec             rcx
    jnz             .block_load
    test            r10, r10
    jnz             .process_partial_block

    ; Format and set digest message
    movdqa          xmm15, [rel shufmask_digest]
    pshufb          xmm11, xmm15
    pshufb          xmm12, xmm15
    pextrq          rdi, xmm11, 1
    pextrq          rsi, xmm12, 0
    pinsrq          xmm12, rdi, 0
    pinsrq          xmm11, rsi, 1
    movdqu          [rdx], xmm11
    movdqu          [rdx + 16], xmm12

    epilog
    ret
