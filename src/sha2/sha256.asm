section .data
    ; Initial hash values
    h    dd    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    ; Constants
    k    dd    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2

section .bss
    msg    resb 64
    
section    .text

_start:
    ; Begins by unloading 512 bits of msg, more repetitions
    call unload


unload:
    ; Add checks for presence of message later, message assumed to be on stack at program start for now
    call   first_56

    call   copy_len

    call   exit

find_len:
    mov    al, byte [rdi + rbx]


first_56:
    ; Address of source buffer assumed in rdi
    pop    rdi
    mov    rsi, msg
    mov    rcx, 56
    jmp    copy_loop

copy_loop
    cmp    rcx, 0
    je     done
    mov    al, byte [rdi]
    mov    byte [rsi], al
    inc    rdi
    inc    rsi
    dec    rcx
    jmp    copy_loop

done:
    ret

copy_len:
    add    rdi, 56
    mov    rsi, msg + 56
    mov    rcx, 4
    jmp    copy_loop

; To be changed
exit: 
    mov   rax, 60
    xor   rdi, rdi
    syscall

