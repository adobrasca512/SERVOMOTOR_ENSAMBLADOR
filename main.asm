;ADILEM DOBRAS 21911633
.dseg
 tiempo: .db 1; declaro mi variable tiempo.

 .cseg
	.EQU Clock = 16000000 ;frecuencia de reloj, en Hz
	.EQU Baud = 9600;variables. velocidad de transmisión deseada (bits por segundo)
	.EQU UBRRvalue = Clock/(Baud*16) - 1 ;formula para calcula el valor que se colocará en UBRR0H:L
	.ORG 0x0000
	 ;punto de entrada en el inicio del sistema
	 jmp looP                      ;ir al programa princiapal para saltar el Vector de Interrupciones
	.ORG 0x0032 ;puntos de entrada en vectores de interrupción para USART0
		JMP USART0_reception_completed    
			 ;saltar a la rutina de manejo de interrupciones cuando ocurre este INT
		RETI ;Solo funciona con  interrupciones                           ;saltar a la rutina de manejo de interrupciones cuando ocurre este INT
		RETI  ;solo va al porg. principal                              ;saltar a la rutina de manejo de interrupciones cuando ocurre este INT
 	
	.org 0x0100;.org definir un espacio en memoria                   ;Fin del espacio reservado para el Vector de Interrupciones

 
	looP:
	ldi r16,0xff
	out ddrb,r16
	
	ldi r21,15; inicio en la posicion media
	sts tiempo,r21

	RCALL init_USART0
	SEI 


	loop1:
	ldi r20,0xff
	out portb, r20
	lds r25,tiempo; activo tiempo
	push r25; guardo el tiempo que tengo en la interrupcion
	call delay1ms; muestro delay->dependiendo de r25
	pop r25; saco r25
	ldi r17,0x00
	out portb, r17; apago la señal, igual si no hay señal no hace nada.
	push r25
	call delay18ms
	pop r25
	rjmp loop1



	//---------------------DELAYS-----------------------
	delay1ms:

	push YL
		push YH
		IN YL, SPL
		IN YH, SPH
	
		push r16; guardamos en memoria
		ldd r16,Y+5; lo llevamos a una posicion en pila 
	
	
	PUSH R18
	PUSH R19
	continuar:
    ldi  r18, 2
    ldi  r19, 9
L1: dec  r19
    brne L1
    dec  r18
    brne L1
	dec r16
	brne continuar
	POP R19
	POP R18
	pop r16
	pop YH
	pop YL
	ret

	delay18ms:


	push r18
	push r19

		 ldi  r18, 198
		ldi  r19, 102
	L2: dec  r19
		brne L2
		dec  r18
		brne L2
		nop




	pop r19
	pop r18


	ret

	//-----------ANALISIS DE RECIBIR VALOR-------	

	init_USART0:                                   
			;cargar en UBRR el valor para obtener la velocidad de transmisión deseada
			PUSH r16
			LDI R16, LOW(UBRRvalue)     ; Low byte of Vaud Rate ; lo que resulto de la operacion del r16 y abarca 16 bits
			STS UBRR0L, R16             ; UBRR0L - USART Baud Rate Register Low Byte ; guarda en memoria ram
			LDI R16, HIGH(UBRRvalue)    ; High byte of Vaud Rate
			STS UBRR0H, R16             ; UBRR0H - USART Baud Rate Register High Byte
			;habilitar recibir y transmitir, habilitar interrupcion USART0 "Rx terminado" (No las: UDR vacío, Tx terminado)
			ldi r16, (1<<RXCIE0)        ; RX Complete Interrupt Enable
			ori r16, (1<<RXEN0)         ; Receiver Enable ; ori suma
			ori r16, (0<<TXEN0)        ; Transmitter Enable
			STS UCSR0B, R16             ; UCSR0B - USART Control and Status Register B ; recibe la info y activa el puerto serial
			; configure USART 0 como asíncrono, establezca el formato de trama ->
			; -> 8 bits de datos, 1 bit de parada, sin paridad
			ldi r16, (1<<UCSZ01)        ; Character Size = 8 bits ; si le dices 3 es el character sixe
			 ori r16, (1<<UCSZ00)  
				ori r16, (0<<UPM01)         ; Receiver Enable ; ori suma
			ori r16, (0<<UPM00)        ; Transmitter Enable
			ORI r16, (0<<USBS0)
			STS UCSR0C, R16             ; UCSR0C - USART Control and Status Register C
			POP r16
	
			RET
			/****************************
		Funcion de atencion de la interrupcion de Dato recibido por USART
		Se dispara cuando un nuevo byte está listo en el registro UDR0
	****************************/
	USART0_reception_completed :

			PUSH R16   ; funcion para recibir info
			IN R16, SREG       ;registro de control ; Copia de seguridad SREG. OBLIGATORIO en las rutinas de manejo de interrupciones
			PUSH R16    
			push r26
			lds r26,tiempo   
			; ** Aqui empieza el cuerpo de la funcion de atencion de la interrupcion
			LDS R16, UDR0     
			push r16          ; recoger el byte recibido para procesarlo
 
		
	;COMPARO SI ES 'A'
	cpi r16,'a'
	breq a
	;COMPARO SI ES 'C'
	cpi r16,'c'
	breq c
	;CONTINUACION DEL ELSE
	rjmp seguir
	;ETIQUETA 1
	c:
	cpi r26,25;si ya es 2.5ms no hacer mas nada
	breq seguir
		
	inc r26; si es 1.5 por ejemplo, decremento 1 cifra

	sts tiempo,r26; guardo la cifra en memoria
	rjmp seguir; continuamos con la interrupcion
	;ETIQUETA 2
	a:
	cpi r26,5;0.5ms si ya es 5ms no hacer nadas
	breq seguir
	dec r26
	sts tiempo,r26
	;cpi r26,5; comparo con 5ms
	rjmp seguir
	;NO HACER NADA O FINALIZAR LA LLAMADA A LA INTERRUPCION
		seguir:
	
	pop r26
	pop r16
	 sts UDR0,r16
			POP R16
			OUT SREG, R16               ; Recuperar SREG de la copia de seguridad anterior
			POP R16
			RETI                        ; RETI es OBLIGATORIO al regresar de una rutina de manejo de interrupciones

	
	;FINALIZADO




	