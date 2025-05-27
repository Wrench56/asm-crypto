section .data
    ; Temporary input, fix later
    input db 'asdf', 0
    ; Initial hash values
    h    dd    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    ; Constants
    k    dd    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2

section    .bss
    msg    resb 64
    len_bits    resq 1
    
section    .text

_start:
    ; Temporary message
    mov    rdi, input
    ; Begins by unloading 512 bits of msg, more repetitions
    call   unload

    call   exit


unload:
    ; Add checks for presence of message later, message assumed to be on stack at program start for now
    call   find_len

    call   pad

    ret

find_len:
    xor    rcx, rcx
    jmp    len_loop

len_loop:
    mov    al, byte [rdi + rcx]
    cmp    al, 0
    je     fin_len
    inc    rcx
    jmp    len_loop

fin_len:
    mov    rax, rcx
    ; Sha uses bit len
    shl    rax, 3
    mov    [len_bits], rax
    mov    rbx, rcx
    ret


pad:
    mov    rsi, msg
    mov    rcx, rbx
    jmp    copy_loop


; Sha is Big Endian for some reason
copy_loop:
    cmp    rcx, 0
    je     done_copy
    mov    al, [rdi]
    mov    [rsi], al
    inc    rdi 
    inc    rsi
    dec    rcx
    jmp    copy_loop

done_copy:
    mov    byte [rsi], 0x80
    inc    rsi

    mov    rax, rbx
    add    rax, 1
    cmp    rax, 56
    ja     full_block

    mov    rcx, 56
    sub    rcx, rax
    jmp    fill_zero

fill_zero:
    cmp    rcx, 0
    je     write_len
    mov    byte [rsi], 0x00
    inc    rsi
    dec    rcx
    jmp    fill_zero

full_block:
    mov    rcx, 64
    sub    rcx, rax

fill_block:
    cmp    rcx, 0
    je     start_new
    mov    byte [rsi], 0x00
    inc    rsi
    dec    rcx
    jmp    fill_block

second_block:
    mov    rcx, 64

fill_b2:
    cmp    rcx, 0
    je     write_len
    mov    byte [rsi], 0x00
    inc    rsi
    dec    rcx
    jmp    fill_b2

write_len:
    mov    rax, [len_bits]
    mov    rcx, 8

write_len_loop:
    mov    rdx, rax
    shr    rdx, 56
    mov    byte [rsi], dl
    shl    rax, 8
    inc    rsi
    dec    rcx
    jnz    write_len_loop
    ret

copy_len:
    mov    rsi, msg + 56
    mov    rax, [len_bits]
    jmp    copy_loop
    mov    rcx, 8

; To be changed
exit: 
    mov   rax, 60
    xor   rdi, rdi
    syscall

