#Author: Leon Becler
#E-Mail: lab160730@utdallas.edu
#Class: CS3340
#Professor: Dr. Karen Mazidi
.data
crc_table: 		.space 		1024		#Table of CRCs of all 8-bit messages (256) (but each element size = 32 bits) (so 256*4)
checksum:		.space		4
pointer:		.word		0
aug_length:		.word		0
newline:		.asciiz		"\n"
			.align 2
buffer: 		.asciiz 	"the quick brown fox jumps over the lazy dog"
			.align 2
uncorrupted:		.asciiz		"Data is okay"
			.align 2
corrupted:		.asciiz		"Data is corrupted"
			.align 2
checksum_message: 	.asciiz		"Checksum for message: "
			.align 2
actual_message:		.asciiz		"Message: "
			.align 2	
augmented_message:	.asciiz		"Message with checksum tacked on the end: "
			.align 2
.text
main:
la $s0, crc_table		#Load address of crc_table into $s0
jal gen_crc_table		#Generate the crc_table

add $t0, $zero, $zero		#unsigned int i = 0 counter for while loop
	while_main:
	sll $t1, $t0, 2			#Align the counter to word boundary
	addu $t1, $t1, $s0		#Move to each word in the crc_table
	lw $a0, ($t1)			#crc_table[i]; Load the element at $t0 in the crc table; 
	li $v0, 34			#Set system function to print word as a hexadecimal value
	syscall				#Print hex value at crc_table[i]

	li $v0, 4			#
	la $a0, newline			#
	syscall				#newline

	addiu $t0, $t0, 1		#
	bltu $t0, 256, while_main	#while i < 256 continue to loop
	
li $v0, 4				#
la $a0, newline				#
syscall					#newline

la $a0, buffer				#
jal count_bytes				#
addu $s1, $v0, 8			#
sw $s1, aug_length			#Count and save the length of the augmented message (buffer length + 8)

li $v0, 9				#
addu $a0, $s1, $zero			#
syscall					#
sw $v0, pointer				#Allocate memory in the heap and save address in pointer

la $a0, buffer				#
li $a1, 0x00000000			#
lw $a2, aug_length			#
lw $a3, pointer				#
jal augment_message			#Create initial augmented message which equals the message bufffer bytes with 8 0 bytes at the end

lw $a0, pointer				#
lw $a1, aug_length			#
jal crc					#Get the checksum value of the augmented message

sw $v0, checksum			#Store return value in checksum address

li $v0, 4				#
la $a0, actual_message			#
syscall					#Print Message:

li $v0, 4				#
lw $a0, pointer				#
syscall					#Print the message in the pointer

li $v0, 4				#
la $a0, newline				#
syscall					#newline

li $v0, 4				#
la $a0, checksum_message		#
syscall					#Print Checksum of the message:

li $v0, 34				#
lw $a0, checksum			#
syscall					#Print checksum as a hexadecimal value

li $v0, 4				#
la $a0, newline				#
syscall					#newline

li $v0, 4				#
la $a0, actual_message			#
syscall					#Print Message:

li $v0, 4				#BREAK HERE
lw $a0, pointer				#
syscall					#print message in the pointer

li $v0, 4				#
la $a0, newline				#
syscall					#newline

li $v0, 4				#
la $a0, checksum_message		#
syscall					#print checksum message

lw $a0, pointer 			#
lw $a1, aug_length			#
jal crc					#Calculate crc of the message in pointer
addu $s2, $v0, $zero		

addu $a0, $v0, $zero			#
li $v0, 34				#
syscall					#Print new checksum

li $v0, 4				#
la $a0, newline				#
syscall					#newline

li $v0, 4				#
la $a0, newline				#
syscall					#newline

lw $t0, checksum			#
addu $t1, $s2, $zero			#
xor $t0, $t0, $t1			#Compare old checksum value and new checksum value

bne $t0, $zero, else			#If $t0 is equal to 0 then the data is uncorrupted
li $v0, 4
la $a0, uncorrupted
syscall					#Print uncorrupted
j next

else:
li $v0, 4
la $a0, corrupted
syscall					#Print corrupted
j next

next:

li $v0, 4				#
la $a0, newline				#
syscall					#newline

la $a0, buffer
lw $a1, checksum
lw $a2, aug_length
lw $a3, pointer
jal augment_message 

li $v0, 4				#
la $a0, augmented_message		#
syscall					#Print Message with checksum tacked on the end: 

li $v0, 4				#
lw $a0, pointer				#
syscall					#Print augmented_message

exit:
li $v0, 4
la $a0, newline
syscall

li $v0, 10
syscall

