;=======================================================================
; EXPERIMENT 7 : ARITHMETIC COPROCESSOR AND FLOATING-POINT COMPUTATION
;                USING 8086 / 8087  -  SIMULATION STUDY
; Processor    : 8086 + 8087 Numeric Data Processor (NDP)
; Simulator    : MASM / TASM under DOSBox (DOSBox emulates the FPU)
;                ** EMU8086 does NOT support 8087 instructions **
;
; AIM : To study the 8087 register stack ST(0)..ST(7) and write ALPs
;       for floating-point computation:
;       (a) Addition, subtraction, multiplication, division of reals
;       (b) Square root of an integer (FILD + FSQRT)
;       (c) Area of a circle  A = PI * r^2      (FLDPI)
;       (d) Hypotenuse  c = SQRT(a^2 + b^2)
;       (e) Average of an array of real numbers
;       (f) Celsius to Fahrenheit  F = C * 9 / 5 + 32
;       (g) Roots of a quadratic equation  ax^2 + bx + c = 0
;       (h) Comparison of two reals (FCOM, FSTSW, SAHF)
;       (i) Real -> integer conversion (FISTP, rounding)
;
; Data types : DD = 32-bit short real, DW = 16-bit word integer,
;              DD integer (for FISTP) = 32-bit short integer.
; Results are displayed with 4 decimal places.
;=======================================================================
.MODEL SMALL
.8087                           ; enable 8087 instruction set
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
NUMA    DD 12.75
NUMB    DD 4.25
IVAL    DW 625                  ; integer for square root
RADIUS  DD 7.5
SIDEA   DD 3.0
SIDEB   DD 4.0
FARR    DD 2.5, 3.75, 10.0, 6.25, 1.5
FCOUNT  DW 5
CELS    DD 37.0
NINE    DD 9.0
FIVE    DD 5.0
THIRTY2 DD 32.0
QA      DD 1.0                  ; x^2 - 5x + 6 = 0  -> roots 3 , 2
QB      DD -5.0
QC      DD 6.0
FOUR    DD 4.0
CONVV   DD 98.6                 ; to be converted to integer
SCALE   DD 10000.0              ; for printing 4 decimals

;--------- RESULT AREA ---------
R_ADD   DD ?
R_SUB   DD ?
R_MUL   DD ?
R_DIV   DD ?
R_SQRT  DD ?
R_AREA  DD ?
R_HYP   DD ?
R_AVG   DD ?
R_FAHR  DD ?
DISC    DD ?
SQD     DD ?
TWOA    DD ?
ROOT1   DD ?
ROOT2   DD ?
R_INT   DW ?
STATUS  DW ?                    ; 8087 status word copy
TMPI    DD ?                    ; 32-bit integer scratch for printing

;--------- MESSAGES ---------
TITLE1  DB 0Dh,0Ah,'===== EXP 7 : 8087 FLOATING-POINT COMPUTATION =====$'
MA0     DB 0Dh,0Ah,0Dh,0Ah,'(a) A = 12.75 , B = 4.25$'
MA1     DB 0Dh,0Ah,'    A + B            = $'
MA2     DB 0Dh,0Ah,'    A - B            = $'
MA3     DB 0Dh,0Ah,'    A x B            = $'
MA4     DB 0Dh,0Ah,'    A / B            = $'
MB      DB 0Dh,0Ah,'(b) SQRT(625)        = $'
MC      DB 0Dh,0Ah,'(c) Area, r = 7.5    = $'
MD      DB 0Dh,0Ah,'(d) Hypotenuse (3,4) = $'
ME      DB 0Dh,0Ah,'(e) Average of 2.5, 3.75, 10.0, 6.25, 1.5 = $'
MF      DB 0Dh,0Ah,'(f) 37.0 C in F      = $'
MG      DB 0Dh,0Ah,'(g) x^2 - 5x + 6 = 0 : root1 = $'
MG2     DB '   root2 = $'
MG_CX   DB 0Dh,0Ah,'(g) Roots are complex (discriminant < 0)$'
MH      DB 0Dh,0Ah,'(h) Compare A and B  : $'
M_GT    DB 'A > B$'
M_LT    DB 'A < B$'
M_EQ    DB 'A = B$'
MI      DB 0Dh,0Ah,'(i) 98.6 -> integer  = $'
DONE    DB 0Dh,0Ah,0Dh,0Ah,'Program completed.',0Dh,0Ah,'$'

