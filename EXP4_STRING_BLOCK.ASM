; EXPERIMENT 3
; Array Operations Using Indirect Addressing
; 8086 Microprocessor

ORG 100H

; Initialize array
MOV BYTE PTR [3000H], 05H
MOV BYTE PTR [3001H], 10H
MOV BYTE PTR [3002H], 15H
MOV BYTE PTR [3003H], 20H
MOV BYTE PTR [3004H], 25H

; Array Addition
MOV SI, 3000H
MOV CX, 05
MOV AX, 0000H

NEXT:
MOV BL, [SI]
MOV BH, 00H
ADD AX, BX
INC SI
LOOP NEXT

MOV [2000H], AX

; Array Copy
MOV SI, 3000H
MOV DI, 4000H
MOV CX, 05

COPY:
MOV AL, [SI]
MOV [DI], AL
INC SI
INC DI
LOOP COPY

HLT;=======================================================================
; EXPERIMENT 4 : STRING AND BLOCK DATA OPERATIONS USING 8086
; Processor    : 8086
; Simulator    : EMU8086  /  MASM or TASM under DOSBox
;
; AIM : To write and verify 8086 ALPs using the string instructions
;       MOVSB/MOVSW, CMPSB, SCASB, LODSB, STOSB/STOSW with the
;       REP / REPE / REPNE prefixes and the Direction Flag (CLD/STD):
;       (a) Block transfer of bytes        (REP MOVSB)
;       (b) Block transfer of words        (REP MOVSW)
;       (c) Overlapping block move         (STD + REP MOVSB)
;       (d) Fill a block with a constant   (REP STOSB)
;       (e) Find the length of a string    (REPNE SCASB)
;       (f) Search a character in a string (REPNE SCASB)
;       (g) Compare two strings            (REPE CMPSB)
;       (h) Reverse a string
;       (i) Palindrome check
;       (j) Lower-case to upper-case       (LODSB / STOSB)
;       (k) Count vowels in a string       (LODSB)
;
; String instructions use  DS:SI  as source and  ES:DI  as destination
; so ES is loaded with the data segment as well.
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

;------------------------------ DATA ----------------------------------
.DATA
SRC     DB 'MICROPROCESSOR$'
SRCLEN  EQU 15                  ; 14 characters + '$'
DST     DB 20 DUP('$')

WSRC    DW 1111h, 2222h, 3333h, 4444h, 5555h
WDST    DW 5 DUP(0)

OVL     DB '12345678$', 4 DUP('$')   ; overlapping move demo buffer

FILLB   DB 10 DUP(?), '$'

STR1    DB 'EMU8086 KIT$'
STRLENV DB ?
SCHAR   DB '8'
SPOS    DB ?                    ; 1-based position (0 = not found)

CMPA    DB 'ASSEMBLY'
CMPB    DB 'ASSEMBLE'
CMPLEN  EQU 8
CMPRES  DB ?                    ; 0 = equal, 1 = not equal
MISPOS  DB ?                    ; position of first mismatch

RSTR    DB 'COMPUTER$'
RLEN    EQU 8
RREV    DB RLEN DUP(?), '$'

PAL1    DB 'MALAYALAM$'
PAL2    DB 'PROCESSOR$'
PALRES  DB ?

LOWS    DB 'hello 8086 world!$'
UPS     DB 20 DUP('$')

VSTR    DB 'MICROCONTROLLER AND INTERFACING$'
VCOUNT  DB ?
VOWELS  DB 'AEIOUaeiou'

