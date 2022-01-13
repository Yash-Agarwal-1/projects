#Author: Yash Agarwal
#CS 252
#Filename:asm5.s
#Purpose: Performs a substitution cipher and decipher based on the inital argument and prints out the result. It takes input from the keyboard and uses     the keyboard and display MMIO simulator in MARS.
#This function decides what mode the program is being processed in and passes the control
#to the respective function.
#scanf("%s", str);
#if(strcmp(str, "cipher" == 0)
#	cipher();
#else if)strcmp(str, "decipher")
#	decipher();
#printf("Not a valid input. Terminating program!");
.globl main
main:
	addiu $sp, $sp, -24
	sw $fp, 0($sp)
	sw $ra, 4($sp)
	addiu $fp, $sp, 20
	
	lui     $t0, 0xffff
	
	addi    $t8, $zero,1
	sll     $t8, $zero,20    # LOOP_COUNT = 2^20
	
	addi  	$s0, $zero, 0	#i = 0
	
	# print_str(NOT_READY_MSG)
	addi    $v0, $zero,4
	la      $a0, NOT_READY_MSG1
	syscall


OUTER_LOOP1:
	lw      $t1, 0($t0)      # read control register
	andi    $t1, $t1,0x1     # mask off all but bit 0 (the 'ready' bit)

.data
NOT_READY_MSG1: .asciiz "Please specify if you wish to proceed with cipher or decipher mode: \n"
INPUT:		.space	10
C_CHECK:	.asciiz	"cipher"
D_CHECK:	.asciiz	"decipher"
IN_ERR:		.asciiz	"Not a valid input. Terminating program!\n"
.text
	bne     $t1,$zero, READY1

NOT_READY_LOOP1:
	lw      $t1, 0($t0)      # read control register
	andi    $t1, $t1,0x1     # mask off all but bit 0 (the 'ready' bit)
	beq     $t1,$zero, NOT_READY_LOOP1

READY1:
	# read the actual typed character
	lw      $t1, 4($t0)
	#if the read character == '\n' goto AFTER_DELAY1
	beq  	$t1, '\n', AFTER_DELAY1
	#str[i]= c
	sb  	$t1, INPUT($s0)
	
	addi	$s0, $s0, 1	#i++

DELAY_LOOP1:
	addi    $t2, $zero,0      # i=0
	slt     $t3, $t2,$t8      # i < LOOP_COUNT
	beq     $t3,$zero, DELAY_DONE1

	addi    $t2, $t2,1        # i++
	j       DELAY_LOOP1
	
DELAY_DONE1:
	j       OUTER_LOOP1
	
AFTER_DELAY1:

	la 	$a0, INPUT	#if(str == "cipher") goto cipher()
	la 	$a1, C_CHECK
	jal strcmp
	
	beq  	$v0, $zero, cipher
	
	la 	$a0, INPUT	#if(str == "decipher") goto decipher()
	la 	$a1, D_CHECK
	jal strcmp
	
	beq 	$v0, $zero, decipher
	
	addi	$v0, $zero, 4
	la 	$a0, IN_ERR
	syscall
	
	addi	$v0, $zero, 10	#exit
	syscall
	
	lw $ra, 4($sp)
	lw $fp, 0($sp)
	addiu $sp, $sp, 24
	jr $ra

#this function performs the encryption based on a substitution pattern which is specified in
#the ALPHABET and SUBSTITUTION_STR strings. ANy character which are not alphabets or numbers are
#added as they are. Whitespaces are ignored.
#scanf("%c", ch);
#for(int i = 0; i < ALPHABET.length; i++)
#if(ch == ' ') goto SPACE_FOUND
#if(ch == '\n') goto NEWLINE_FOUND
#if(ALPHABET[i] == ch){
#printf("%c -> %c", ch, SUBSTITUTION_STR[i]);
#output_str+=SUBSTITUTION_STR[i]);}
#}


