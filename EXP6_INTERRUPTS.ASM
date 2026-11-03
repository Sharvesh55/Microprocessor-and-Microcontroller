; EXPERIMENT 6
; Interrupt Handling
; 8086 Microprocessor
; DOS Interrupt 21H

ORG 100H

; Display Character A
MOV AH, 02H
MOV DL, 'A'
INT 21H

; Display Character B
MOV AH, 02H
MOV DL, 'B'
INT 21H

; Keyboard Input
MOV AH, 01H
INT 21H

; Store Input Character
MOV [2000H], AL

; Exit Program
MOV AH, 4CH
INT 21H

HLT
