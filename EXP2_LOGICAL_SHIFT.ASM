;=======================================================================
; EXPERIMENT 2 : LOGICAL, BIT-MANIPULATION AND SHIFT OPERATIONS USING
;                8-BIT AND 16-BIT DATA
; Processor    : 8086
; Simulator    : EMU8086  /  MASM or TASM under DOSBox
;
; AIM : To write and verify 8086 ALPs for
;       (a) Logical   : AND, OR, XOR, NOT, TEST          (8 & 16 bit)
;       (b) Shift     : SHL, SHR, SAR                     (8 & 16 bit)
;       (c) Rotate    : ROL, ROR, RCL, RCR                (8 & 16 bit)
;       (d) Bit manipulation : set / clear / toggle / test a bit,
;           count 1s, nibble swap, byte swap, bit reversal,
;           BCD pack / unpack, binary-to-Gray code,
;           multiply by 10 and divide by 8 using shifts.
;
; Results are stored in memory (R_xxx) and shown in HEX and BINARY.
; NOTE: on the 8086 a shift/rotate count > 1 must be placed in CL.
;=======================================================================
.MODEL SMALL
.STACK 100h

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

SHOWB8 MACRO MSG, VAL           ; message + 8-bit value (hex & binary)
        PRINT MSG
        MOV  AL, VAL
        CALL PHEX8
        PRINT HOPEN
        CALL PBIN8
        PRINT BCLOSE
ENDM

SHOWB16 MACRO MSG, VAL          ; message + 16-bit value (hex & binary)
        PRINT MSG
        MOV  AX, VAL
        CALL PHEX16
        PRINT HOPEN
        CALL PBIN16
        PRINT BCLOSE
ENDM

SHOWBIT MACRO MSG, VAL          ; message + one bit (0/1)
        PRINT MSG
        MOV  DL, VAL
        ADD  DL, '0'
        MOV  AH, 02h
        INT  21h
ENDM

GETCF MACRO DEST                ; copy Carry Flag (0/1) into DEST
        MOV  DEST, 0
        RCL  DEST, 1
ENDM

;------------------------------ DATA ----------------------------------
.DATA
A8      DB 0B5h                 ; 1011 0101
B8      DB 3Ch                  ; 0011 1100
A16     DW 0A5F0h               ; 1010 0101 1111 0000
B16     DW 0FF0Fh               ; 1111 1111 0000 1111
BITV    DB 5Ch                  ; 0101 1100  (for bit manipulation)
PBCD    DB 47h                  ; packed BCD 47
NUM10   DW 0025h                ; 37 decimal (to be multiplied by 10)

;--------- RESULT AREA ---------
R_AND8  DB ?
R_OR8   DB ?
R_XOR8  DB ?
R_NOT8  DB ?
R_TSTZ  DB ?
R_AND16 DW ?
R_OR16  DW ?
R_XOR16 DW ?
R_NOT16 DW ?

R_SHL8  DB ?
R_SHR8  DB ?
R_SAR8  DB ?
R_ROL8  DB ?
R_ROR8  DB ?
R_RCL8  DB ?
R_RCR8  DB ?
R_CF    DB 7 DUP(?)             ; carry after each 8-bit shift/rotate

R_SHL16 DW ?
R_SHR16 DW ?
R_SAR16 DW ?
R_ROL16 DW ?
R_ROR16 DW ?
R_RCL16 DW ?
R_RCR16 DW ?

R_SETB  DB ?
R_CLRB  DB ?
R_TOGB  DB ?
R_TSTB  DB ?
R_ONES  DB ?
R_ZEROS DB ?
R_NSWAP DB ?
R_BSWAP DW ?
R_REV   DB ?
R_UNPH  DB ?
R_UNPL  DB ?
R_PACK  DB ?
R_GRAY  DB ?
R_MUL10 DW ?
R_DIV8  DW ?

;--------- MESSAGES ---------
TITLE1  DB 0Dh,0Ah,'===== EXP 2 : LOGICAL, BIT & SHIFT OPERATIONS =====',0Dh,0Ah
        DB 'A8=B5h  B8=3Ch  A16=A5F0h  B16=FF0Fh',0Dh,0Ah,'$'
HOPEN   DB 'h  ($'
BCLOSE  DB 'b)$'
M_CF    DB '  CF=$'