;--------- MESSAGES ---------
TITLE1  DB 0Dh,0Ah,'===== EXP 4 : STRING & BLOCK OPERATIONS =====$'
HSUF    DB 'h$'
SPACE   DB ' $'
MA      DB 0Dh,0Ah,0Dh,0Ah,'(a) REP MOVSB  source : $'
MA2     DB 0Dh,0Ah,'               copied : $'
MB      DB 0Dh,0Ah,'(b) REP MOVSW  copied words : $'
MC1     DB 0Dh,0Ah,'(c) Overlap move  before : $'
MC2     DB 0Dh,0Ah,'    (shift right by 2) after : $'
MD      DB 0Dh,0Ah,'(d) REP STOSB fill with *  : $'
ME      DB 0Dh,0Ah,'(e) Length of "EMU8086 KIT"  = $'
MF      DB 0Dh,0Ah,'(f) Position of "8"          = $'
MG      DB 0Dh,0Ah,'(g) "ASSEMBLY" vs "ASSEMBLE" : $'
MG_EQ   DB 'EQUAL$'
MG_NE   DB 'NOT EQUAL, first mismatch at position $'
MH      DB 0Dh,0Ah,'(h) Reverse of "COMPUTER"    : $'
MI1     DB 0Dh,0Ah,'(i) "MALAYALAM" is $'
MI2     DB 0Dh,0Ah,'    "PROCESSOR" is $'
M_PAL   DB 'a PALINDROME$'
M_NPAL  DB 'NOT a palindrome$'
MJ      DB 0Dh,0Ah,'(j) Upper case : $'
MK      DB 0Dh,0Ah,'(k) Vowels in "MICROCONTROLLER AND INTERFACING" = $'
DONE    DB 0Dh,0Ah,0Dh,0Ah,'Program completed.',0Dh,0Ah,'$'

;------------------------------ CODE ----------------------------------
.CODE
MAIN PROC
        MOV  AX, @DATA
        MOV  DS, AX
        MOV  ES, AX             ; ES = DS for string instructions
        PRINT TITLE1

;================ (a) BLOCK TRANSFER OF BYTES =========================
        CLD                     ; DF = 0 -> SI, DI auto-increment
        LEA  SI, SRC
        LEA  DI, DST
        MOV  CX, SRCLEN
        REP  MOVSB              ; copy CX bytes DS:[SI] -> ES:[DI]
        PRINT MA
        PRINT SRC
        PRINT MA2
        PRINT DST

;================ (b) BLOCK TRANSFER OF WORDS =========================
        CLD
        LEA  SI, WSRC
        LEA  DI, WDST
        MOV  CX, 5
        REP  MOVSW              ; copy 5 words
        PRINT MB
        LEA  SI, WDST
        MOV  CX, 5
PW_LP:  LODSW                   ; AX = [SI], SI += 2
        CALL PHEX16
        PRINT SPACE
        LOOP PW_LP

;================ (c) OVERLAPPING BLOCK MOVE ==========================
; Move 8 bytes of OVL two positions higher. Source and destination
; overlap, so the copy must start from the END (DF = 1).
        PRINT MC1
        PRINT OVL
        STD                     ; DF = 1 -> SI, DI auto-decrement
        LEA  SI, OVL+7          ; last source byte
        LEA  DI, OVL+9          ; last destination byte
        MOV  CX, 8
        REP  MOVSB
        CLD
        MOV  OVL, '-'           ; mark the two vacated positions
        MOV  OVL+1, '-'
        MOV  OVL+10, '$'
        PRINT MC2
        PRINT OVL               ; --12345678

;================ (d) FILL A BLOCK ====================================
        CLD
        LEA  DI, FILLB
        MOV  AL, '*'
        MOV  CX, 10
        REP  STOSB              ; store AL in CX bytes at ES:[DI]
        PRINT MD
        PRINT FILLB

;================ (e) STRING LENGTH USING SCASB =======================
        CLD
        LEA  DI, STR1
        MOV  AL, '$'            ; search for terminator
        MOV  CX, 0FFFFh
        REPNE SCASB
        NOT  CX                 ; CX = chars scanned (incl. '$')
        DEC  CX                 ; exclude '$'
        MOV  STRLENV, CL        ; 11 = 0Bh
        SHOW8 ME, STRLENV

