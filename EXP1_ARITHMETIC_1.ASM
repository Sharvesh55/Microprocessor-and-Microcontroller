;=======================================================================
; EXPERIMENT 1 : ANALYSIS, DEVELOPMENT AND VERIFICATION OF 8-BIT AND
;                16-BIT ARITHMETIC OPERATIONS USING ASSEMBLY LANGUAGE
; Processor    : 8086
; Simulator    : EMU8086  /  MASM or TASM under DOSBox
;
; AIM : To write and verify 8086 ALPs for
;       (a) 8-bit  ADD, SUB, MUL, DIV, IMUL, IDIV, INC, DEC, NEG
;       (b) 16-bit ADD, SUB, MUL, DIV (16/16 and 32/16), IMUL, IDIV
;       (c) 32-bit ADD / SUB using ADC / SBB (carry & borrow chaining)
;       (d) BCD addition / subtraction using DAA / DAS
;
; Every result is stored in a memory variable (R_xxx) so it can be
; checked in the simulator's memory/variables window, and it is also
; printed on the screen in hexadecimal.
;=======================================================================
.MODEL SMALL
.STACK 100h

;----------------------------- MACROS ---------------------------------
PRINT MACRO MSG                 ; print a '$' terminated string
        PUSH AX
        PUSH DX
        LEA  DX, MSG
        MOV  AH, 09h
        INT  21h
        POP  DX
        POP  AX
ENDM

SHOW8 MACRO MSG, VAL            ; message + 8-bit value in hex
        PRINT MSG
        MOV  AL, VAL
        CALL PHEX8
        PRINT HSUF
ENDM

SHOW16 MACRO MSG, VAL           ; message + 16-bit value in hex
        PRINT MSG
        MOV  AX, VAL
        CALL PHEX16
        PRINT HSUF
ENDM

SHOW32 MACRO MSG, HI, LO        ; message + 32-bit value HI:LO in hex
        PRINT MSG
        MOV  AX, HI
        CALL PHEX16
        MOV  AX, LO
        CALL PHEX16
        PRINT HSUF
ENDM

SHOWBIT MACRO MSG, VAL          ; message + single flag bit (0/1)
        PRINT MSG
        MOV  DL, VAL
        ADD  DL, '0'
        MOV  AH, 02h
        INT  21h
ENDM

;------------------------------ DATA ----------------------------------
.DATA
; 8-bit operands
A8      DB 25h
B8      DB 12h
SA8     DB 0FBh                 ; -5   (signed)
SB8     DB 03h                  ; +3
SD8     DB 0ECh                 ; -20  (signed dividend)
INCV    DB 0FFh
DECV    DB 00h

; 16-bit operands
A16     DW 0A234h
B16     DW 7ABCh
DVDH    DW 0012h                ; 32-bit dividend = 0012 3456h
DVDL    DW 3456h
DVSR    DW 1234h                ; 16-bit divisor
SA16    DW 0FC18h               ; -1000 (signed)
SB16    DW 0019h                ; +25

; 32-bit operands (low word first)
X32L    DW 5678h                ; X = 1234 5678h
X32H    DW 1234h
Y32L    DW 0DEF0h               ; Y = 9ABC DEF0h
Y32H    DW 9ABCh

; BCD operands
BCD1    DB 38h                  ; BCD 38
BCD2    DB 45h                  ; BCD 45

;------------- RESULT AREA ----------------
R_ADD8   DB ?
R_ADD8C  DB ?
R_SUB8   DB ?
R_SUB8B  DB ?
R_SUB8X  DB ?
R_SUB8XB DB ?
R_MUL8   DW ?
R_DIV8Q  DB ?
R_DIV8R  DB ?
R_IMUL8  DW ?
R_IDIV8Q DB ?
R_IDIV8R DB ?
R_INC8   DB ?
R_DEC8   DB ?
R_NEG8   DB ?

