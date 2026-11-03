;=======================================================================
; EXPERIMENT 6 : INTERRUPT HANDLING AND INTERRUPT-DRIVEN PROGRAMMING
;                USING 8086 MICROPROCESSOR
; Processor    : 8086
; Simulator    : EMU8086  /  MASM or TASM under DOSBox
;
; AIM : To study the 8086 interrupt structure and Interrupt Vector
;       Table (IVT) and to write ALPs that
;       (a) use DOS software interrupt services (INT 21h)
;       (b) use a BIOS software interrupt (INT 10h)
;       (c) install a USER-DEFINED interrupt service routine (INT 60h)
;           using DOS functions 35h (get vector) and 25h (set vector)
;       (d) read the IVT directly  (vector address = type x 4)
;       (e) handle the OVERFLOW interrupt (type 4) raised by INTO
;       (f) perform interrupt-driven programming with the TIMER
;           interrupt INT 1Ch (18.2 times per second) - vector
;           installed by writing the IVT directly with CLI / STI
;       and finally restore every original vector.
;
; 8086 interrupt response : push FLAGS, clear IF & TF, push CS,
; push IP, load new CS:IP from 0000:(type*4). ISR ends with IRET.
;
; NOTE for EMU8086 : section (a) waits for one key press. If the
; timer interrupt is not being simulated, press any key during
; section (f) to skip the wait.
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
OLD60_OFF DW ?                  ; saved original vectors
OLD60_SEG DW ?
OLD04_OFF DW ?
OLD04_SEG DW ?
OLD1C_OFF DW ?
OLD1C_SEG DW ?

KEYIN   DB ?
CNT60   DB 0                    ; times INT 60h ISR executed
OVFCNT  DB 0                    ; times overflow ISR executed
TICKS   DW 0                    ; incremented by timer ISR
SECS    DB 0

;--------- MESSAGES ---------
TITLE1  DB 0Dh,0Ah,'===== EXP 6 : INTERRUPT HANDLING =====$'
HSUF    DB 'h$'
COLON   DB ':$'
MA      DB 0Dh,0Ah,0Dh,0Ah,'(a) INT 21h services - press any key : $'
MA2     DB 0Dh,0Ah,'    ASCII code of key = $'
MA3     DB '   case toggled -> $'
MBB     DB 0Dh,0Ah,'(b) INT 10h (BIOS teletype) : ',0
BIOSMSG DB 'Hello from BIOS INT 10h!',0
MC      DB 0Dh,0Ah,'(c) Installing user ISR for INT 60h ...$'
MC_OLD  DB 0Dh,0Ah,'    Old INT 60h vector (seg:off) = $'
MC_NEW  DB 0Dh,0Ah,'    New INT 60h vector (seg:off) = $'
ISRMSG  DB 0Dh,0Ah,'    >> INT 60h ISR executed, count = $'
MD      DB 0Dh,0Ah,'(d) IVT entry at 0000:0180h      = $'
ME      DB 0Dh,0Ah,'(e) Overflow interrupt (INTO, type 4)$'
ME1     DB 0Dh,0Ah,'    70h + 30h (signed) -> INTO$'
ME2     DB 0Dh,0Ah,'    10h + 20h (signed) -> INTO$'
OVFMSG  DB 0Dh,0Ah,'    >> TYPE 4 ISR : OVERFLOW detected!$'
ME3     DB 0Dh,0Ah,'    Overflow ISR call count = $'
MF      DB 0Dh,0Ah,'(f) Timer interrupt INT 1Ch (interrupt-driven delay)$'
MF1     DB 0Dh,0Ah,'    >> 1 second elapsed (18 ticks), seconds = $'
MF_KEY  DB 0Dh,0Ah,'    Wait skipped by key press.$'
MG      DB 0Dh,0Ah,'(g) All original vectors restored.$'
DONE    DB 0Dh,0Ah,0Dh,0Ah,'Program completed.',0Dh,0Ah,'$'