;------------------------------ CODE ----------------------------------
.CODE
MAIN PROC
        MOV  AX, @DATA
        MOV  DS, AX
        FINIT                   ; initialise 8087 (empty stack, round-nearest)
        PRINT TITLE1

;================ (a) BASIC ARITHMETIC ================================
        PRINT MA0
        FLD  NUMA               ; ST(0) = A
        FADD NUMB               ; ST(0) = A + B = 17.0
        FST  R_ADD
        PRINT MA1
        CALL PFLOAT             ; prints and pops ST(0)

        FLD  NUMA
        FSUB NUMB               ; 8.5
        FST  R_SUB
        PRINT MA2
        CALL PFLOAT

        FLD  NUMA
        FMUL NUMB               ; 54.1875
        FST  R_MUL
        PRINT MA3
        CALL PFLOAT

        FLD  NUMA
        FDIV NUMB               ; 3.0
        FST  R_DIV
        PRINT MA4
        CALL PFLOAT

;================ (b) SQUARE ROOT OF AN INTEGER =======================
        FILD IVAL               ; integer -> real (625.0)
        FSQRT                   ; 25.0
        FST  R_SQRT
        PRINT MB
        CALL PFLOAT

;================ (c) AREA OF CIRCLE ==================================
        FLD  RADIUS             ; ST(0) = r
        FMUL ST(0), ST(0)       ; r^2
        FLDPI                   ; ST(0) = PI , ST(1) = r^2
        FMULP ST(1), ST(0)      ; ST(0) = PI * r^2 = 176.7146
        FST  R_AREA
        PRINT MC
        CALL PFLOAT

;================ (d) HYPOTENUSE ======================================
        FLD  SIDEA
        FMUL SIDEA              ; a^2
        FLD  SIDEB
        FMUL SIDEB              ; b^2      (ST(1) = a^2)
        FADDP ST(1), ST(0)      ; a^2 + b^2
        FSQRT                   ; 5.0
        FST  R_HYP
        PRINT MD
        CALL PFLOAT

;================ (e) AVERAGE OF REAL ARRAY ===========================
        FLDZ                    ; sum = 0.0
        LEA  SI, FARR
        MOV  CX, FCOUNT
AV_LP:  FADD DWORD PTR [SI]     ; sum += element
        ADD  SI, 4              ; next short real (4 bytes)
        LOOP AV_LP
        FIDIV FCOUNT            ; sum / 5 = 4.8
        FST  R_AVG
        PRINT ME
        CALL PFLOAT

;================ (f) CELSIUS TO FAHRENHEIT ===========================
        FLD  CELS
        FMUL NINE
        FDIV FIVE
        FADD THIRTY2            ; 98.6
        FST  R_FAHR
        PRINT MF
        CALL PFLOAT

;================ (g) ROOTS OF QUADRATIC EQUATION =====================
        FLD  QB
        FMUL QB                 ; b^2
        FLD  QA
        FMUL QC
        FMUL FOUR               ; 4ac           (ST(1) = b^2)
        FSUBP ST(1), ST(0)      ; ST(0) = b^2 - 4ac
        FST  DISC
        FTST                    ; compare ST(0) with 0.0
        FSTSW STATUS
        FWAIT
        MOV  AX, STATUS
        SAHF                    ; C0 -> CF , C3 -> ZF
        JB   COMPLEX            ; discriminant < 0
        FSQRT                   ; SQRT(disc)
        FSTP SQD
        FLD  QA
        FADD QA                 ; 2a
        FSTP TWOA

        FLD  QB
        FCHS                    ; -b
        FADD SQD                ; -b + SQRT(disc)
        FDIV TWOA
        FST  ROOT1              ; 3.0
        PRINT MG
        CALL PFLOAT

        FLD  QB
        FCHS
        FSUB SQD                ; -b - SQRT(disc)
        FDIV TWOA
        FST  ROOT2              ; 2.0
        PRINT MG2
        CALL PFLOAT
        JMP  QUAD_END