.globl cipher
cipher:
	addiu $sp, $sp, -24
	sw $fp, 0($sp)
	sw $ra, 4($sp)
	addiu $fp, $sp, 20

	lui     $t0, 0xffff
	
	addi    $t8, $zero,1
	sll     $t8, $zero,20    # LOOP_COUNT = 2^20
	
	addi    $v0, $zero,4	#print_str(KEY_MSG0)
	la      $a0, KEY_MSG0
	syscall
	
	addi    $v0, $zero,11	#print_chr('\n')
	la      $a0, '\n'
	syscall
	
	addi    $v0, $zero,4		#print_str(SUBSTITUTION_STR)
	la      $a0, SUBSTITUTION_STR
	syscall
	
	addi    $v0, $zero,11		#print_chr('\n')
	la      $a0, '\n'
	syscall
	
	addi    $v0, $zero,4		#print_str(KEY_MSG1)
	la      $a0, KEY_MSG1
	syscall
	
	addi    $v0, $zero,4		#print_str(KEY_MSG2)
	la      $a0, KEY_MSG2
	syscall
	
	addi    $v0, $zero,4		#print_str(ALPHABET)
	la      $a0, ALPHABET
	syscall
	
	addi    $v0, $zero,11		#print_chr('\n')
	la      $a0, '\n'
	syscall
	
	addi    $v0, $zero,11		#print_chr('\n')
	la      $a0, '\n'
	syscall
	
	# print_str(NOT_READY_MSG)
	addi    $v0, $zero,4
	la      $a0, NOT_READY_MSG
	syscall
	
	addi    $v0, $zero,4		# print_str(DOTS)
	la      $a0, DOTS
	syscall
	
	addi	$s0, $zero, 0		#count = 0
	

OUTER_LOOP:
	lw      $t1, 0($t0)      # read control register
	andi    $t1, $t1,0x1     # mask off all but bit 0 (the 'ready' bit)

.data
KEY_MSG0:		.asciiz	"THE KEYS BEING USED:\n"
KEY_MSG1:		.asciiz	"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n"
KEY_MSG2:		.asciiz	"||||||||||||||||||||||||||||||||||||||||||||||||||||\n"
NOT_READY_MSG: 		.asciiz "Please enter the text to be ciphered...\n"
DOTS: 			.asciiz	"*--------------------------------------*\n"
ALPHABET:		.asciiz "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
SUBSTITUTION_STR:	.asciiz	"qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM6751423809"	
STR:			.space	512	
STR2:			.space	512
SPACE:			.asciiz	"Whitespace was entered and removed from the final string\n"
CIPHER:			.asciiz	"Ciphertext: "
.text
	bne     $t1,$zero, READY

NOT_READY_LOOP:
	lw      $t1, 0($t0)      # read control register
	andi    $t1, $t1,0x1     # mask off all but bit 0 (the 'ready' bit)
	beq     $t1,$zero, NOT_READY_LOOP

READY:
	# read the actual typed character
	lw      $t1, 4($t0)
	
	beq  	$t1, '\n', NEWLINE_FOUND	#if(ch == '\n') goto NEWLINE_FOUND
	
	beq  	$t1, ' ', SPACE_FOUND		#if(ch == ' ') goto SPACE_FOUND
	
	addi  $t7, $zero, 0			#i = 0
		
	la    $t2, ALPHABET			#t2= &ALPHABET

SEARCH_LOOP:

	slti  $t6, $t7, 62			#if(i > 62) goto SUB_NOT_FOUND
	beq   $t6, $zero, SUB_NOT_FOUND
	
	add  $t3, $t2, $t7			#t3= ALPHABET[i]
	lb   $t3, 0($t3)
	beq  $t1, $t3, SUB_FOUND
	
	addi  $t7, $t7, 1			#i++
	
	j SEARCH_LOOP
	
SUB_FOUND:
	
	la  $t2, SUBSTITUTION_STR		#t2 = &SUBSTITUTION_STR
	add $t4, $t2, $t7			
	lb  $t4, 0($t4)				#t4 = SUBSTITUTION_STR[i]
	
	sb  $t4, STR($s0)			#STR[i] = t4
	
	addi  $s0, $s0, 1			#i++
	
	#print_chr(t1)
	addi    $v0, $zero, 11
	add     $a0, $t1, $zero
	syscall
	
	#print_chr(' ')
	addi	$v0, $zero, 11
	addi	$a0, $zero, ' '
	syscall
	
	#print_chr('-')
	addi	$v0, $zero, 11
	addi	$a0, $zero, '-'
	syscall
	
	addi	$v0, $zero, 11
	addi	$a0, $zero, '>'
	syscall
	
	#print_chr(' ')
	addi	$v0, $zero, 11
	addi	$a0, $zero, ' '
	syscall
	
	# print_chr(t1)
	addi    $v0, $zero,11
	add     $a0, $t4,$zero
	syscall
	
	#print_chr('\n')
	addi	$v0, $zero, 11
	addi	$a0, $zero, '\n'
	syscall
	
	j DELAY_LOOP
	