;------------------------------ CODE ----------------------------------
.CODE
MAIN PROC
        MOV  AX, @DATA
        MOV  DS, AX
        PRINT TITLE1

;================ (a) DOS INTERRUPT SERVICES ==========================
        PRINT MA                ; INT 21h / AH=09h : display string
        MOV  AH, 01h            ; INT 21h / AH=01h : read key with echo
        INT  21h
        MOV  KEYIN, AL
        PRINT MA2
        MOV  AL, KEYIN
        CALL PHEX8
        PRINT HSUF
        PRINT MA3
        MOV  DL, KEYIN
        CMP  DL, 'A'
        JB   NOT_LET
        CMP  DL, 'z'
        JA   NOT_LET
        XOR  DL, 20h            ; toggle upper/lower case
NOT_LET:
        MOV  AH, 02h            ; INT 21h / AH=02h : display character
        INT  21h

;================ (b) BIOS INTERRUPT INT 10h ==========================
        LEA  SI, MBB
        CALL BIOSPUTS
        LEA  SI, BIOSMSG
        CALL BIOSPUTS

;================ (c) INSTALL USER ISR FOR INT 60h ====================
        PRINT MC
        MOV  AX, 3560h          ; AH=35h get vector, AL=60h
        INT  21h                ; ES:BX = old vector
        MOV  OLD60_OFF, BX
        MOV  OLD60_SEG, ES
        PRINT MC_OLD
        MOV  AX, ES
        CALL PHEX16
        PRINT COLON
        MOV  AX, BX
        CALL PHEX16

        PUSH DS
        MOV  AX, CS             ; ISR is in the code segment
        MOV  DS, AX
        MOV  DX, OFFSET ISR60   ; DS:DX = new ISR address
        MOV  AX, 2560h          ; AH=25h set vector, AL=60h
        INT  21h
        POP  DS

        MOV  AX, 3560h          ; read back to verify
        INT  21h
        PRINT MC_NEW
        MOV  AX, ES
        CALL PHEX16
        PRINT COLON
        MOV  AX, BX
        CALL PHEX16

        INT  60h                ; invoke the user interrupt 3 times
        INT  60h
        INT  60h

;================ (d) READ IVT DIRECTLY ===============================
        PUSH ES
        XOR  AX, AX
        MOV  ES, AX             ; ES = 0000h (IVT segment)
        MOV  BX, ES:[60h*4]     ; offset  at 0000:0180h
        MOV  CX, ES:[60h*4+2]   ; segment at 0000:0182h
        POP  ES
        PRINT MD
        MOV  AX, CX
        CALL PHEX16
        PRINT COLON
        MOV  AX, BX
        CALL PHEX16

;================ (e) OVERFLOW INTERRUPT - TYPE 4 =====================
        PRINT ME
        MOV  AX, 3504h          ; save old type-4 vector
        INT  21h
        MOV  OLD04_OFF, BX
        MOV  OLD04_SEG, ES
        PUSH DS
        MOV  AX, CS             ; ISR is in the code segment
        MOV  DS, AX
        MOV  DX, OFFSET ISR04
        MOV  AX, 2504h          ; install new type-4 ISR
        INT  21h
        POP  DS

        PRINT ME1
        MOV  AL, 70h            ; +112
        ADD  AL, 30h            ; +48  -> 160 > 127 : OF = 1
        INTO                    ; OF=1 -> INT 4 is executed

        PRINT ME2
        MOV  AL, 10h
        ADD  AL, 20h            ; 30h : OF = 0
        INTO                    ; OF=0 -> no interrupt

        PRINT ME3
        MOV  AL, OVFCNT         ; expected 01
        CALL PHEX8
        PRINT HSUF

