; ================================= ;
;  > utils.inc                      ;
; --------------------------------- ;
;  NASM utility macros and helpers  ;
;                                   ;
;  Author(s) : Mark Devenyi         ;
;  Created   : 21 Feb 2025          ;
;  Updated   :  2 Jun 2025          ;
;  License   : MIT                  ;
; ================================= ;

%xdefine __local_variable_pointer 0

; Arguments:
;  > 1: string - variable name
;  > 2: number - variable size
%ifnmacro deflocal
    %macro deflocal 2
        %ifidn TARGET_ABI, ABI_WINDOWS
            %xdefine %1 rsp + 32 + __local_variable_pointer
        %else
            %xdefine %1 rsp + __local_variable_pointer
        %endif

        %xdefine __temp_local_variable_pointer __local_variable_pointer
        %undef __local_variable_pointer
        %xdefine __local_variable_pointer __temp_local_variable_pointer + %2
        %undef __temp_local_variable_pointer
    %endmacro
%endif

; Arguments:
;  > 1: number - number of registers pushed
;  > 2: number - stack frame size
%ifnmacro prolog
    %macro prolog 2
        ; Check for concurrency issues
        %ifdef __stack_alignment
            %fatal Concurrency issue with assembler in "epilog" for "__stack_alignment"
        %endif
        %ifdef __stack_frame_size
            %fatal Concurrency issue with assembler in "epilog" for "__stack_frame_size"
        %endif

        %xdefine __stack_frame_size %2
        %xdefine __stack_alignment %cond(((%cond(((%1 % 2) == 0), 0, 8) + __stack_frame_size) % 16) == 0, 8, 0)

        %ifidn TARGET_ABI, ABI_WINDOWS
            sub rsp, 32 + __stack_frame_size + __stack_alignment
        %else
            %if __stack_frame_size == 0
                %if __stack_alignment == 8
                    push rax
                %endif
            %else
                sub rsp, __stack_frame_size + __stack_alignment
            %endif
        %endif
    %endmacro
%endif

%ifnmacro epilog
    %macro epilog 0
        ; Check for concurrency issues
        %ifndef __stack_alignment
            %fatal Concurrency issue with assembler in "epilog" for "__stack_alignment"
        %endif
        %ifndef __stack_frame_size
            %fatal Concurrency issue with assembler in "epilog" for "__stack_frame_size"
        %endif

        %ifidn TARGET_ABI, ABI_WINDOWS
            add rsp, 32 + __stack_frame_size + __stack_alignment
        %else
            %if __stack_frame_size == 0
                %if __stack_alignment == 8
                    pop rcx
                %endif
            %else
                add rsp, __stack_frame_size + __stack_alignment
            %endif
        %endif

        %undef __stack_alignment
        %undef __stack_frame_size
    %endmacro
%endif

; Arguments:
;  > 1: number - argument number
%ifidn TARGET_ABI, ABI_WINDOWS
    ; Windows x64 ABI
    %define __stack_arg(n) [rsp + 8 * (n + 3)]

    %define __arg1  rcx
    %define __arg2  rdx
    %define __arg3  r8
    %define __arg4  r9
    %define __arg5  __stack_arg(1)
    %define __arg6  __stack_arg(2)
    %define __arg7  __stack_arg(3)
    %define __arg8  __stack_arg(4)
    %define __arg9  __stack_arg(5)
    %define __arg10 __stack_arg(6)
    %define __arg11 __stack_arg(7)
    %define __arg12 __stack_arg(8)
    %define __arg13 __stack_arg(9)
    %define __arg14 __stack_arg(10)
    %define __arg15 __stack_arg(11)
    %define __arg16 __stack_arg(12)

%elifidn TARGET_ABI, ABI_SYSV
    ; System V AMD64 ABI
    %define __stack_arg(n) [rsp + 8 * n]

    %define __arg1  rdi
    %define __arg2  rsi
    %define __arg3  rdx
    %define __arg4  rcx
    %define __arg5  r8
    %define __arg6  r9
    %define __arg7  __stack_arg(1)
    %define __arg8  __stack_arg(2)
    %define __arg9  __stack_arg(3)
    %define __arg10 __stack_arg(4)
    %define __arg11 __stack_arg(5)
    %define __arg12 __stack_arg(6)
    %define __arg13 __stack_arg(7)
    %define __arg14 __stack_arg(8)
    %define __arg15 __stack_arg(9)
    %define __arg16 __stack_arg(10)

%else
    %error Unsupported output format
%endif

%define arg(n) __arg %+ n
