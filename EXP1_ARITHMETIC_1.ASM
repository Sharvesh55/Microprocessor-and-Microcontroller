; EXPERIMENT 1
; 8-bit and 16-bit Arithmetic Operations
; 8086 Microprocessor

ORG 100H

; 8-bit Addition
MOV AL, 25H
MOV BL, 15H
ADD AL, BL
MOV [2000H], AL

; 8-bit Subtraction
MOV AL, 35H
MOV BL, 15H
SUB AL, BL
MOV [2001H], AL

; 8-bit Multiplication
MOV AL, 05H
MOV BL, 04H
MUL BL
MOV [2002H], AX

; 8-bit Division
MOV AX, 0014H
MOV BL, 04H
DIV BL
MOV [2004H], AL
MOV [2005H], AH

; 16-bit Addition
MOV AX, 1234H
MOV BX, 1111H
ADD AX, BX
MOV [2006H], AX

; 16-bit Subtraction
MOV AX, 3456H
MOV BX, 1234H
SUB AX, BX
MOV [2008H], AX

; 16-bit Multiplication
MOV AX, 0010H
MOV BX, 0005H
MUL BX
MOV [200AH], AX
MOV [200CH], DX

; 16-bit Division
MOV DX, 0000H
MOV AX, 0064H
MOV BX, 0005H
DIV BX
MOV [200EH], AX
MOV [2010H], DX

HLT