;================ (f) TIMER INTERRUPT 1Ch (interrupt driven) ==========
        PRINT MF
        PUSH ES
        XOR  AX, AX
        MOV  ES, AX
        CLI                     ; disable interrupts while editing IVT
        MOV  AX, ES:[1Ch*4]
        MOV  OLD1C_OFF, AX
        MOV  AX, ES:[1Ch*4+2]
        MOV  OLD1C_SEG, AX
        MOV  WORD PTR ES:[1Ch*4], OFFSET ISR1C
        MOV  ES:[1Ch*4+2], CS
        MOV  TICKS, 0
        STI                     ; enable interrupts
        POP  ES

        MOV  SECS, 0
WAIT_T: CMP  TICKS, 18          ; 18 ticks ~ 1 second
        JB   CHK_KEY
        MOV  TICKS, 0
        INC  SECS
        PRINT MF1
        MOV  AL, SECS
        CALL PHEX8
        CMP  SECS, 3
        JAE  T_DONE             ; stop after 3 seconds
CHK_KEY:
        MOV  AH, 01h            ; BIOS INT 16h : key available?
        INT  16h
        JZ   WAIT_T             ; ZF=1 -> no key, keep waiting
        MOV  AH, 00h            ; remove the key from buffer
        INT  16h
        PRINT MF_KEY
T_DONE:

;================ (g) RESTORE ALL ORIGINAL VECTORS ====================
        PUSH ES                 ; INT 1Ch - direct IVT write
        XOR  AX, AX
        MOV  ES, AX
        CLI
        MOV  AX, OLD1C_OFF
        MOV  ES:[1Ch*4], AX
        MOV  AX, OLD1C_SEG
        MOV  ES:[1Ch*4+2], AX
        STI
        POP  ES

        PUSH DS                 ; INT 04h - DOS function 25h
        MOV  DX, OLD04_OFF
        MOV  AX, OLD04_SEG
        MOV  DS, AX
        MOV  AX, 2504h
        INT  21h
        POP  DS

        PUSH DS                 ; INT 60h - DOS function 25h
        MOV  DX, OLD60_OFF
        MOV  AX, OLD60_SEG
        MOV  DS, AX
        MOV  AX, 2560h
        INT  21h
        POP  DS
        PRINT MG

        PRINT DONE
        MOV  AH, 4Ch
        INT  21h
MAIN ENDP

;=====================================================================
;                   INTERRUPT SERVICE ROUTINES
;=====================================================================
; ISR60 : user-defined software interrupt
ISR60 PROC FAR
        PUSH AX
        PUSH DX
        PUSH DS
        MOV  AX, @DATA          ; ISR must set up its own DS
        MOV  DS, AX
        INC  CNT60
        PRINT ISRMSG
        MOV  AL, CNT60
        CALL PHEX8
        POP  DS
        POP  DX
        POP  AX
        IRET                    ; pop IP, CS, FLAGS
ISR60 ENDP

; ISR04 : overflow interrupt (type 4) - called by INTO when OF = 1
ISR04 PROC FAR
        PUSH AX
        PUSH DX
        PUSH DS
        MOV  AX, @DATA
        MOV  DS, AX
        INC  OVFCNT
        PRINT OVFMSG
        POP  DS
        POP  DX
        POP  AX
        IRET
ISR04 ENDP

; ISR1C : timer tick (called by the BIOS INT 08h handler ~18.2 Hz).
;         Hardware-driven, so it must be short and must NOT call DOS.
ISR1C PROC FAR
        PUSH AX
        PUSH DS
        MOV  AX, @DATA
        MOV  DS, AX
        INC  TICKS
        POP  DS
        POP  AX
        IRET
ISR1C ENDP

;------------------------- HELPER ROUTINES ----------------------------
; BIOSPUTS : print 0-terminated string at DS:SI with BIOS INT 10h/0Eh
BIOSPUTS PROC
        PUSH AX
        PUSH BX
        PUSH SI
BP_LP:  MOV  AL, [SI]
        CMP  AL, 0
        JE   BP_END
        MOV  AH, 0Eh            ; teletype output
        MOV  BH, 0              ; page 0
        INT  10h
        INC  SI
        JMP  BP_LP
BP_END: POP  SI
        POP  BX
        POP  AX
        RET
BIOSPUTS ENDP

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