R_ADD16  DW ?
R_ADD16C DB ?
R_SUB16  DW ?
R_SUB16B DB ?
R_MUL16H DW ?
R_MUL16L DW ?
R_DIV16Q DW ?
R_DIV16R DW ?
R_DIV32Q DW ?
R_DIV32R DW ?
R_IMULH  DW ?
R_IMULL  DW ?
R_IDIVQ  DW ?
R_IDIVR  DW ?

R_ADD32L DW ?
R_ADD32H DW ?
R_SUB32L DW ?
R_SUB32H DW ?

R_DAA    DB ?
R_DAS    DB ?

;------------- MESSAGES ----------------
TITLE1  DB 0Dh,0Ah,'===== EXP 1 : 8-BIT & 16-BIT ARITHMETIC =====',0Dh,0Ah,'$'
HSUF    DB 'h$'
SPC     DB '  $'
CRLF    DB 0Dh,0Ah,'$'
M_CF    DB '   CF=$'
M_REM   DB '   Remainder=$'

H8      DB 0Dh,0Ah,'--- 8-BIT OPERATIONS ---$'
M1      DB 0Dh,0Ah,'ADD   25h + 12h          = $'
M2      DB 0Dh,0Ah,'SUB   25h - 12h          = $'
M2X     DB 0Dh,0Ah,'SUB   12h - 25h          = $'
M3      DB 0Dh,0Ah,'MUL   25h x 12h     (AX) = $'
M4      DB 0Dh,0Ah,'DIV   25h / 12h  Quotient= $'
M5      DB 0Dh,0Ah,'IMUL  (-5) x (+3)   (AX) = $'
M6      DB 0Dh,0Ah,'IDIV  (-20)/(+3) Quotient= $'
M7      DB 0Dh,0Ah,'INC   FFh                = $'
M8      DB 0Dh,0Ah,'DEC   00h                = $'
M9      DB 0Dh,0Ah,'NEG   25h  (2s compl.)   = $'

H16     DB 0Dh,0Ah,0Dh,0Ah,'--- 16-BIT OPERATIONS ---$'
N1      DB 0Dh,0Ah,'ADD   A234h + 7ABCh      = $'
N2      DB 0Dh,0Ah,'SUB   A234h - 7ABCh      = $'
N3      DB 0Dh,0Ah,'MUL   A234h x 7ABCh DX:AX= $'
N4      DB 0Dh,0Ah,'DIV   A234h / 7ABCh  Quot= $'
N5      DB 0Dh,0Ah,'DIV   00123456h/1234h Quo= $'
N6      DB 0Dh,0Ah,'IMUL  (-1000)x(+25) DX:AX= $'
N7      DB 0Dh,0Ah,'IDIV  (-1000)/(+25)  Quot= $'

H32     DB 0Dh,0Ah,0Dh,0Ah,'--- 32-BIT USING ADC / SBB ---$'
P1      DB 0Dh,0Ah,'ADD   12345678h + 9ABCDEF0h = $'
P2      DB 0Dh,0Ah,'SUB   9ABCDEF0h - 12345678h = $'

HBCD    DB 0Dh,0Ah,0Dh,0Ah,'--- BCD ARITHMETIC ---$'
Q1      DB 0Dh,0Ah,'DAA   38 + 45  (BCD)     = $'
Q2      DB 0Dh,0Ah,'DAS   83 - 38  (BCD)     = $'
DONE    DB 0Dh,0Ah,0Dh,0Ah,'Program completed.',0Dh,0Ah,'$'

;------------------------------ CODE ----------------------------------
.CODE
MAIN PROC
        MOV  AX, @DATA
        MOV  DS, AX

        PRINT TITLE1
        PRINT H8

;==================== (a) 8-BIT OPERATIONS ============================
; ---- 8-bit addition ----
        MOV  AL, A8
        ADD  AL, B8             ; AL = 37h
        MOV  R_ADD8, AL
        MOV  AL, 0
        ADC  AL, 0              ; capture carry flag
        MOV  R_ADD8C, AL
        SHOW8   M1, R_ADD8
        SHOWBIT M_CF, R_ADD8C