COMPLEX:
        FSTP ST(0)              ; discard discriminant
        PRINT MG_CX
QUAD_END:

;================ (h) FLOATING-POINT COMPARISON =======================
        PRINT MH
        FLD  NUMA
        FCOMP NUMB              ; compare ST(0) with B and pop
        FSTSW STATUS            ; 8087 stores status word to memory
        FWAIT                   ; wait until 8087 has finished
        MOV  AX, STATUS
        SAHF                    ; AH -> flags (C3=ZF, C2=PF, C0=CF)
        JA   CMP_GT
        JB   CMP_LT
        PRINT M_EQ
        JMP  CMP_END
CMP_GT: PRINT M_GT              ; 12.75 > 4.25
        JMP  CMP_END
CMP_LT: PRINT M_LT
CMP_END:

;================ (i) REAL -> INTEGER =================================
        FLD  CONVV
        FISTP R_INT             ; rounded to nearest -> 99
        FWAIT
        PRINT MI
        MOV  AX, R_INT
        XOR  DX, DX
        CALL PDEC32

        PRINT DONE
        MOV  AH, 4Ch
        INT  21h
MAIN ENDP

;------------------------------------------------------------------
; PFLOAT : print ST(0) as a signed decimal with 4 fractional digits
;          and pop it from the 8087 stack.
;------------------------------------------------------------------
PFLOAT PROC
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        FMUL SCALE              ; x * 10000
        FRNDINT                 ; round to integer
        FISTP TMPI              ; store as 32-bit integer, pop
        FWAIT
        MOV  AX, WORD PTR TMPI
        MOV  DX, WORD PTR TMPI+2
        TEST DX, 8000h          ; negative?
        JZ   PF_POS
        PUSH AX
        PUSH DX
        MOV  DL, '-'
        MOV  AH, 02h
        INT  21h
        POP  DX
        POP  AX
        NOT  AX                 ; 32-bit two's complement negate
        NOT  DX
        ADD  AX, 1
        ADC  DX, 0
PF_POS: MOV  BX, 10000          ; split into integer / fraction
        MOV  SI, AX
        MOV  AX, DX
        XOR  DX, DX
        DIV  BX
        MOV  CX, AX             ; high word of quotient
        MOV  AX, SI
        DIV  BX                 ; AX = low quotient , DX = fraction
        MOV  SI, DX
        MOV  DX, CX
        CALL PDEC32             ; integer part
        MOV  DL, '.'
        MOV  AH, 02h
        INT  21h
        MOV  AX, SI             ; fraction, always 4 digits
        MOV  BX, 10
        MOV  CX, 4
PF_D:   XOR  DX, DX
        DIV  BX
        PUSH DX
        LOOP PF_D
        MOV  CX, 4
PF_O:   POP  DX
        ADD  DL, '0'
        MOV  AH, 02h
        INT  21h
        LOOP PF_O
        POP  SI
        POP  DX
        POP  CX
        POP  BX
        POP  AX
        RET
PFLOAT ENDP

; PDEC32 : print DX:AX as unsigned decimal
PDEC32 PROC
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        MOV  BX, 10
        XOR  CX, CX
PD_DIV: MOV  SI, AX
        MOV  AX, DX
        XOR  DX, DX
        DIV  BX
        PUSH AX
        MOV  AX, SI
        DIV  BX
        MOV  SI, DX
        POP  DX
        PUSH SI
        INC  CX
        MOV  SI, AX
        OR   SI, DX
        JNZ  PD_DIV
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

END MAIN