HL      DB 0Dh,0Ah,'--- LOGICAL (8-BIT) ---$'
L1      DB 0Dh,0Ah,'A8 AND B8  = $'
L2      DB 0Dh,0Ah,'A8 OR  B8  = $'
L3      DB 0Dh,0Ah,'A8 XOR B8  = $'
L4      DB 0Dh,0Ah,'NOT A8     = $'
L5      DB 0Dh,0Ah,'TEST A8,B8 : ZF = $'
HL16    DB 0Dh,0Ah,0Dh,0Ah,'--- LOGICAL (16-BIT) ---$'
L6      DB 0Dh,0Ah,'A16 AND B16 = $'
L7      DB 0Dh,0Ah,'A16 OR  B16 = $'
L8      DB 0Dh,0Ah,'A16 XOR B16 = $'
L9      DB 0Dh,0Ah,'NOT A16     = $'

HS      DB 0Dh,0Ah,0Dh,0Ah,'--- SHIFT / ROTATE 8-BIT (A8, count=1, CF=0 before RCL/RCR) ---$'
S1      DB 0Dh,0Ah,'SHL = $'
S2      DB 0Dh,0Ah,'SHR = $'
S3      DB 0Dh,0Ah,'SAR = $'
S4      DB 0Dh,0Ah,'ROL = $'
S5      DB 0Dh,0Ah,'ROR = $'
S6      DB 0Dh,0Ah,'RCL = $'
S7      DB 0Dh,0Ah,'RCR = $'
HS16    DB 0Dh,0Ah,0Dh,0Ah,'--- SHIFT / ROTATE 16-BIT (A16, count CL=4) ---$'

HB      DB 0Dh,0Ah,0Dh,0Ah,'--- BIT MANIPULATION (BITV = 5Ch) ---$'
B1      DB 0Dh,0Ah,'Set    bit 0      = $'
B2      DB 0Dh,0Ah,'Clear  bit 6      = $'
B3      DB 0Dh,0Ah,'Toggle bit 7      = $'
B4      DB 0Dh,0Ah,'Test   bit 3 of BITV : bit = $'
B5      DB 0Dh,0Ah,'No. of 1s in A16  = $'
B5Z     DB 'h   No. of 0s = $'
B6      DB 0Dh,0Ah,'Nibble swap A8    = $'
B7      DB 0Dh,0Ah,'Byte swap A16     = $'
B8M     DB 0Dh,0Ah,'Bit reverse A8    = $'
B9      DB 0Dh,0Ah,'Unpack BCD 47h -> high = $'
B9L     DB '   low = $'
B10     DB 0Dh,0Ah,'Pack 04h,07h      = $'
B11     DB 0Dh,0Ah,'Gray code of A8   = $'
B12     DB 0Dh,0Ah,'0025h x 10 (shift)= $'
B13     DB 0Dh,0Ah,'A5F0h / 8  (shift)= $'
HSUF    DB 'h$'
DONE    DB 0Dh,0Ah,0Dh,0Ah,'Program completed.',0Dh,0Ah,'$'

;------------------------------ CODE ----------------------------------
.CODE
MAIN PROC
        MOV  AX, @DATA
        MOV  DS, AX
        PRINT TITLE1

;===================== (a) LOGICAL OPERATIONS =========================
        PRINT HL
        MOV  AL, A8
        AND  AL, B8             ; 34h
        MOV  R_AND8, AL
        SHOWB8 L1, R_AND8

        MOV  AL, A8
        OR   AL, B8             ; BDh
        MOV  R_OR8, AL
        SHOWB8 L2, R_OR8

        MOV  AL, A8
        XOR  AL, B8             ; 89h
        MOV  R_XOR8, AL
        SHOWB8 L3, R_XOR8

        MOV  AL, A8
        NOT  AL                 ; 4Ah
        MOV  R_NOT8, AL
        SHOWB8 L4, R_NOT8

        MOV  AL, A8
        TEST AL, B8             ; AND without storing - only flags change
        MOV  BL, 0
        JNZ  TST_NZ
        MOV  BL, 1              ; ZF = 1
TST_NZ: MOV  R_TSTZ, BL         ; expected ZF = 0 (34h is non-zero)
        SHOWBIT L5, R_TSTZ

        PRINT HL16
        MOV  AX, A16
        AND  AX, B16            ; A500h
        MOV  R_AND16, AX
        SHOWB16 L6, R_AND16

        MOV  AX, A16
        OR   AX, B16            ; FFFFh
        MOV  R_OR16, AX
        SHOWB16 L7, R_OR16

        MOV  AX, A16
        XOR  AX, B16            ; 5AFFh
        MOV  R_XOR16, AX
        SHOWB16 L8, R_XOR16

        MOV  AX, A16
        NOT  AX                 ; 5A0Fh
        MOV  R_NOT16, AX
        SHOWB16 L9, R_NOT16

