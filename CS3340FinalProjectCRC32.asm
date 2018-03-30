#Author: Leon Becker
#E-mail: lab160730@utdallas.edu
#Class: CS3340
#Professor: Dr. Karen Mazidi

.data
message: .word 0x48690000 #Hex for: Hi
poly: .word 0xEDB88320
.text
main:
la $a0, message
li $a1, 8
jal crc32_checksum
add $a0, $v0, $zero

li $v0,36
syscall

exit:
li $v0, 10
syscall

#crc32_checksum( a0=address of message, a1 = length of message in bytes )
#$t0 = value
#$t1 = checksum
#$t2 = iterator
crc32_checksum:
add $t1, $t1, 0xFFFFFFFF
	crc32_checksum_outer_loop:
	beq $a1, $zero, ccolexit
	addiu $a1, $a1, -1
	lbu $t4, ($a0)
	addiu $a0, $a0, 1
	xor $t0,$t1,$t4
	and $t0, 0xFF
	li $t2, 0
		crc32_checksum_inner_loop:
		beq $t2, 8, ccilexit
		addiu $t2, $t2, 1
		and $t3, $t0, 1
		srl $t0, $t0, 1
		beq $t3, $zero, ccil_else
		lw $t3, poly
		xor $t0, $t0, $t3
		ccil_else:
		j crc32_checksum_inner_loop
		ccilexit:
	srl $t1, $t1, 8
	xor $t1, $t1, $t0
	j crc32_checksum_outer_loop
	ccolexit:
addu $t3, $t3, 0xFFFFFFFF
xor $v0, $t1, $t3
jr $ra