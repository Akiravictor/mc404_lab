#include "api_robot2.h"
    
	.global set_motor_speed
	.global set_motors_speed
	.global read_sonar
	.global read_sonars
	.global add_alarm
	.global get_time
	.global set_time
   
   
.align 4

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@			MOTORS			@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


set_motor_speed:
	stmfd sp!, {r4-r6, r10-r11, lr} @ Save the callee-save registers
		                            @ and the return address.
        
	checaMotor:
		cmp r0, #1
		bls checaVelocidade
		@ If r0 is higher than #1, return -1 (Invalid id)
		mov r0,#-1    
		ldmfd sp!, {r4-r6, r10-r11, pc}

	checaVelocidade:
		cmp r1,#63
		bls liga_motor
		@ If speed is higher than #63, return -2 (Invalid speed)
		mov r0,#-2
		ldmfd sp!, {r4-r6, r10-r11, pc}

	liga_motor:
		mov r3,#9               @ Load motor call
		mov r7, r3            
		svc 0x0                 @ Make syscall.

	mov r0,#0
	ldmfd sp!, {r4-r6, r10-r11, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

set_motors_speed:
    stmfd sp!, {r4-r6, r10-r11, lr} @ Save the callee-save registers
					                @ and the return address.
        
    cmp r0,#63
    bls verificaMotor_2
	@ If speed for motor0 is higher than #63, return -1 (Invalid speed for motor0)
    mov r0,#-1
    ldmfd sp!, {r4-r6, r10-r11, pc}
        
    verificaMotor_2:
		cmp r1,#63
		bls liga_motores
		@ If speed for motor1 is higher than #63, return -2 (Invalid speed for motor1)
		mov r0,#-2
		ldmfd sp!, {r4-r6, r10-r11, pc}    
        
    liga_motores:
		mov r7, #10             @ Load motors call
		svc 0x0                 @ Make syscall.

	mov r0,#0
	ldmfd sp!, {r4-r6, r10-r11, pc}
    
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@			SONARES			@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    read_sonar:
        stmfd sp!, {r4-r6, r10-r11, lr}
        
        cmp r0,#15
        bls saida
        @ If sonar_id is higher than 15, return -1 (Invalid sonar_id)
        mov r0,#-1
        ldmfd sp!, {r4-r6, r10-r11, pc}

        saida:
            mov r7, #8            @ Make syscall.
            svc 0x0                  
            
        ldmfd sp!, {r4-r6, r10-r11, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@			SYSTEM			@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    add_alarm:
        stmfd sp!, {r4-r6, r10-r11, lr}
        mov r7, #13
        svc 0x0
            
        ldmfd sp!, {r4-r6, r10-r11, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   
    get_time:
        stmfd sp!, {r4-r6, r10-r11, lr}
        mov r7, #11
        svc 0x0
            
        ldmfd sp!, {r4-r6, r10-r11, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    set_time:
        stmfd sp!, {r4-r6, r10-r11, lr}
        mov r7, #12
        svc 0x0
            
        ldmfd sp!, {r4-r6, r10-r11, pc}