#gen_crc_table() 
#$t0 = checksum
#$t1 = i
#$t2 = j
gen_crc_table:
addu $t1, $zero, $zero			#unsigned int i = 0
	while_gen_1:			#do
	addu $t0, $t1, $zero		#unsigned int checksum = i
	addu $t2, $zero, $zero		#unsigned int j = 0
		while_gen_2:			#do
		and $t3, $t0, 1			#unsigned int temp = checksum & 1
		srl $t0, $t0, 1			#checksum = checksum >> 1
		beqz $t3, wg2_else		#if(temp == 1)
		add $t3, $zero, 0xEDB88320	#temp = 0xEDB88320
		xor $t0, $t0, $t3		#checksum = temp ^ checksum
		wg2_else:	
		addiu $t2, $t2, 1		#j++
		bltu $t2, 8, while_gen_2	#while( j < 8 )			
	sll $t3, $t1, 2			#allign with word boundary
	addu $t3, $t3, $s0 		# $s0 = address of crc_table
	sw $t0, ($t3)			#crc_table[n] = checksum
	addiu $t1, $t1, 1		#i++
	bltu $t1, 256, while_gen_1	#while( i < 256 )
jr $ra				#return to function call address + 1
###


#gen_crc(uint32 crc, uint8 *buf, uint32 length)
#$a0 = crc, $a1 = buf, $a2 = length
#return value $v0 = checksum
gen_crc:
addu $t1, $a0, $zero		#uint32 c = crc
addu $t0, $zero, $zero		#unsigned int i = 0
	while_crc:			#do
	addu $t4, $a1, $t0		#
	lbu $t2, ($t4) 			#buf[i]
	xor $t2, $t2, $t1		#buf[i] ^ c
	and $t2, 0xFF			#(buf[i] ^ c) & 0xFF
	sll $t2, $t2, 2			#align to word boundary
	
	addu $t4, $s0, $t2		#
	lw $t2, ($t4)			#crc_table[(buf[i] ^ c) & 0xFF]
	srl $t3, $t1, 8			#c>>8
	xor $t1, $t2, $t3		#c = crc_table[buf[i] ^ c) & 0xFF] ^ (c>>8)
	
	addiu $t0, $t0, 1		#i++
	bltu $t0, $a2, while_crc	#while(i < length)
addu $v0, $t1, $zero			#
jr $ra					#return c
###

#crc(uint8 *buf, uint32 length)
#$a0 = buf, $a1 = length
crc:
addi $sp, $sp, -4		#Make space on the stack
sw $ra, ($sp)			#Save return address

addu $a2, $a1, $zero
addu $a1, $a0, $zero
li $a0, 0xFFFFFFFF
jal gen_crc			#gen_crc(0xFFFFFFFF,buf,len)

li $t0, 0xFFFFFFFF 		#
xor $v0, $v0, $t0		#gen_crc(0xFFFFFFFF,buf,len) ^ 0xFFFFFFFF

lw $ra, ($sp)			#Load return address
addi $sp, $sp, 4		#Remove space from the stack
jr $ra				#return gen_crc(0xFFFFFFFF, buf, len) ^ 0xFFFFFFFF
###

#Counts the bytes in the buffer
#count_bytes(uint8 *buf)
#$a0 = buf
#return $v0 = number of bytes
count_bytes:
li $t0, 0			#counter for while loop
addu $t2, $a0, $zero		#load buffer address into $t2
	while_cb:
	lbu $t1, ($t2)			#load byte
	beq $t1, $zero, while_cb_exit	#if byte is null terminating character exit loop
	addiu $t0, $t0, 1		#counter++
	addiu $t2, $t2, 1		#point to next byte
	j while_cb
while_cb_exit:
addu $v0, $t0, $zero		#
jr $ra				#return counter
###

#Adds a crc32 checksum to the end of a message buffer
#packaged_message(uint8* buffer, uint32 checksum, uint32 length, uint8* pointer)
#$a0 = buffer, $a1 = checksum, $a2 = length, $a3 = pointer
augment_message:
li $t0, 0			#unsigned int i = 0; counter for loops
addiu $t1, $a2, -8		#Add only the message first to the dynamic memory address
	while_pm_1:	
	addu $t2, $a0, $t0		#Point $t2 to the proper memory location from the memory buffer address
	lb $t3, ($t2)			#Load the byte at $t2
	
	addu $t2, $a3, $t0		#Point $t2 to the proper memory location from the dynamic memory pointer address
	sb $t3, ($t2) 			#Store byte from message buffer into dynamic memory
	
	addiu $t0, $t0, 1		#i++; add 1 to the loop count
	bltu $t1, $t0, pm_1_exit	#Loop while i is less than the length of the buffer
	j while_pm_1
pm_1_exit:
li $t2, 0xF			#Use $t2 to filter bytes from the checksum
	while_pm_2:
	subu $t4, $a2, $t0		#Subtract the aug_length by the current count
	sll $t4, $t4, 2			#Multiply difference by 4 to properly set shift amount to isolate each byte
	srlv $t3, $a1, $t4		#Place target byte in the 0th byte position
	and $t3, $t2, $t3		#Cull any byte not in the 0th position
	
	addiu $t0, $t0, -1		
	addu $t4, $a3, $t0		#Point to the proper address from the dynamic memory pointer address
	sb $t3, ($t4)			#Store the byte at the address
	addiu $t0, $t0, 1
	
	addiu $t0, $t0, 1		#i++; add 1 to the loop count
	bltu $a2, $t0, pm_2_exit	#Loop while i is less than the length of the augmented message
	j while_pm_2
pm_2_exit:
jr $ra