;================ (b,c) SHIFT & ROTATE  - 8 BIT =======================
        PRINT HS
        LEA  SI, R_CF           ; SI -> carry-flag table

        MOV  AL, A8
        SHL  AL, 1              ; 6Ah , CF=1
        MOV  R_SHL8, AL
        GETCF BYTE PTR [SI]
        SHOWB8 S1, R_SHL8
        SHOWBIT M_CF, [SI]

        MOV  AL, A8
        SHR  AL, 1              ; 5Ah , CF=1  (logical: 0 enters MSB)
        MOV  R_SHR8, AL
        GETCF BYTE PTR [SI+1]
        SHOWB8 S2, R_SHR8
        SHOWBIT M_CF, [SI+1]

        MOV  AL, A8
        SAR  AL, 1              ; DAh , CF=1  (arithmetic: sign kept)
        MOV  R_SAR8, AL
        GETCF BYTE PTR [SI+2]
        SHOWB8 S3, R_SAR8
        SHOWBIT M_CF, [SI+2]

        MOV  AL, A8
        ROL  AL, 1              ; 6Bh , CF=1
        MOV  R_ROL8, AL
        GETCF BYTE PTR [SI+3]
        SHOWB8 S4, R_ROL8
        SHOWBIT M_CF, [SI+3]

        MOV  AL, A8
        ROR  AL, 1              ; DAh , CF=1
        MOV  R_ROR8, AL
        GETCF BYTE PTR [SI+4]
        SHOWB8 S5, R_ROR8
        SHOWBIT M_CF, [SI+4]

        MOV  AL, A8
        CLC                     ; CF = 0
        RCL  AL, 1              ; 6Ah , CF=1  (9-bit rotate through CF)
        MOV  R_RCL8, AL
        GETCF BYTE PTR [SI+5]
        SHOWB8 S6, R_RCL8
        SHOWBIT M_CF, [SI+5]

        MOV  AL, A8
        CLC
        RCR  AL, 1              ; 5Ah , CF=1
        MOV  R_RCR8, AL
        GETCF BYTE PTR [SI+6]
        SHOWB8 S7, R_RCR8
        SHOWBIT M_CF, [SI+6]

;================ (b,c) SHIFT & ROTATE  - 16 BIT ======================
        PRINT HS16
        MOV  CL, 4              ; shift count in CL

        MOV  AX, A16
        SHL  AX, CL             ; 5F00h
        MOV  R_SHL16, AX
        SHOWB16 S1, R_SHL16

        MOV  AX, A16
        SHR  AX, CL             ; 0A5Fh
        MOV  R_SHR16, AX
        SHOWB16 S2, R_SHR16

        MOV  AX, A16
        SAR  AX, CL             ; FA5Fh
        MOV  R_SAR16, AX
        SHOWB16 S3, R_SAR16

        MOV  AX, A16
        ROL  AX, CL             ; 5F0Ah
        MOV  R_ROL16, AX
        SHOWB16 S4, R_ROL16

        MOV  AX, A16
        ROR  AX, CL             ; 0A5Fh
        MOV  R_ROR16, AX
        SHOWB16 S5, R_ROR16

        MOV  AX, A16
        CLC
        RCL  AX, CL             ; 5F05h (17-bit rotate through CF)
        MOV  R_RCL16, AX
        SHOWB16 S6, R_RCL16

        MOV  AX, A16
        CLC
        RCR  AX, CL             ; 0A5Fh
        MOV  R_RCR16, AX
        SHOWB16 S7, R_RCR16

;===================== (d) BIT MANIPULATION ===========================
        PRINT HB
; --- SET bit n : OR with mask (1 SHL n) ---
        MOV  BL, 1
        MOV  CL, 0              ; bit number 0
        SHL  BL, CL             ; mask = 01h
        MOV  AL, BITV
        OR   AL, BL             ; 5Dh
        MOV  R_SETB, AL
        SHOWB8 B1, R_SETB

; --- CLEAR bit n : AND with NOT mask ---
        MOV  BL, 1
        MOV  CL, 6              ; bit number 6
        SHL  BL, CL             ; mask = 40h
        NOT  BL                 ; BFh
        MOV  AL, BITV
        AND  AL, BL             ; 1Ch
        MOV  R_CLRB, AL
        SHOWB8 B2, R_CLRB

; --- TOGGLE bit n : XOR with mask ---
        MOV  BL, 1
        MOV  CL, 7              ; bit number 7
        SHL  BL, CL             ; mask = 80h
        MOV  AL, BITV
        XOR  AL, BL             ; DCh
        MOV  R_TOGB, AL
        SHOWB8 B3, R_TOGB

; --- TEST bit n ---
        MOV  BL, 1
        MOV  CL, 3
        SHL  BL, CL             ; mask = 08h
        MOV  R_TSTB, 0
        TEST BITV, BL
        JZ   BIT_IS0
        MOV  R_TSTB, 1          ; bit 3 of 5Ch is 1
