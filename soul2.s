.org 0x0
.section .iv,"a";

_start:     
  

@inicializando o vetor de exceções

    interrupt_vector:
            b RESET_HANDLER
    .org 0x8
            b SYS_CALL
    .org 0x18
            b IRQ_HANDLER

.org 0x100
.text

@@@@@@	RESET HANDLER	@@@@@@

RESET_HANDLER:

	ldr r1,=Timer    
	ldr r0,[r1]

@Configurando o GPT   
@registradores do GPT
	.set GPT_CR,   0x53FA0000 
	.set GPT_PR,   0x53FA0004 
	.set GPT_OCR1, 0x53FA0010
	.set GPT_SR,   0x53FA0008
	.set GPT_IR,   0x53FA000C

@Set interrupt table base address on coprocessor 15.
	ldr r0, =interrupt_vector
	mcr p15, 0, r0, c12, c0, 0

@Zerar o timer

	ldr r2, =Timer
	mov r0,#0
	str r0, [r2]

@ configurar o cl
	ldr r1,=GPT_CR
	mov r2,#0x00000041 
	str r2, [r1]

@Habilita a interrupção do canal 1
	ldr r1,=GPT_PR
	mov r2,#0
	str r2, [r1]  

	ldr r1,=GPT_OCR1
	mov r2, #12
	str r2,[r1] 

	ldr r1,=GPT_IR
	mov r2,#1       
	str r2,[r1]

@@@@@@	Pilha do Supervisor	@@@@@@

	ldr sp, =PILHA_SUDO

@@@@@@ Pilha do IRQ	@@@@@@

@ CONFIGURA MODO IRQ
    mrs r0, CPSR
    bic r0, r0, #0x1F
    orr r0, r0, #0x12
    msr CPSR_c, r0

    ldr sp, =PILHA_IRQ    

@@@@@@	Pilha do Usuário	@@@@@@

@ CONFIGURA MODO SYSTEM(USER)
@ sp do modo SYSTEM e do modo USER eh o mesmo
    mrs r0, CPSR
    bic r0, r0, #0x1F
    orr r0, r0, #0x1F
    msr CPSR_c, r0

    ldr sp, =PILHA_USER

@registradores do periférico
    .set DR,    0x53F84000
    .set GDIR,  0x53F84004
    .set PSR ,  0x53F84008

@ Configurando o GPIO 
@configurando os pinos de entrada e saída 
	ldr r1, =GDIR
	ldr r2, =0xFFFC003E
	str r2,[r1]

@ Configurando o DR 
@configurando os pinos de entrada e saída 
	ldr r1, =DR
	ldr r2, =0xFFFFFFFF
	str r2,[r1]

	ldr r1,=DR
	ldr r3,[r1]

@Inicializa o Vetor do add_alarm
	ldr r1, =Alarmes
	mov r2, #tamanho_vetor

reset_alarmes:
	mov r3, #0
	str r3, [r1]

	add r1, r1, #4
	sub r2, r2, #4

	cmp r2, #0
	bne reset_alarmes

@@@@@@	TZIC	@@@@@@

@ Constantes para os enderecos do TZIC

@ Liga o controlador de interrupcoes
@ R1 <= TZIC_BASE
SET_TZIC:
	ldr    r1, =TZIC_BASE

@ Configura interrupcao 39 do GPT como nao segura
	mov    r0, #(1 << 7)
	str    r0, [r1, #TZIC_INTSEC1]

@ Habilita interrupcao 39 (GPT)
@ reg1 bit 7 (gpt)

	mov    r0, #(1 << 7)
	str    r0, [r1, #TZIC_ENSET1]

@ Configure interrupt39 priority as 1
@ reg9, byte 3

	ldr r0, [r1, #TZIC_PRIORITY9]
	bic r0, r0, #0xFF000000
	mov r2, #1
	orr r0, r0, r2, lsl #24
	str r0, [r1, #TZIC_PRIORITY9]

@ Configure PRIOMASK as 0
	eor r0, r0, r0
	str r0, [r1, #TZIC_PRIOMASK]

@ Habilita o controlador de interrupcoes
	mov    r0, #1
	str    r0, [r1, #TZIC_INTCTRL]

@instrucao msr - habilita inteerrupcoes
	msr CPSR_c, #0x13         @ SUPERVISOR mode, IRQ/FIQ enabledetor

@mudando de usuário
	msr  CPSR_c, #0x10        @ USER mode
	.set TZIC_BASE, 0x0FFFC000
	.set TZIC_INTCTRL, 0x0
	.set TZIC_INTSEC1, 0x84 
	.set TZIC_ENSET1, 0x104
	.set TZIC_PRIOMASK, 0xC
	.set TZIC_PRIORITY9, 0x424
      
@pula para a sação do texto; definido no makefile do loco;
	.set user, 0x77802000
	ldr r0, =user
	bx r0
         
@@@@@@	IRQ HANDLER	@@@@@@

IRQ_HANDLER:

	stmfd sp!,{r0-r12}

	ldr r0,=GPT_SR
	mov r1, #0x1
	str r1,[r0]

	ldr r1,=Timer    
	ldr r0,[r1]
	add r0,r0,#1
@r0 possui o valor do timer
	str r0,[r1]

	ldr r1, =NumAlarmes
	ldr r1,[r1]

	cmp r1,#0
	beq Sai_irq_handler

Verifica_alarmes:

	ldr r3,=Alarmes
	ldr r4, [r3]

	cmp r4,#1                @verifico se o alarme está ativo
	beq ChamaAlarme 

	add r4, r4,#12
	sub r1,r1,#1

	cmp r1,#0

	bne Verifica_alarmes
	b Sai_irq_handler

ChamaAlarme:  
	stmfd sp!, {lr}              @ Save the callee-save registers

@carrego o tempo do alarme
	add r3, r3,#4   
	ldr r4, [r3]

@Comparo codel m o tempo do sistema; sendo menor ou igual, eu chamo a função do alarme
	cmp r4,r0
	bls ChamaFuncaoDoAlarme

@retorno o fluxo do programa para o #Verifica_alarmes
	ldmfd sp!, {lr}
	mov pc,lr 

ChamaFuncaoDoAlarme:
	stmfd sp!, {lr}

@ajusto o contador de alarmes
	sub r1,r1,#1
	ldr r2, =NumAlarmes
	str r1, [r2]

@desativa o alarme; 
	mov r1,#0
	movs r2,r3
	sub r2,r2,#4
	str r1,[r2]

@transfiro o fluxo do programa para a função
	add r3,r3,#4
	stmfd sp!, {r6}

	ldr r2,[r3]
	msr CPSR_c, #0x10
	blx r2;

	mov r7,#6
	svc 0x0

@retorno o flixo de programa para o #ChamaAlarme
	add r3,r3,#4 @ajusta o endereço para verificar o número de validação;

	ldmfd sp!, {lr}
	sub lr, lr, #4
	mov pc,lr 

Sai_irq_handler:
	ldmfd sp!,{r0-r12}
	sub lr, lr, #4
	movs pc, lr

	.set MAX_ALARMES, 16
	.set tamanho_vetor, 16