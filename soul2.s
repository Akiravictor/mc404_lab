.org 0x0
.section .iv,"a";

_start:     
  

@inicializando o vetor de exce��es

    interrupt_vector:
            b RESET_HANDLER
    .org 0x8
            b SYS_CALL
    .org 0x18
            b IRQ_HANDLER

.org 0x100
.text

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ RESET HANDLER @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

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

@Habilita a interrup��o do canal 1
	ldr r1,=GPT_PR
	mov r2,#0
	str r2, [r1]  

	ldr r1,=GPT_OCR1
	mov r2, #12
	str r2,[r1] 

	ldr r1,=GPT_IR
	mov r2,#1       
	str r2,[r1]

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Pilha do Supervisor @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	ldr sp, =PILHA_SUDO

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Pilha do IRQ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@ CONFIGURA MODO IRQ
    mrs r0, CPSR
    bic r0, r0, #0x1F
    orr r0, r0, #0x12
    msr CPSR_c, r0

    ldr sp, =PILHA_IRQ    

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Pilha do Usu�rio @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@ CONFIGURA MODO SYSTEM(USER)
@ sp do modo SYSTEM e do modo USER eh o mesmo
    mrs r0, CPSR
    bic r0, r0, #0x1F
    orr r0, r0, #0x1F
    msr CPSR_c, r0

    ldr sp, =PILHA_USER

@registradores do perif�rico
    .set DR,    0x53F84000
    .set GDIR,  0x53F84004
    .set PSR ,  0x53F84008

@ Configurando o GPIO 
@configurando os pinos de entrada e sa�da 
	ldr r1, =GDIR
	ldr r2, =0xFFFC003E
	str r2,[r1]

@ Configurando o DR 
@configurando os pinos de entrada e sa�da 
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

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ TZIC @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

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

@mudando de usu�rio
	msr  CPSR_c, #0x10        @ USER mode
	.set TZIC_BASE, 0x0FFFC000
	.set TZIC_INTCTRL, 0x0
	.set TZIC_INTSEC1, 0x84 
	.set TZIC_ENSET1, 0x104
	.set TZIC_PRIOMASK, 0xC
	.set TZIC_PRIORITY9, 0x424
      
@pula para a sa��o do texto; definido no makefile do loco;
	.set user, 0x77802000
	ldr r0, =user
	bx r0
         
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ IRQ HANDLER @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

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

	cmp r4,#1                @verifico se o alarme est� ativo
	beq ChamaAlarme 

	add r4, r4,#12
	sub r1,r1,#1

	cmp r1,#0

	bne Verifica_alarmes
	b Sai_irq_handler

ChamaAlarme:  
	stmfd sp!, {lr}

@carrega o tempo do alarme
	add r3, r3,#4   
	ldr r4, [r3]

@Compara codel m o tempo do sistema; sendo menor ou igual, eu chamo a fun��o do alarme
	cmp r4,r0
	bls ChamaFuncaoDoAlarme

@retorna o fluxo do programa para o Verifica_alarmes
	ldmfd sp!, {lr}
	mov pc,lr 

ChamaFuncaoDoAlarme:
	stmfd sp!, {lr}

@ajusta o contador de alarmes
	sub r1,r1,#1
	ldr r2, =NumAlarmes
	str r1, [r2]

@desativa o alarme; 
	mov r1,#0
	movs r2,r3
	sub r2,r2,#4
	str r1,[r2]

@transfere o fluxo do programa para a fun��o
	add r3,r3,#4
	stmfd sp!, {r6}

	ldr r2,[r3]
	msr CPSR_c, #0x10
	blx r2;

	mov r7,#6
	svc 0x0

@retorna o fluxo de programa para o #ChamaAlarme
	add r3,r3,#4 @ajusta o endere�o para verificar o n�mero de valida��o;

	ldmfd sp!, {lr}
	sub lr, lr, #4
	mov pc,lr 

Sai_irq_handler:
	ldmfd sp!,{r0-r12}
	sub lr, lr, #4
	movs pc, lr

	.set MAX_ALARMES, 16
	.set tamanho_vetor, 16

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Syscalls @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

SYS_CALL:

	cmp r7,#6
	beq sudo

	cmp r7, #8
	beq read_sonar

	cmp r7, #9
	beq set_motor_speed

	cmp r7, #10
	beq set_motors_speed

	cmp r7, #11
	beq get_time

	cmp r7, #12
	beq set_time

	cmp r7, #13
	beq add_alarm

	movs pc,lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Syscall Methods @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

