;=======================================================================
; EXPERIMENT 3 : MULTI-BYTE DATA AND ARRAY OPERATIONS USING 8086
;                INDIRECT ADDRESSING
; Processor    : 8086
; Simulator    : EMU8086  /  MASM or TASM under DOSBox
;
; AIM : To write and verify 8086 ALPs using register-indirect
;       ([SI],[DI],[BX]), based-indexed ([BX+SI]) and indexed
;       ([SI+disp]) addressing modes for
;       (a) Multi-byte (64-bit) addition with ADC
;       (b) Multi-byte (64-bit) subtraction with SBB
;       (c) Sum and average of an array of 16-bit words
;       (d) Largest and smallest element of a byte array
;       (e) Count of positive / negative and even / odd numbers
;       (f) Sorting an array in ascending order (bubble sort)
;       (g) Copying an array in reverse order
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

SHOW8 MACRO MSG, VAL
        PRINT MSG
        MOV  AL, VAL
        CALL PHEX8
        PRINT HSUF
ENDM

SHOW16 MACRO MSG, VAL
        PRINT MSG
        MOV  AX, VAL
        CALL PHEX16
        PRINT HSUF
ENDM

;------------------------------ DATA ----------------------------------
.DATA
NBYTES  EQU 8                   ; 8 bytes = 64-bit numbers
; Multi-byte numbers stored LOW BYTE FIRST (little endian)
NUM1    DB 0EFh,0CDh,0ABh,89h,67h,45h,23h,0F1h   ; F123456789ABCDEFh
NUM2    DB 0DFh,9Bh,57h,13h,0E0h,0ACh,68h,24h    ; 2468ACE013579BDFh
SUMM    DB NBYTES DUP(?)        ; NUM1 + NUM2
SUMC    DB ?                    ; final carry
DIFF    DB NBYTES DUP(?)        ; NUM1 - NUM2
DIFB    DB ?                    ; final borrow

WCOUNT  EQU 6
WARR    DW 1200h, 0FA00h, 3456h, 0A0B0h, 0011h, 7FFFh
WSUML   DW ?                    ; 32-bit sum (DX:AX)
WSUMH   DW ?
WAVG    DW ?                    ; average = sum / count
WREM    DW ?

BCOUNT  EQU 10
BARR    DB 25h, 8Ah, 03h, 7Fh, 0F0h, 41h, 12h, 99h, 66h, 0Ch
LARGE   DB ?
SMALL   DB ?
SLARGE  DB ?                    ; signed largest
SSMALL  DB ?                    ; signed smallest
POSC    DB ?
NEGC    DB ?
EVENC   DB ?
ODDC    DB ?
SORTED  DB BCOUNT DUP(?)
REVARR  DB BCOUNT DUP(?)

;--------- MESSAGES ---------
TITLE1  DB 0Dh,0Ah,'===== EXP 3 : MULTI-BYTE & ARRAY OPERATIONS =====$'
HSUF    DB 'h$'
SPACE   DB ' $'
H1      DB 0Dh,0Ah,0Dh,0Ah,'--- 64-BIT ADDITION / SUBTRACTION ---$'
M_N1    DB 0Dh,0Ah,'NUM1          = $'
M_N2    DB 0Dh,0Ah,'NUM2          = $'
M_SUM   DB 0Dh,0Ah,'NUM1 + NUM2   = $'
M_C     DB 'h   Carry=$'
M_DIF   DB 0Dh,0Ah,'NUM1 - NUM2   = $'
M_B     DB 'h   Borrow=$'
H2      DB 0Dh,0Ah,0Dh,0Ah,'--- WORD ARRAY : 1200 FA00 3456 A0B0 0011 7FFF ---$'
M_WS    DB 0Dh,0Ah,'Sum (32-bit)  = $'
M_WA    DB 0Dh,0Ah,'Average       = $'
M_WR    DB '   Remainder = $'
H3      DB 0Dh,0Ah,0Dh,0Ah,'--- BYTE ARRAY ---',0Dh,0Ah,'Array         : $'
M_L     DB 0Dh,0Ah,'Largest  (unsigned) = $'
M_S     DB 0Dh,0Ah,'Smallest (unsigned) = $'
M_SL    DB 0Dh,0Ah,'Largest  (signed)   = $'
M_SS    DB 0Dh,0Ah,'Smallest (signed)   = $'
M_P     DB 0Dh,0Ah,'Positive count      = $'
M_NG    DB 0Dh,0Ah,'Negative count      = $'
M_E     DB 0Dh,0Ah,'Even count          = $'
M_O     DB 0Dh,0Ah,'Odd count           = $'
M_SRT   DB 0Dh,0Ah,'Ascending order     : $'
M_REV   DB 0Dh,0Ah,'Reversed array      : $'
DONE    DB 0Dh,0Ah,0Dh,0Ah,'Program completed.',0Dh,0Ah,'$'