; ---- 8-bit subtraction (no borrow) ----
        MOV  AL, A8
        SUB  AL, B8             ; AL = 13h , CF = 0
        MOV  R_SUB8, AL
        MOV  AL, 0
        ADC  AL, 0
        MOV  R_SUB8B, AL
        SHOW8   M2, R_SUB8
        SHOWBIT M_CF, R_SUB8B

; ---- 8-bit subtraction (with borrow) ----
        MOV  AL, B8
        SUB  AL, A8             ; AL = EDh (-19) , CF = 1 (borrow)
        MOV  R_SUB8X, AL
        MOV  AL, 0
        ADC  AL, 0
        MOV  R_SUB8XB, AL
        SHOW8   M2X, R_SUB8X
        SHOWBIT M_CF, R_SUB8XB

; ---- 8-bit unsigned multiplication : AX = AL * src ----
        MOV  AL, A8
        MUL  B8                 ; AX = 029Ah
        MOV  R_MUL8, AX
        SHOW16  M3, R_MUL8

; ---- 8-bit unsigned division : AX / src -> AL=Q , AH=R ----
        MOV  AL, A8
        MOV  AH, 00h            ; zero-extend dividend
        DIV  B8                 ; AL = 02h , AH = 01h
        MOV  R_DIV8Q, AL
        MOV  R_DIV8R, AH
        SHOW8   M4, R_DIV8Q
        SHOW8   M_REM, R_DIV8R

; ---- 8-bit signed multiplication ----
        MOV  AL, SA8
        IMUL SB8                ; AX = FFF1h  (-15)
        MOV  R_IMUL8, AX
        SHOW16  M5, R_IMUL8

; ---- 8-bit signed division ----
        MOV  AL, SD8
        CBW                     ; sign-extend AL into AX (AX = FFECh)
        IDIV SB8                ; AL = FAh (-6) , AH = FEh (-2)
        MOV  R_IDIV8Q, AL
        MOV  R_IDIV8R, AH
        SHOW8   M6, R_IDIV8Q
        SHOW8   M_REM, R_IDIV8R

; ---- INC / DEC / NEG ----
        MOV  AL, INCV
        INC  AL                 ; FFh + 1 = 00h (ZF=1, CF not affected)
        MOV  R_INC8, AL
        SHOW8   M7, R_INC8

        MOV  AL, DECV
        DEC  AL                 ; 00h - 1 = FFh
        MOV  R_DEC8, AL
        SHOW8   M8, R_DEC8

        MOV  AL, A8
        NEG  AL                 ; 0 - 25h = DBh
        MOV  R_NEG8, AL
        SHOW8   M9, R_NEG8

;==================== (b) 16-BIT OPERATIONS ===========================
        PRINT H16
; ---- 16-bit addition ----
        MOV  AX, A16
        ADD  AX, B16            ; AX = 1CF0h , CF = 1
        MOV  R_ADD16, AX
        MOV  AL, 0
        ADC  AL, 0
        MOV  R_ADD16C, AL
        SHOW16  N1, R_ADD16
        SHOWBIT M_CF, R_ADD16C

; ---- 16-bit subtraction ----
        MOV  AX, A16
        SUB  AX, B16            ; AX = 2778h , CF = 0
        MOV  R_SUB16, AX
        MOV  AL, 0
        ADC  AL, 0
        MOV  R_SUB16B, AL
        SHOW16  N2, R_SUB16
        SHOWBIT M_CF, R_SUB16B

; ---- 16-bit unsigned multiplication : DX:AX = AX * src ----
        MOV  AX, A16
        MUL  B16                ; DX:AX = 4DC3 E630h
        MOV  R_MUL16H, DX
        MOV  R_MUL16L, AX
        SHOW32  N3, R_MUL16H, R_MUL16L