SUB_NOT_FOUND:

	sb  $t1, STR($s0)		#STR2[i] = t1
	
	addi  $s0, $s0, 1		#i++
		
	# print_chr(t1)
	addi    $v0, $zero,11
	add     $a0, $t1,$zero
	syscall
	
	#print_chr(' ')
	addi	$v0, $zero, 11
	addi	$a0, $zero, ' '
	syscall
	
	#print_chr('-')
	addi	$v0, $zero, 11
	addi	$a0, $zero, '-'
	syscall
	
	addi	$v0, $zero, 11
	addi	$a0, $zero, '>'
	syscall
	
	#print_chr(' ')
	addi	$v0, $zero, 11
	addi	$a0, $zero, ' '
	syscall
	
	# print_chr(t1)
	addi    $v0, $zero,11
	add     $a0, $t1,$zero
	syscall

	#print_chr('\n')
	addi	$v0, $zero, 11
	addi	$a0, $zero, '\n'
	syscall
	
DELAY_LOOP:
	addi    $t2, $zero,0      # i=0
	slt     $t3, $t2,$t8      # i < LOOP_COUNT
	beq     $t3,$zero, DELAY_DONE

	addi    $t2, $t2,1        # i++
	j       DELAY_LOOP
	
DELAY_DONE:
	j       OUTER_LOOP
	
	j AFTER_SPACE
	
NEWLINE_FOUND:

	addi  $v0, $zero, 4		#printf("%s", cipher)
	la    $a0, CIPHER
	syscall
	
	addi  $v0, $zero, 4		#printf(str)
	la    $a0, STR
	syscall
	
	addi	$v0, $zero, 11		#print_Chr('\n')
	addi	$a0, $zero, '\n'
	syscall
	
	j OUTER_LOOP

SPACE_FOUND:

	addi  $v0, $zero, 4		#print_str(SPACE)
	la    $a0, SPACE
	syscall
	
	j OUTER_LOOP
	
AFTER_SPACE:
	
	lw $ra, 4($sp)
	lw $fp, 0($sp)
	addiu $sp, $sp, 24
	jr $ra


# This function deciphers the encoded string by referncing the encoding strings the
# other way round. 
#scanf("%c", ch);
#for(int i = 0; i < ALPHABET.length; i++)
#if(ch == ' ') goto SPACE_FOUND
#if(ch == '\n') goto NEWLINE_FOUND
#if(SUBSTITUTION[i] == ch){
#printf("%c -> %c", ch, ALPHABET[i]);
#output_str+=ALPHABET[i]);}
#}
.globl decipher
decipher:
	addiu $sp, $sp, -24
	sw $fp, 0($sp)
	sw $ra, 4($sp)
	addiu $fp, $sp, 20

	lui     $t0, 0xffff
	
	addi    $t8, $zero,1
	sll     $t8, $zero,20    # LOOP_COUNT = 2^20
	
	# print_str(NOT_READY_MSG)
	addi    $v0, $zero,4
	la      $a0, NOT_READY_MSG2
	syscall
	
	addi 	$s0, $zero, 0	#i = 0

OUTER_LOOP2:
	lw      $t1, 0($t0)      # read control register
	andi    $t1, $t1,0x1     # mask off all but bit 0 (the 'ready' bit)

.data
NOT_READY_MSG2: .asciiz "Now in decipher mode!\n"

.text
	bne     $t1,$zero, READY2

NOT_READY_LOOP2:
	lw      $t1, 0($t0)      # read control register
	andi    $t1, $t1,0x1     # mask off all but bit 0 (the 'ready' bit)
	beq     $t1,$zero, NOT_READY_LOOP2

READY2:
	# read the actual typed character
	lw      $t1, 4($t0)

	beq 	$t1, ' ', SP_FOUND	#If(ch == ' ') goto SP_FOUND
	
	beq 	$t1, '\n', PRINT_DC	#if(ch == '\n') goto PRINT_DC
	
	addiu	$t7, $zero, 0	#count = 0
	
	la    $t2, SUBSTITUTION_STR	#t2 = &SUBSTITUTION_STR
	
SEARCH_LOOP2:

	slti  $t6, $t7, 62		#if(count < 62)
	beq   $t6, $zero, SUB_NOT_FOUND2
	add  $t3, $t2, $t7
	lb   $t3, 0($t3)		#c = SUBSTITUTION_STR[count])
	beq  $t1, $t3, SUB_FOUND2	
	
	addi  $t7, $t7, 1		#count++
	
	j SEARCH_LOOP2
	