;------------------------------ CODE ----------------------------------
.CODE
MAIN PROC
        MOV  AX, @DATA
        MOV  DS, AX
        MOV  ES, AX
        PRINT TITLE1

;================ (a) 64-BIT ADDITION USING [SI],[DI],[BX] ============
        PRINT H1
        LEA  SI, NUM1           ; SI -> first operand
        LEA  DI, NUM2           ; DI -> second operand
        LEA  BX, SUMM           ; BX -> result
        MOV  CX, NBYTES
        CLC                     ; no carry into the lowest byte
ADD_LP: MOV  AL, [SI]
        ADC  AL, [DI]           ; byte + byte + carry
        MOV  [BX], AL
        INC  SI                 ; INC does not change CF
        INC  DI
        INC  BX
        LOOP ADD_LP             ; LOOP does not change CF
        MOV  AL, 0
        ADC  AL, 0
        MOV  SUMC, AL           ; final carry

;================ (b) 64-BIT SUBTRACTION USING [BX+SI] ================
        XOR  SI, SI             ; SI = index 0
        MOV  CX, NBYTES
        CLC
SUB_LP: LEA  BX, NUM1
        MOV  AL, [BX+SI]        ; based-indexed addressing
        LEA  BX, NUM2
        SBB  AL, [BX+SI]
        LEA  BX, DIFF
        MOV  [BX+SI], AL
        INC  SI
        LOOP SUB_LP
        MOV  AL, 0
        ADC  AL, 0
        MOV  DIFB, AL

; ---- display (most significant byte first) ----
        PRINT M_N1
        LEA  SI, NUM1
        CALL PMULTI
        PRINT HSUF
        PRINT M_N2
        LEA  SI, NUM2
        CALL PMULTI
        PRINT HSUF
        PRINT M_SUM
        LEA  SI, SUMM
        CALL PMULTI
        PRINT M_C
        MOV  AL, SUMC
        CALL PHEX8
        PRINT M_DIF
        LEA  SI, DIFF
        CALL PMULTI
        PRINT M_B
        MOV  AL, DIFB
        CALL PHEX8

;================ (c) SUM AND AVERAGE OF WORD ARRAY ===================
        PRINT H2
        LEA  SI, WARR
        MOV  CX, WCOUNT
        XOR  AX, AX             ; low word of sum
        XOR  DX, DX             ; high word of sum
WS_LP:  ADD  AX, [SI]
        ADC  DX, 0              ; propagate carry into high word
        ADD  SI, 2              ; next word
        LOOP WS_LP
        MOV  WSUML, AX
        MOV  WSUMH, DX          ; sum = 0002 6116h
        MOV  BX, WCOUNT
        DIV  BX                 ; DX:AX / 6
        MOV  WAVG, AX           ; 6583h
        MOV  WREM, DX           ; 0004h
        PRINT M_WS
        MOV  AX, WSUMH
        CALL PHEX16
        MOV  AX, WSUML
        CALL PHEX16
        PRINT HSUF
        SHOW16 M_WA, WAVG
        SHOW16 M_WR, WREM

;================ (d) LARGEST & SMALLEST (unsigned + signed) ==========
        PRINT H3
        LEA  SI, BARR
        MOV  CX, BCOUNT
        CALL PARRAY

        LEA  SI, BARR
        MOV  CX, BCOUNT-1
        MOV  AL, [SI]           ; AL = unsigned max
        MOV  BL, [SI]           ; BL = unsigned min
        MOV  AH, [SI]           ; AH = signed max
        MOV  BH, [SI]           ; BH = signed min
MM_LP:  INC  SI
        MOV  DL, [SI]
        CMP  DL, AL
        JBE  MX1
        MOV  AL, DL             ; new unsigned max