BIT_IS0:
        SHOWBIT B4, R_TSTB

; --- COUNT number of 1s and 0s in a 16-bit word ---
        MOV  AX, A16
        MOV  CX, 16
        XOR  BL, BL             ; BL = count of ones
CNT1:   SHR  AX, 1              ; LSB -> CF
        ADC  BL, 0              ; add CF to count
        LOOP CNT1
        MOV  R_ONES, BL         ; 08h
        MOV  AL, 16
        SUB  AL, BL
        MOV  R_ZEROS, AL        ; 08h
        PRINT B5
        MOV  AL, R_ONES
        CALL PHEX8
        PRINT B5Z
        MOV  AL, R_ZEROS
        CALL PHEX8
        PRINT HSUF

; --- NIBBLE SWAP : rotate byte by 4 ---
        MOV  AL, A8
        MOV  CL, 4
        ROL  AL, CL             ; B5h -> 5Bh
        MOV  R_NSWAP, AL
        SHOWB8 B6, R_NSWAP

; --- BYTE SWAP of a word ---
        MOV  AX, A16
        XCHG AH, AL             ; A5F0h -> F0A5h
        MOV  R_BSWAP, AX
        SHOWB16 B7, R_BSWAP

; --- BIT REVERSAL of a byte ---
        MOV  AL, A8             ; 1011 0101
        XOR  BL, BL
        MOV  CX, 8
REVL:   SHR  AL, 1              ; take LSB of AL ...
        RCL  BL, 1              ; ... shift it into BL from the right
        LOOP REVL
        MOV  R_REV, BL          ; 1010 1101 = ADh
        SHOWB8 B8M, R_REV

; --- UNPACK packed BCD 47h -> 04h , 07h ---
        MOV  AL, PBCD
        MOV  AH, AL
        AND  AL, 0Fh            ; low digit  = 07h
        MOV  CL, 4
        SHR  AH, CL             ; high digit = 04h
        MOV  R_UNPH, AH
        MOV  R_UNPL, AL
        PRINT B9
        MOV  AL, R_UNPH
        CALL PHEX8
        PRINT HSUF
        PRINT B9L
        MOV  AL, R_UNPL
        CALL PHEX8
        PRINT HSUF

; --- PACK 04h , 07h -> 47h ---
        MOV  AL, R_UNPH
        MOV  CL, 4
        SHL  AL, CL             ; 40h
        OR   AL, R_UNPL         ; 47h
        MOV  R_PACK, AL
        SHOWB8 B10, R_PACK

; --- BINARY TO GRAY CODE : G = B XOR (B SHR 1) ---
        MOV  AL, A8
        MOV  BL, AL
        SHR  BL, 1
        XOR  AL, BL             ; B5h -> EFh
        MOV  R_GRAY, AL
        SHOWB8 B11, R_GRAY

; --- MULTIPLY BY 10 USING SHIFTS : X*10 = X*8 + X*2 ---
        MOV  AX, NUM10
        SHL  AX, 1              ; X*2
        MOV  BX, AX
        MOV  CL, 2
        SHL  AX, CL             ; X*8
        ADD  AX, BX             ; X*10 = 0172h (370)
        MOV  R_MUL10, AX
        SHOWB16 B12, R_MUL10

; --- DIVIDE BY 8 USING SHIFT ---
        MOV  AX, A16
        MOV  CL, 3
        SHR  AX, CL             ; A5F0h / 8 = 14BEh
        MOV  R_DIV8, AX
        SHOWB16 B13, R_DIV8

        PRINT DONE
        MOV  AH, 4Ch
        INT  21h
MAIN ENDP

;------------------------- HELPER ROUTINES ----------------------------
PHEX16 PROC                     ; print AX in hex
        PUSH AX
        XCHG AL, AH
        CALL PHEX8
        XCHG AL, AH
        CALL PHEX8
        POP  AX
        RET
PHEX16 ENDP

PHEX8 PROC                      ; print AL in hex
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

PNIB PROC                       ; print low nibble of AL
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

PBIN16 PROC                     ; print AX in binary (16 digits)
        PUSH AX
        XCHG AL, AH
        CALL PBIN8
        XCHG AL, AH
        CALL PBIN8
        POP  AX
        RET
PBIN16 ENDP

PBIN8 PROC                      ; print AL in binary (8 digits)
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        MOV  BL, AL
        MOV  CX, 8
PB_L:   MOV  DL, '0'
        SHL  BL, 1              ; MSB -> CF
        ADC  DL, 0              ; '0' or '1'
        MOV  AH, 02h
        INT  21h
        LOOP PB_L
        POP  DX
        POP  CX
        POP  BX
        POP  AX
        RET
PBIN8 ENDP

END MAIN