; ---- 16-bit / 16-bit unsigned division ----
        MOV  AX, A16
        MOV  DX, 0000h          ; DX:AX = 0000 A234h
        DIV  B16                ; AX = 0001h , DX = 2778h
        MOV  R_DIV16Q, AX
        MOV  R_DIV16R, DX
        SHOW16  N4, R_DIV16Q
        SHOW16  M_REM, R_DIV16R

; ---- 32-bit / 16-bit unsigned division ----
        MOV  DX, DVDH
        MOV  AX, DVDL           ; DX:AX = 0012 3456h
        DIV  DVSR               ; AX = 0100h , DX = 0056h
        MOV  R_DIV32Q, AX
        MOV  R_DIV32R, DX
        SHOW16  N5, R_DIV32Q
        SHOW16  M_REM, R_DIV32R

; ---- 16-bit signed multiplication ----
        MOV  AX, SA16
        IMUL SB16               ; DX:AX = FFFF 9E58h (-25000)
        MOV  R_IMULH, DX
        MOV  R_IMULL, AX
        SHOW32  N6, R_IMULH, R_IMULL

; ---- 16-bit signed division ----
        MOV  AX, SA16
        CWD                     ; sign-extend AX into DX:AX
        IDIV SB16               ; AX = FFD8h (-40) , DX = 0000h
        MOV  R_IDIVQ, AX
        MOV  R_IDIVR, DX
        SHOW16  N7, R_IDIVQ
        SHOW16  M_REM, R_IDIVR

;=============== (c) 32-BIT ADD / SUB USING ADC / SBB =================
        PRINT H32
        MOV  AX, X32L
        ADD  AX, Y32L           ; add low words  -> CF
        MOV  R_ADD32L, AX
        MOV  AX, X32H
        ADC  AX, Y32H           ; add high words + carry
        MOV  R_ADD32H, AX       ; result = ACF1 3568h
        SHOW32  P1, R_ADD32H, R_ADD32L

        MOV  AX, Y32L
        SUB  AX, X32L           ; subtract low words -> borrow
        MOV  R_SUB32L, AX
        MOV  AX, Y32H
        SBB  AX, X32H           ; subtract high words - borrow
        MOV  R_SUB32H, AX       ; result = 8888 8878h
        SHOW32  P2, R_SUB32H, R_SUB32L

;===================== (d) BCD ARITHMETIC =============================
        PRINT HBCD
        MOV  AL, BCD1
        ADD  AL, BCD2           ; 38h + 45h = 7Dh (binary)
        DAA                     ; adjust -> 83h (BCD 83)
        MOV  R_DAA, AL
        SHOW8   Q1, R_DAA

        MOV  AL, R_DAA          ; 83h
        SUB  AL, BCD1           ; 83h - 38h = 4Bh (binary)
        DAS                     ; adjust -> 45h (BCD 45)
        MOV  R_DAS, AL
        SHOW8   Q2, R_DAS

        PRINT DONE
        MOV  AH, 4Ch            ; terminate program
        INT  21h
MAIN ENDP

;------------------------- HELPER ROUTINES ----------------------------
; PHEX16 : print AX as 4 hex digits
PHEX16 PROC
        PUSH AX
        XCHG AL, AH
        CALL PHEX8
        XCHG AL, AH
        CALL PHEX8
        POP  AX
        RET
PHEX16 ENDP

; PHEX8 : print AL as 2 hex digits
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

; PNIB : print low nibble of AL (0-F) as an ASCII hex digit
PNIB PROC
        PUSH AX
        PUSH DX
        ADD  AL, '0'
        CMP  AL, '9'
        JBE  PN_OK
        ADD  AL, 7              ; 'A'..'F'
PN_OK:  MOV  DL, AL
        MOV  AH, 02h
        INT  21h
        POP  DX
        POP  AX
        RET
PNIB ENDP

END MAIN
