;=======================================================================
; EXPERIMENT 5 : FACTORIAL, SQUARE, BRANCH AND SUBROUTINE OPERATIONS
;                USING 8086 MICROPROCESSOR
; Processor    : 8086
; Simulator    : EMU8086  /  MASM or TASM under DOSBox
;
; AIM : To write and verify 8086 ALPs for
;       (a) Factorial of a number - iterative subroutine (32-bit result)
;       (b) Factorial of a number - recursive subroutine (stack based)
;       (c) Square of a number using MUL
;       (d) Square using successive addition of odd numbers
;       (e) Table of squares of 1..10 and sum of squares
;           (nested subroutine calls)
;       (f) Branching : compare two numbers, largest of three,
;           even/odd, positive/negative/zero, GCD of two numbers
;       (g) Parameter passing to a subroutine through the stack
;=======================================================================
.MODEL SMALL
.STACK 200h

;----------------------------- MACROS ---------------------------------
PRINT MACRO MSG
        PUSH AX
        PUSH DX
        LEA  DX, MSG
        MOV  AH, 09h
        INT  21h
        POP  DX
        POP  AX
ENDM

;------------------------------ DATA ----------------------------------
.DATA
N_IT    DW 10                   ; for iterative factorial  (10! )
N_REC   DW 7                    ; for recursive factorial  ( 7! )
N_SQ    DW 25                   ; for square
N_ODD   DW 12                   ; square by odd-number addition
NUM_A   DW 1234h
NUM_B   DW 0ABCDh
X1      DB 47
X2      DB 92
X3      DB 65
SNUM    DB 0F6h                 ; -10 (signed) for pos/neg/zero test
EONUM   DB 37
G1      DW 48
G2      DW 18
P1      DW 1500                 ; parameters passed through stack
P2      DW 2700

;--------- RESULT AREA ---------
FACT_H  DW ?                    ; 10! = 0037 5F00h = 3628800
FACT_L  DW ?
FACTR   DW ?                    ;  7! = 13B0h = 5040
SQR     DW ?                    ; 25^2 = 0271h = 625
SQR2    DW ?                    ; 12^2 = 0090h = 144
SQTAB   DW 10 DUP(?)            ; 1,4,9,...,100
SQSUM   DW ?                    ; 385
LARGE3  DB ?
GCDRES  DW ?
STKSUM  DW ?

;--------- MESSAGES ---------
TITLE1  DB 0Dh,0Ah,'===== EXP 5 : FACTORIAL, SQUARE, BRANCH & SUBROUTINE =====$'
HSUF    DB 'h$'
SPACE   DB ' $'
EQD     DB 'h  = $'
DECS    DB ' (decimal)$'
MA      DB 0Dh,0Ah,0Dh,0Ah,'(a) 10! (iterative)  = $'
MB      DB 0Dh,0Ah,'(b)  7! (recursive)  = $'
MC      DB 0Dh,0Ah,'(c) Square of 25     = $'
MD      DB 0Dh,0Ah,'(d) 12^2 = 1+3+5+..+23 = $'
ME      DB 0Dh,0Ah,'(e) Squares of 1..10 : $'
ME2     DB 0Dh,0Ah,'    Sum of squares   = $'
MF      DB 0Dh,0Ah,0Dh,0Ah,'(f) BRANCHING$'
MF1     DB 0Dh,0Ah,'    1234h vs ABCDh (unsigned): $'
MF1B    DB 0Dh,0Ah,'    1234h vs ABCDh (signed)  : $'
M_GT    DB 'first is GREATER$'
M_LT    DB 'first is SMALLER$'
M_EQ    DB 'both are EQUAL$'
MF2     DB 0Dh,0Ah,'    Largest of 47, 92, 65    = $'
MF3     DB 0Dh,0Ah,'    37 is $'
M_EVEN  DB 'EVEN$'
M_ODD   DB 'ODD$'
MF4     DB 0Dh,0Ah,'    F6h (signed) is $'
M_POS   DB 'POSITIVE$'
M_NEG   DB 'NEGATIVE$'
M_ZERO  DB 'ZERO$'
MF5     DB 0Dh,0Ah,'    GCD(48, 18)              = $'
MG      DB 0Dh,0Ah,0Dh,0Ah,'(g) Stack parameters : 1500 + 2700 = $'
DONE    DB 0Dh,0Ah,0Dh,0Ah,'Program completed.',0Dh,0Ah,'$'

;------------------------------ CODE ----------------------------------
.CODE
MAIN PROC
        MOV  AX, @DATA
        MOV  DS, AX
        PRINT TITLE1

;================ (a) ITERATIVE FACTORIAL (32-bit) ====================
        MOV  CX, N_IT
        CALL FACT32             ; returns DX:AX = N!
        MOV  FACT_H, DX
        MOV  FACT_L, AX
        PRINT MA
        CALL PHEX32             ; hex
        PRINT EQD
        CALL PDEC32             ; decimal
        PRINT DECS

