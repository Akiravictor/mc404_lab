#include "api_robot2.h"
    
    .global set_motor_speed
    .global set_motors_speed
    .global read_sonar
    .global read_sonars
    .global set_alarm
    .global get_time
    .global set_time
   
   
.align 4
@@inicio da programação das syscalls

@@ MOTORES
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@ ainda falta definir o que é uma velocidade inválida  -> inválida é maior que 63
    
    set_motor_speed:
        stmfd sp!, {r4-r6, r10-r11, lr} @ Save the callee-save registers
                                        @ and the return address.
        
        checaMotor:
            cmp r0, #1
            bls checaVelocidade
              @else
                mov r0,#-1    
                ldmfd sp!, {r4-r6, r10-r11, pc}

        checaVelocidade:
        @else
          cmp r1,#63
          bls liga_motor
          mov r0,#-2
          
        ldmfd sp!, {r4-r6, r10-r11, pc}

        liga_motor:
            mov r3,#9               @carrega a chamada do motor             
            mov r7, r3            
            svc 0x0                 @ Faz a chamada da syscall.
    @Lembrar de colocar o 0 em R0 após setar a velocidade
        ldmfd sp!, {r4-r6, r10-r11, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    set_motors_speed:
        stmfd sp!, {r4-r6, r10-r11, lr} @ Save the callee-save registers
                        @ and the return address.
                        
                        
        @ainda falta definir o que são velocidades válidas        
        
        cmp r0,#70               @verifica o valor da velocidade do motor0
        bls verificaMotor_2
        mov r0,#-1
        ldmfd sp!, {r4-r6, r10-r11, pc}
        
        verificaMotor_2:

        cmp r1,#70               @verifica o valor da velocidade do motor1
        bls liga_motores
        mov r0,#-2
        ldmfd sp!, {r4-r6, r10-r11, pc}    
        
        liga_motores:           @caso os valroes sejam corretos, executa a chamada da syscall
        mov r7, #10             @ Identifica a syscall 124 (write_motors).
        svc 0x0                 @ Faz a chamada da syscall.

    @setar r0 em 0 dentro do soul;

    ldmfd sp!, {r4-r6, r10-r11, pc}
    
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        
@@ SONARES
        
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    read_sonar:
        stmfd sp!, {r4-r6, r10-r11, lr}
        
        cmp r0,#15
        bls saida
        
        mov r0,#-1
        
        ldmfd sp!, {r4-r6, r10-r11, pc}

        saida:
            mov r7, #8            @ Identifica a syscall 125 (read_sonar).
            svc 0x0                  
            
        ldmfd sp!, {r4-r6, r10-r11, pc}
     
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@ SYSTEM

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    set_alarm:
        stmfd sp!, {r4-r6, r10-r11, lr}
        mov r7, #13
        svc 0x0
            
        ldmfd sp!, {r4-r6, r10-r11, pc}
    

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    get_time:
        stmfd sp!, {r4-r6, r10-r11, lr}
        mov r7, #11
        svc 0x0
            
        ldmfd sp!, {r4-r6, r10-r11, pc}
    

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    set_time:
        stmfd sp!, {r4-r6, r10-r11, lr}
        mov r7, #12
        svc 0x0
            
        ldmfd sp!, {r4-r6, r10-r11, pc}
    

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