;================ (f) SEARCH A CHARACTER ==============================
        CLD
        LEA  DI, STR1
        MOV  AL, SCHAR
        MOV  CL, STRLENV
        MOV  CH, 0
        REPNE SCASB             ; stop when [DI] = AL
        MOV  SPOS, 0
        JNE  NOTFND
        LEA  AX, STR1
        SUB  DI, AX             ; DI points one past the match
        MOV  AX, DI
        MOV  SPOS, AL           ; 1-based position = 4
NOTFND: SHOW8 MF, SPOS

;================ (g) STRING COMPARISON ===============================
        CLD
        LEA  SI, CMPA
        LEA  DI, CMPB
        MOV  CX, CMPLEN
        REPE CMPSB              ; compare while equal
        PRINT MG
        JE   SAME
        MOV  CMPRES, 1
        LEA  AX, CMPA
        SUB  SI, AX
        MOV  AX, SI
        MOV  MISPOS, AL         ; first mismatch at position 8
        PRINT MG_NE
        MOV  AL, MISPOS
        CALL PHEX8
        JMP  CMP_END
SAME:   MOV  CMPRES, 0
        PRINT MG_EQ
CMP_END:

;================ (h) REVERSE A STRING ================================
        LEA  SI, RSTR           ; SI -> first char of source
        LEA  DI, RREV+RLEN-1    ; DI -> last position of destination
        MOV  CX, RLEN
REV_LP: CLD
        LODSB                   ; AL = [SI], SI++
        STD
        STOSB                   ; [DI] = AL, DI--
        LOOP REV_LP
        CLD
        PRINT MH
        PRINT RREV              ; RETUPMOC

;================ (i) PALINDROME CHECK ================================
        PRINT MI1
        LEA  SI, PAL1
        CALL PALIN
        PRINT MI2
        LEA  SI, PAL2
        CALL PALIN

;================ (j) LOWER CASE -> UPPER CASE ========================
        CLD
        LEA  SI, LOWS
        LEA  DI, UPS
UC_LP:  LODSB
        CMP  AL, '$'
        JE   UC_END
        CMP  AL, 'a'
        JB   UC_ST
        CMP  AL, 'z'
        JA   UC_ST
        SUB  AL, 20h            ; 'a'-'A' = 20h
UC_ST:  STOSB
        JMP  UC_LP
UC_END: STOSB                   ; copy the '$'
        PRINT MJ
        PRINT UPS

;================ (k) COUNT VOWELS ====================================
        CLD
        LEA  SI, VSTR
        XOR  BL, BL             ; vowel counter
VW_LP:  LODSB
        CMP  AL, '$'
        JE   VW_END
        LEA  DI, VOWELS
        MOV  CX, 10
        REPNE SCASB             ; is AL in the vowel table?
        JNE  VW_LP
        INC  BL
        JMP  VW_LP
VW_END: MOV  VCOUNT, BL         ; 10 = 0Ah
        SHOW8 MK, VCOUNT

        PRINT DONE
        MOV  AH, 4Ch
        INT  21h
MAIN ENDP

;------------------------------------------------------------------
; PALIN : checks if the '$'-terminated string at DS:SI is a
;         palindrome. Prints result, PALRES = 1 (yes) / 0 (no)
;------------------------------------------------------------------
PALIN PROC
        PUSH AX
        PUSH CX
        PUSH SI
        PUSH DI
        MOV  DI, SI             ; find end of string
PL_FE:  CMP  BYTE PTR [DI], '$'
        JE   PL_GOT
        INC  DI
        JMP  PL_FE
PL_GOT: DEC  DI                 ; DI -> last character
PL_CMP: CMP  SI, DI
        JAE  PL_YES             ; pointers met -> palindrome
        MOV  AL, [SI]
        CMP  AL, [DI]
        JNE  PL_NO
        INC  SI
        DEC  DI
        JMP  PL_CMP
PL_YES: MOV  PALRES, 1
        PRINT M_PAL
        JMP  PL_RET
PL_NO:  MOV  PALRES, 0
        PRINT M_NPAL
PL_RET: POP  DI
        POP  SI
        POP  CX
        POP  AX
        RET
PALIN ENDP

;------------------------- HELPER ROUTINES ----------------------------
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
