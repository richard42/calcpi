*********************************************************************************
* calcpi.asm
* Copyright (c) 2025, Richard Goedeken
* All rights reserved.
* 
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************************

***********************************************************
* BASIC code
* 10 PRINT"NUMBER OF DIGITS";:INPUT N
* 15 L=INT(10*N/3):DIM A(1000):Z$="000000":T$="999999"
* 20 FOR I=1 TO L:A(I)=2:NEXT:M=0:P=0:FOR J=1 TO N:Q=0:K=2*L+1
* 30 FOR I=L TO 1 STEP -1:K=K-2:X=10*A(I)+Q*I:Q=INT(X/K):A(I)=X-Q*K:NEXT I
* 40 Y=INT(Q/10):A(1)=Q-10*Y:Q=Y:IF Q=9 THEN M=M+1:GOTO 70
* 50 IF Q=10 THEN PRINT MID$(STR$(P+1),2);LEFT$(Z$,M);:P=0:M=0:GOTO 70
* 60 PRINT MID$(STR$(P),2);LEFT$(T$,M);:P=Q:M=0
* 70 NEXT J:PRINT MID$(STR$(P),2)

***********************************************************
* Startup code

            org         $404

start       orcc        #$50                    * disable interrupts
            ldmd        #1                      * put 6309 into enhanced mode
            ldx         #$0000                  * clear memory where screen will be placed at $0000
            lda         #$60
            clrb
loop1
            sta         ,x+
            sta         ,x+
            decb
            bne         loop1
            ldx         #$FFC6                  * set screen start address in VDG to $0000
            sta         ,x
            sta         2,x
            sta         4,x
            sta         6,x
            sta         8,x
            sta         10,x
            sta         12,x
            sta         $13,x                   * high-speed poke
            
            ldx         #ProgStartAddress       * copy main program to RAM starting at 0200
            ldy         #$0200
            ldw         #ProgEndAddress-$200+1
            tfm         x+,y+
            
            lda         #2                      * set DP to $02 page
            tfr         a,dp
            
            lds         #$400                   * set top of stack to $400
            
            ldd         ,s                      * D = number of digits to print
            ldu         2,s                     * U = number of 16-bit numeric state entries to use

            jmp         CalcPi                  * start the program

***********************************************************
* PI Calculator Code

ProgStartAddress        EQU     *

            org         $0200
            
            * Data area
NumTerms                zmb     2               * L (BASIC)
DigitCounter            zmb     2               * N (BASIC)
ScreenPos               zmb     2
Divisor                 zmb     2               * K (BASIC)
TempX                   zmb     4
NumZeros                zmb     1               * M (BASIC)
NextDigit               zmb     1               * P (BASIC)
LastDigit               zmb     2               * Q (BASIC)

            * Code area
CalcPi
            std         <DigitCounter
            stu         <NumTerms               * save the value of L
            tfr         u,y
            ldd         #2
            ldx         #$400
Init_L1                                         * initialize value of all terms to 2
            std         ,x++
            leay        -1,y
            bne         Init_L1
DigitLoop
            ldd         <NumTerms
            lsld
            addd        #1                      * K = 2*L + 1
            std         <Divisor
            clr         <LastDigit              * Q = 0
            clr         <LastDigit+1
            ldx         #$3fd
            leax        d,x                     * X = address of A(I)
            ldy         <NumTerms
TermLoop
            ldd         <Divisor
            subd        #2
            std         <Divisor                * K = K - 2
            ldd         ,x
            muld        #10
            stq         <TempX
            tfr         y,d
            muld        <LastDigit
            addw        <TempX+2
            adcd        <TempX                  * X = 10*A(I) + Q*I
            divq        <Divisor
            stw         <LastDigit              * Q=INT(X/K)
            std         ,x                      * A(I) = X-Q*K
            leax        -2,x
            leay        -1,y
            bne         TermLoop
            ldd         <LastDigit
            divd        #10
            sta         3,x                     * A(1) = Q-10*Y
            stb         <LastDigit+1            * Q=Y
            cmpb        #9
            bne         NotNine
            inc         <NumZeros
DigitLoopEnd
            ldd         <DigitCounter
            subd        #1
            std         <DigitCounter
            bne         DigitLoop
            lda         <NextDigit
            adda        #$70
            bsr         PrintDigit
            bra         Infinite
NotNine
            cmpb        #10
            bne         NotTen
            lda         <NextDigit
            adda        #$71
            bsr         PrintDigit
            ldb         <NumZeros
            beq         ZerosDone
            lda         #$70
PrintZeros
            bsr         PrintDigit
            decb
            bne         PrintZeros
ZerosDone
            clr         <NumZeros
            clr         <NextDigit
            bra         DigitLoopEnd
NotTen
            lda         <NextDigit
            adda        #$70
            bsr         PrintDigit
            ldb         <NumZeros
            beq         NinesDone
            lda         #$79
PrintNines
            bsr         PrintDigit
            decb
            bne         PrintNines
NinesDone
            lda         <LastDigit+1
            sta         <NextDigit
            clr         <NumZeros
            bra         DigitLoopEnd
            
Infinite    bra         Infinite

PrintDigit
            ldu         <ScreenPos
            sta         ,u+
            cmpu        #$200
            beq         ScrollScreen
PrintEnd
            stu         <ScreenPos
            rts
ScrollScreen
            ldu         #0
ScrollLoop1
            ldx         32,u
            stx         ,u++
            cmpu        #$1E0
            bne         ScrollLoop1
            stu         <ScreenPos
            ldx         #$6060
ScrollLoop2
            stx         ,u++
            cmpu        #$200
            bne         ScrollLoop2
            rts
            
ProgEndAddress          EQU     *

