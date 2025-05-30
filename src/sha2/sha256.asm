section .data
    ; Temporary input, fix later
    input           db 'asdf', 0

    ; Hash constants
    h               dd 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    ; Round constants
    k               dd 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, \
                       0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, \
                       0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da, \
                       0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, \
                       0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, \
                       0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, \
                       0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3, \
                       0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2

    ; Byte swap mask
    be_mask         db 3,2,1,0, 7,6,5,4, 11,10,9,8, 15,14,13,12

section .bss
    msg             resb 64
    len_bits        resq 1
    schd            resb 256

    
section .text
_start:
    ; Temporary message
    mov             rdi, input
    ; Begins by unloading 512 bits of msg, more repetitions
    call            unload

    call            main_loop

    call            exit


unload:
    ; Add checks for presence of message later, message assumed to be on stack at program start for now
    call            find_len

    call            pad

    ret

find_len:
    xor             rcx, rcx
    jmp             len_loop

len_loop:
    mov             al, byte [rdi + rcx]
    cmp             al, 0
    je              fin_len
    inc             rcx
    jmp             len_loop

fin_len:
    mov             rax, rcx
    ; Sha uses bit len
    shl             rax, 3
    mov             [rel len_bits], rax
    mov             rbx, rcx
    ret


pad:
    mov             rsi, msg
    mov             rcx, rbx
    jmp             copy_loop


; Sha is Big Endian for some reason
copy_loop:
    cmp             rcx, 0
    je              done_copy
    mov             al, [rdi]
    mov             [rsi], al
    inc             rdi 
    inc             rsi
    dec             rcx
    jmp             copy_loop

done_copy:
    mov             byte [rsi], 0x80
    inc             rsi

    mov             rax, rbx
    add             rax, 1
    cmp             rax, 56
    ja              full_block

    mov             rcx, 56
    sub             rcx, rax
    jmp             fill_zero

fill_zero:
    cmp             rcx, 0
    je              write_len
    mov             byte [rsi], 0x00
    inc             rsi
    dec             rcx
    jmp             fill_zero

full_block:
    mov             rcx, 64
    sub             rcx, rax

fill_block:
    cmp             rcx, 0
    je              second_block
    mov             byte [rsi], 0x00
    inc             rsi
    dec             rcx
    jmp             fill_block

second_block:
    mov             rcx, 64

fill_b2:
    cmp             rcx, 0
    je              write_len
    mov             byte [rsi], 0x00
    inc             rsi
    dec             rcx
    jmp             fill_b2

write_len:
    mov             rax, [rel len_bits]
    mov             rcx, 8

write_len_loop:
    mov             rdx, rax
    shr             rdx, 56
    mov             byte [rsi], dl
    shl             rax, 8
    inc             rsi
    dec             rcx
    jnz             write_len_loop
    ret

copy_len:
    mov             rsi, msg + 56
    mov             rax, [rel len_bits]
    jmp             copy_loop
    mov             rcx, 8

main_loop:
    ; Initial hash state as the hash values
    movdqu          xmm1, [rel h +  0]
    movdqu          xmm2, [rel h +  8]
    movdqu          xmm3, [rel h + 16]
    movdqu          xmm4, [rel h + 24]

    movdqu          xmm5, [rel msg]
    movdqu          xmm6, [rel msg + 16]
    movdqu          xmm7, [rel msg + 32]
    movdqu          xmm8, [rel msg + 48]

    movdqu          xmm15, [rel be_mask]
    pshufb          xmm5, xmm15
    pshufb          xmm6, xmm15
    pshufb          xmm7, xmm15
    pshufb          xmm8, xmm15

    movdqu          [rel schd], xmm1
    movdqu          [rel schd + 16], xmm2
    movdqu          [rel schd + 32], xmm3
    movdqu          [rel schd + 48], xmm4

    xor             ecx, ecx

loop_schd:
    ; Wt
    ; TODO: needed for PIE binaries only, disable on no-PIE
    lea             rax, [rel schd]
    movdqu          xmm0, [rax + rcx*4]

    ; Kt
    ; TODO: needed for PIE binaries only, disable on no-PIE
    lea             rax, [rel schd]
    movdqu          xmm9, [rax + rcx*4]

    sha256rnds2     xmm1, xmm3, xmm0
    sha256rnds2     xmm2, xmm4, xmm0

    add             ecx, 4
    cmp             ecx, 64
    jl              loop_schd_ext

    jmp             fin_update

loop_schd_ext:
    ; Wt changes from values 16-63
    ; TODO: needed for PIE binaries only, disable on no-PIE
    lea             rax, [rel schd]
    movdqu          xmm10, [rax + (rcx-16)*4]
    movdqu          xmm11, [rax + (rcx-15)*4]
    movdqu          xmm12, [rax + (rcx-7)*4]
    movdqu          xmm13, [rax + (rcx-2)*4]

    sha256msg1      xmm11, xmm10
    sha256msg2      xmm13, xmm12

    paddd           xmm13, xmm11

    ; Store new Wt
    ; TODO: needed for PIE binaries only, disable on no-PIE
    lea             rax, [rel schd]
    movdqu          [rax + rcx*4], xmm13
    jmp             loop_schd

fin_update:
    movdqu          xmm0, [rel h + 0]
    movdqu          xmm9, [rel h + 16]

    paddd           xmm1, xmm0
    paddd           xmm2, xmm9

    movdqu          [rel h + 0], xmm1
    movdqu          [rel h + 16], xmm2

    ret

; TODO: Fix this
exit: 
    mov             rax, 60
    xor             rdi, rdi
    syscall