SUB_FOUND2:
	
	la  $t2, ALPHABET		#t2 = &ALPHABET
	add $t4, $t2, $t7
	lb  $t4, 0($t4)			#t4 = ALPHABET[i]
	
	sb  $t4, STR2($s0)		#STR2[count] = t4
	
	addi  $s0, $s0, 1		#count++
	
	#print_chr(t1)
	addi    $v0, $zero, 11
	add     $a0, $t1, $zero
	syscall
	
	#print_chr(' ')
	addi	$v0, $zero, 11
	addi	$a0, $zero, ' '
	syscall
	
	#print_chr('-')
	addi	$v0, $zero, 11
	addi	$a0, $zero, '-'
	syscall
	
	addi	$v0, $zero, 11
	addi	$a0, $zero, '>'
	syscall
	
	#print_chr(' ')
	addi	$v0, $zero, 11
	addi	$a0, $zero, ' '
	syscall
	
	# print_chr(t1)
	addi    $v0, $zero,11
	add     $a0, $t4,$zero
	syscall
	
	#print_chr('\n')
	addi	$v0, $zero, 11
	addi	$a0, $zero, '\n'
	syscall
	
	j DELAY_LOOP2
	
SUB_NOT_FOUND2:

	sb  $t1, STR2($s0)		#STR2[i] = t1
	
	addi  $s0, $s0, 1		#i++
	
	# print_chr(t1)
	addi    $v0, $zero,11
	add     $a0, $t1,$zero
	syscall
	
	#print_chr(' ')
	addi	$v0, $zero, 11
	addi	$a0, $zero, ' '
	syscall
	
	#print_chr('-')
	addi	$v0, $zero, 11
	addi	$a0, $zero, '-'
	syscall
	
	addi	$v0, $zero, 11
	addi	$a0, $zero, '>'
	syscall
	
	#print_chr(' ')
	addi	$v0, $zero, 11
	addi	$a0, $zero, ' '
	syscall
	
	# print_chr(t1)
	addi    $v0, $zero,11
	add     $a0, $t1,$zero
	syscall

	#print_chr('\n')
	addi	$v0, $zero, 11
	addi	$a0, $zero, '\n'
	syscall
	
	
DELAY_LOOP2:
	addi    $t2, $zero,0      # i=0
	slt     $t3, $t2,$t8      # i < LOOP_COUNT
	beq     $t3,$zero, DELAY_DONE2

	addi    $t2, $t2,1        # i++
	j       DELAY_LOOP2
	
DELAY_DONE2:
	j       OUTER_LOOP2
	
	lw $ra, 4($sp)
	lw $fp, 0($sp)
	addiu $sp, $sp, 24
	jr $ra
.data
SP_NOT:		.asciiz	"Whitespace is not a valid ciphered character!\n"
DEC:		.asciiz	"Deciphered: "
.text
SP_FOUND:

	addi	$v0, $zero, 4		#print_str(SP_NOT)
	la	$a0, SP_NOT
	syscall
	
	j OUTER_LOOP2
	
PRINT_DC:
	
	addi	$v0, $zero, 4		#print_str(DEC)
	la	$a0, DEC
	syscall
	
	addi	$v0, $zero, 4		#print_str(STR2)
	la 	$a0, STR2
	syscall
	
	addi	$v0, $zero, 11		#print_ch('\n')
	addi	$a0, $zero, '\n'
	syscall
	
	j OUTER_LOOP2
		

#from asm4 tests
#Author: Tyler Conklin
.globl strcmp
strcmp:
	# standard prologue
	addiu   $sp, $sp, -24
	sw      $fp, 0($sp)
	sw      $ra, 4($sp)
	addiu   $fp, $sp, 20
	
	sw  	$t0, -4($sp)
	sw	$t1, -8($sp)
	addiu 	$sp, $sp, -8

	add     $t0, $a0,$zero          # p1 = a
	add     $t1, $a1,$zero          # p2 = b

strcmp_LOOP:
	lb      $t2, 0($t0)             # read *p1
	lb      $t3, 0($t1)             # read *p2
	beq     $t2,$zero, strcmp_DONE  # if (*p1 == '\0') break
	beq     $t3,$zero, strcmp_DONE  # if (*p2 == '\0') break
	bne     $t2,$t3,   strcmp_DONE  # if (*p1 != *p2 ) break

	addi    $t0, $t0,1              # p1++
	addi    $t1, $t1,1              # p2++
	j       strcmp_LOOP

strcmp_DONE:
	sub     $v0, $t2,$t3            # return *p1 - *p2


	lw  	$t0, 4($sp)
	lw	$t1, 0($sp)
	addiu 	$sp, $sp, 8
	
	# standard epilogue
	lw      $ra, 4($sp)
	lw      $fp, 0($sp)
	addiu   $sp, $sp, 24
	jr      $ra

	