;================ (b) RECURSIVE FACTORIAL =============================
        MOV  AX, N_REC
        PUSH AX                 ; pass N on the stack
        CALL FACTREC            ; AX = N!
        MOV  FACTR, AX
        PRINT MB
        CALL PHEX16
        PRINT EQD
        XOR  DX, DX
        CALL PDEC32

;================ (c) SQUARE USING MUL ================================
        MOV  AX, N_SQ
        CALL SQUARE             ; AX = AX * AX
        MOV  SQR, AX
        PRINT MC
        CALL PHEX16
        PRINT EQD
        XOR  DX, DX
        CALL PDEC32

;================ (d) SQUARE BY ADDING ODD NUMBERS ====================
; n^2 = 1 + 3 + 5 + ... + (2n-1)
        MOV  CX, N_ODD
        XOR  AX, AX             ; running sum
        MOV  BX, 1              ; first odd number
ODD_LP: ADD  AX, BX
        ADD  BX, 2
        LOOP ODD_LP
        MOV  SQR2, AX
        PRINT MD
        CALL PHEX16
        PRINT EQD
        XOR  DX, DX
        CALL PDEC32

;================ (e) TABLE OF SQUARES + SUM (nested calls) ===========
        CALL SQTABLE            ; SQTABLE itself calls SQUARE
        PRINT ME
        LEA  SI, SQTAB
        MOV  CX, 10
PT_LP:  MOV  AX, [SI]
        XOR  DX, DX
        CALL PDEC32
        PRINT SPACE
        ADD  SI, 2
        LOOP PT_LP
        PRINT ME2
        MOV  AX, SQSUM
        XOR  DX, DX
        CALL PDEC32

;================ (f) BRANCHING =======================================
        PRINT MF
; --- unsigned compare : JA / JB / JE ---
        PRINT MF1
        MOV  AX, NUM_A
        CMP  AX, NUM_B
        JA   U_GT
        JB   U_LT
        PRINT M_EQ
        JMP  U_END
U_GT:   PRINT M_GT
        JMP  U_END
U_LT:   PRINT M_LT              ; 1234h < ABCDh (unsigned)
U_END:

; --- signed compare : JG / JL / JE ---
        PRINT MF1B
        MOV  AX, NUM_A
        CMP  AX, NUM_B
        JG   S_GT
        JL   S_LT
        PRINT M_EQ
        JMP  S_END
S_GT:   PRINT M_GT              ; +4660 > -21555 (signed)
        JMP  S_END
S_LT:   PRINT M_LT
S_END:

; --- largest of three numbers ---
        MOV  AL, X1
        CMP  AL, X2
        JAE  L_A
        MOV  AL, X2
L_A:    CMP  AL, X3
        JAE  L_B
        MOV  AL, X3
L_B:    MOV  LARGE3, AL         ; 92
        PRINT MF2
        MOV  AL, LARGE3
        XOR  AH, AH
        XOR  DX, DX
        CALL PDEC32

; --- even / odd ---
        PRINT MF3
        TEST EONUM, 01h
        JZ   IS_EVN
        PRINT M_ODD
        JMP  EO_END
IS_EVN: PRINT M_EVEN
EO_END:

; --- positive / negative / zero ---
        PRINT MF4
        MOV  AL, SNUM
        CMP  AL, 0
        JG   IS_POS
        JL   IS_NEG
        PRINT M_ZERO
        JMP  PN_END
IS_POS: PRINT M_POS
        JMP  PN_END
IS_NEG: PRINT M_NEG
PN_END:

; --- GCD by repeated subtraction (loop with conditional branch) ---
        MOV  AX, G1
        MOV  BX, G2
GCD_LP: CMP  AX, BX
        JE   GCD_OK
        JB   GCD_SW
        SUB  AX, BX             ; AX > BX : AX = AX - BX
        JMP  GCD_LP
GCD_SW: SUB  BX, AX             ; BX > AX : BX = BX - AX
        JMP  GCD_LP
GCD_OK: MOV  GCDRES, AX         ; 6
        PRINT MF5
        XOR  DX, DX
        CALL PDEC32

;================ (g) PARAMETER PASSING THROUGH STACK =================
        PUSH P1                 ; parameter 1
        PUSH P2                 ; parameter 2
        CALL ADDSTK             ; AX = P1 + P2 (callee cleans stack)
        MOV  STKSUM, AX         ; 4200
        PRINT MG
        XOR  DX, DX
        CALL PDEC32

        PRINT DONE
        MOV  AH, 4Ch
        INT  21h
MAIN ENDP