MX1:    CMP  DL, BL
        JAE  MX2
        MOV  BL, DL             ; new unsigned min
MX2:    CMP  DL, AH
        JLE  MX3
        MOV  AH, DL             ; new signed max
MX3:    CMP  DL, BH
        JGE  MX4
        MOV  BH, DL             ; new signed min
MX4:    LOOP MM_LP
        MOV  LARGE, AL          ; F0h
        MOV  SMALL, BL          ; 03h
        MOV  SLARGE, AH         ; 7Fh
        MOV  SSMALL, BH         ; 8Ah (-118)
        SHOW8 M_L,  LARGE
        SHOW8 M_S,  SMALL
        SHOW8 M_SL, SLARGE
        SHOW8 M_SS, SSMALL

;================ (e) POSITIVE/NEGATIVE & EVEN/ODD COUNT ==============
        LEA  SI, BARR
        MOV  CX, BCOUNT
        XOR  BX, BX             ; BL = positive , BH = negative
        XOR  DX, DX             ; DL = even     , DH = odd
PN_LP:  MOV  AL, [SI]
        TEST AL, 80h            ; sign bit
        JNZ  IS_NEG
        INC  BL
        JMP  CHK_EO
IS_NEG: INC  BH
CHK_EO: TEST AL, 01h            ; LSB
        JNZ  IS_ODD
        INC  DL
        JMP  PN_NX
IS_ODD: INC  DH
PN_NX:  INC  SI
        LOOP PN_LP
        MOV  POSC, BL           ; 7
        MOV  NEGC, BH           ; 3
        MOV  EVENC, DL          ; 5
        MOV  ODDC, DH           ; 5
        SHOW8 M_P,  POSC
        SHOW8 M_NG, NEGC
        SHOW8 M_E,  EVENC
        SHOW8 M_O,  ODDC

;================ (f) BUBBLE SORT (ascending, unsigned) ===============
; copy BARR -> SORTED first so the original stays unchanged
        LEA  SI, BARR
        LEA  DI, SORTED
        MOV  CX, BCOUNT
CP_LP:  MOV  AL, [SI]
        MOV  [DI], AL
        INC  SI
        INC  DI
        LOOP CP_LP

        MOV  DX, BCOUNT-1       ; number of passes
PASS:   LEA  SI, SORTED
        MOV  CX, DX             ; comparisons in this pass
CMP_LP: MOV  AL, [SI]
        CMP  AL, [SI+1]         ; indexed addressing with displacement
        JBE  NO_SWP
        XCHG AL, [SI+1]         ; swap adjacent elements
        MOV  [SI], AL
NO_SWP: INC  SI
        LOOP CMP_LP
        DEC  DX
        JNZ  PASS

        PRINT M_SRT
        LEA  SI, SORTED
        MOV  CX, BCOUNT
        CALL PARRAY

;================ (g) COPY ARRAY IN REVERSE ORDER =====================
        LEA  SI, BARR                   ; SI -> first element of source
        LEA  DI, REVARR+BCOUNT-1        ; DI -> last element of dest.
        MOV  CX, BCOUNT
RV_LP:  MOV  AL, [SI]
        MOV  [DI], AL
        INC  SI
        DEC  DI
        LOOP RV_LP

        PRINT M_REV
        LEA  SI, REVARR
        MOV  CX, BCOUNT
        CALL PARRAY

        PRINT DONE
        MOV  AH, 4Ch
        INT  21h
MAIN ENDP

;------------------------- HELPER ROUTINES ----------------------------
; PMULTI : print NBYTES-byte number at [SI] (stored low byte first)
PMULTI PROC
        PUSH AX
        PUSH CX
        PUSH SI
        ADD  SI, NBYTES-1       ; start from most significant byte
        MOV  CX, NBYTES
PM_LP:  MOV  AL, [SI]
        CALL PHEX8
        DEC  SI
        LOOP PM_LP
        POP  SI
        POP  CX
        POP  AX
        RET
PMULTI ENDP

; PARRAY : print CX bytes at [SI] separated by spaces
PARRAY PROC
        PUSH AX
        PUSH CX
        PUSH SI
PA_LP:  MOV  AL, [SI]
        CALL PHEX8
        PRINT SPACE
        INC  SI
        LOOP PA_LP
        POP  SI
        POP  CX
        POP  AX
        RET
PARRAY ENDP

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