sudo:

	mov r6,#0x12
	msr CPSR_c,r6
	ldmfd sp!,{r6}
	mov pc, lr

	set_motor_speed:
		stmfd sp!, {r4-r11}
		stmfd sp!, {lr}

		msr  CPSR_c, #0x13

		@ r1 guarda a velocidade a ser setada no motor0
		@ r2 guarda o endere�o do PSR
		@ r3 guarda o valor do PSR
		@ r4 � auxiliar; 

		ldr r2, =DR
		ldr r3, [r2]
              
		cmp r0,#1 @verifica qual motor foi ativado              
		beq motor1
		motor0:           @dir
			ldr r6,=0xFE03FFFF
			mov r7,#19
			b ligarMotor
		motor1:           @esq
			ldr r6,=0x01FFFFFF
			mov r7,#26          

		ligarMotor:
			and r4,r3,r6                  @ � zerado, e o novo mapa � guardado em r4
			lsl r1,r7
			orr  r3,r4,r1                 @ Guarda em r3 o valor do sinal a ser enviado � placa;
			ldr r2, =DR
			str r3, [r2]                  @ salva a velocidade no registrador;
			ldmfd sp!, {r4-r11}
			movs pc,lr       
        
	set_motors_speed:
		stmfd sp!, {r4-r11,lr}
		msr  CPSR_c, #0x13
		
		ldr r2,=DR
		ldr r3, [r2]
		
		ligarMotores:
			ldr r6,=0x0003FFFF 
			and r4,r3,r6				@ � zerado, e o novo mapa � guardado em r4

			mov r5, r0, lsl #26         @ coloca o valor da velocidade do motor 0 na posi��o de altera��o de velocidade  
			mov r6, r1,lsl #19			@ coloca o valor da velocidade na posi��o de altera��o de velocidade do motor1
			orr r5, r5, r6
			orr r3, r4, r5				@ Guarda em r3 o valor do sinal a ser enviado � placa;
    
			ldr r2, =DR
			str r3, [r2]			    @salva a velocidade no registrador;  

			ldmfd sp!, {r4-r11, lr}
			movs pc,lr 
            
	read_sonar: 
		stmfd sp!, {r4-r11, lr}
		msr  CPSR_c, #0x13
		@guardando o sonar_id (r0) no sonar_mux          
		ldr r2,=DR
		ldr r3, [r2]
		ldr r6, =0xFFFFFFC3              
		and r4, r3, r6                  @ � zerado, e o novo mapa � guardado em r4
		mov r0, r0 , lsl #2             @ coloca o valor do sonar_id locomovido 2 
		orr r3, r4, r0                  @ Guarda em r3 o valor do sinal a ser enviado � placa;
		str r3, [r2]    
          
		@eleva o Trigger a 1 com dalay de 10ms
		ldr r2,=DR
		ldr r3, [r2]
		mov r5, #2                       @ eleva tigger a 1 0x2 = 10 coloca o valor do sonar_id                                     
		orr r3, r3, r5                   @ Guarda em r3 o valor do sinal a ser enviado � placa;
		str r3, [r2]                     @salva a velocidade no registrador;

		@eleva o Trigger a 0
		ldr r2, =DR
		ldr r3, [r2]          
		ldr r6, =0xFFFFFFFD            
		and r3, r3, r6                   @ � zerado, e o novo mapa � guardado em r4
		str r3, [r2]                     @salva a velocidade no registrador;

		@verifica a flag
		mov r4, #0x1                     @mascara para zerar a esquerda
		flag:
			ldr r2, =DR
			ldr r1, [r2]
			and r5, r1, r4
			cmp r5, #1
			bne flag                     @loop enquanto flag nao � 1
          
		@pegando a distancia
		ldr r3, [r2]
		mov r4, r3, lsr #6               @ignora o mux, tigger e flag
		ldr r6,=0xFFF			         @ zerar a esquerda   
		and r0, r4, r6
		ldmfd sp!, {r4-r11, lr}
		movs pc,lr              
                  
	get_time:
		stmfd sp!, {r4-r11, lr}
		stmfd sp!, {lr}
		msr  CPSR_c, #0x13

		ldr r1, =Timer
		ldr r0, [r1]

		ldmfd sp!, {r4-r11, lr}
		movs pc,lr 

	set_time:
		stmfd sp!, {r4-r11, lr}
		stmfd sp!, {lr}
		msr  CPSR_c, #0x13

		ldr r1, =Timer
		str r0, [r1]

		ldmfd sp!, {r4-r11, lr}
		movs pc,lr 

	add_alarm:
		stmfd sp!, {r4-r11,lr}
		msr  CPSR_c, #0x13

		@r0 possui o endere�o de uma fun��o
		@r1 possui o tempo que deve ser chamado

		ldr r3, =Timer
		ldr r3, [r3]
		@carrego em r3 o valor do Timer
		ldr r4, =Alarmes
		@endere�o inicial dos Alarmes
		ldr r5, =NumAlarmes
		ldr r5, [r5]
		@carrego em r5 o n�mero de Alarmes
		cmp r5, #MAX_ALARMES            @Verifico a quantidade de alarmes 
		bls Testa_tempo

		mov r0, #-1
		ldmfd sp!, {r4-r11, lr}
		movs pc,lr       

		Testa_tempo:					@adicionar um bit para verificar se o alarme foi ou n�o ativado;
			cmp r1,r3                   @tempo do alarme � maior que o tempo de sistema
			bhi adicionaAlarme

			mov r0, #-2
			ldmfd sp!, {r4-r11, lr}
			movs pc,lr 
        
		adicionaAlarme:
			mov r9, r5
			ldr r6, [r4]    
			cmp r6, #0
			beq novo_alarme     
			add r4,r4,#12
			sub r9,r9,#1
			cmp r9,#0
			bhi adicionaAlarme

		novo_alarme:
			add r5,r5,#1
			ldr r3,=NumAlarmes
			str r5, [r3]
			mov r9,#1
			str r9, [r4]            @salva o valor de verifica��o
			add r4,r4, #4
			str r1, [r4]            @salva o tempo na dada posi��o do vetor
			add r4,r4, #4
			str r0, [r4]            @salva a fun��o na dada posi��o do vetor                
			ldmfd sp!, {r4-r11, lr}
			movs pc,lr 

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Data @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.data
.org 0xFFF

Timer:
	.word 0
    
NumAlarmes:
	.word 0

.align 4

Alarmes:
	.skip 204       @alocando 204 bytes de mem�ria -> (4 + 4 + 4)-> ativo ou n�o -> tempo, endere�o da fun��o a ser chamada
    
PILHA_SUDO:
	.skip 1000
    
PILHA_IRQ:
	.skip 1000
    
PILHA_USER:
	.skip 1000