;=====================================================================
;                          SUBROUTINES
;=====================================================================
; FACT32 : CX = N (0..12)  ->  DX:AX = N!   (32-bit iterative)
FACT32 PROC
        PUSH BX
        PUSH SI
        PUSH DI
        MOV  AX, 1              ; DI:SI hold the running product
        XOR  DX, DX
        MOV  SI, AX
        MOV  DI, DX
        JCXZ F32_END            ; 0! = 1
F32_LP: MOV  AX, SI             ; low  word * CX
        MUL  CX
        MOV  SI, AX
        MOV  BX, DX             ; carry part
        MOV  AX, DI             ; high word * CX
        MUL  CX
        ADD  AX, BX
        MOV  DI, AX
        LOOP F32_LP
F32_END:
        MOV  AX, SI
        MOV  DX, DI
        POP  DI
        POP  SI
        POP  BX
        RET
FACT32 ENDP

; FACTREC : N passed on stack -> AX = N!   (recursive, N <= 8)
;           fact(n) = 1 if n <= 1 else n * fact(n-1)
FACTREC PROC
        PUSH BP
        MOV  BP, SP
        PUSH BX
        PUSH DX
        MOV  BX, [BP+4]         ; BX = n
        CMP  BX, 1
        JA   FR_REC
        MOV  AX, 1              ; base case
        JMP  FR_RET
FR_REC: MOV  AX, BX
        DEC  AX
        PUSH AX                 ; push n-1
        CALL FACTREC            ; AX = (n-1)!
        MUL  BX                 ; AX = n * (n-1)!
FR_RET: POP  DX
        POP  BX
        POP  BP
        RET  2                  ; remove the parameter
FACTREC ENDP

; SQUARE : AX = AX * AX  (DX destroyed)
SQUARE PROC
        MUL  AX
        RET
SQUARE ENDP

; SQTABLE : fills SQTAB with squares of 1..10 and SQSUM with their sum
SQTABLE PROC
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        LEA  SI, SQTAB
        MOV  CX, 1
        XOR  BX, BX             ; sum
ST_LP:  MOV  AX, CX
        CALL SQUARE             ; nested subroutine call
        MOV  [SI], AX
        ADD  BX, AX
        ADD  SI, 2
        INC  CX
        CMP  CX, 10
        JBE  ST_LP
        MOV  SQSUM, BX
        POP  SI
        POP  DX
        POP  CX
        POP  BX
        POP  AX
        RET
SQTABLE ENDP

; ADDSTK : two words on stack -> AX = sum
;   stack after PUSH BP : [BP+2]=return addr, [BP+4]=P2, [BP+6]=P1
ADDSTK PROC
        PUSH BP
        MOV  BP, SP
        MOV  AX, [BP+6]         ; P1
        ADD  AX, [BP+4]         ; + P2
        POP  BP
        RET  4                  ; return and discard 2 parameters
ADDSTK ENDP

;------------------------- HELPER ROUTINES ----------------------------
; PDEC32 : print DX:AX as unsigned decimal
PDEC32 PROC
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        MOV  BX, 10
        XOR  CX, CX             ; digit counter
PD_DIV: MOV  SI, AX             ; save low word
        MOV  AX, DX
        XOR  DX, DX
        DIV  BX                 ; high word / 10
        PUSH AX                 ; high quotient
        MOV  AX, SI
        DIV  BX                 ; (rem:low) / 10 -> AX low quotient, DX digit
        MOV  SI, DX             ; digit
        POP  DX                 ; DX:AX = quotient
        PUSH SI                 ; save digit
        INC  CX
        MOV  SI, AX
        OR   SI, DX
        JNZ  PD_DIV             ; until quotient = 0
PD_OUT: POP  DX
        ADD  DL, '0'
        MOV  AH, 02h
        INT  21h
        LOOP PD_OUT
        POP  SI
        POP  DX
        POP  CX
        POP  BX
        POP  AX
        RET
PDEC32 ENDP

; PHEX32 : print DX:AX in hex
PHEX32 PROC
        PUSH AX
        MOV  AX, DX
        CALL PHEX16
        POP  AX
        CALL PHEX16
        RET
PHEX32 ENDP

PHEX16 PROC
        PUSH AX
        XCHG AL, AH
        CALL PHEX8
        XCHG AL, AH
        CALL PHEX8
        POP  AX
        RET
PHEX16 ENDP

PHEX8 PROC
        PUSH AX
        PUSH CX
        PUSH DX
        MOV  DH, AL
        MOV  CL, 4
        SHR  AL, CL
        CALL PNIB
        MOV  AL, DH
        AND  AL, 0Fh
        CALL PNIB
        POP  DX
        POP  CX
        POP  AX
        RET
PHEX8 ENDP

PNIB PROC
        PUSH AX
        PUSH DX
        ADD  AL, '0'
        CMP  AL, '9'
        JBE  PN_OK
        ADD  AL, 7
PN_OK:  MOV  DL, AL
        MOV  AH, 02h
        INT  21h
        POP  DX
        POP  AX
        RET
PNIB ENDP

END MAIN
