; EXPERIMENT 2
; Logical and Shift Operations
; 8086 Microprocessor

ORG 100H

; AND Operation
MOV AL, 0FH
MOV BL, 0AH
AND AL, BL
MOV [2000H], AL

; OR Operation
MOV AL, 0FH
MOV BL, 0AH
OR AL, BL
MOV [2001H], AL

; XOR Operation
MOV AL, 0FH
MOV BL, 0AH
XOR AL, BL
MOV [2002H], AL

; NOT Operation
MOV AL, 55H
NOT AL
MOV [2003H], AL

; Shift Left
MOV AL, 05H
SHL AL, 1
MOV [2004H], AL

; Shift Right
MOV AL, 20H
SHR AL, 1
MOV [2005H], AL

; 16-bit Shift Left
MOV AX, 1234H
SHL AX, 1
MOV [2006H], AX

; 16-bit Shift Right
MOV AX, 1234H
SHR AX, 1
MOV [2008H], AX

HLT
