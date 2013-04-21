################# Data segment ##################### 
.data 
msg1: .asciiz "Enter an 8-bit feedback polynomial: " 
msg2: .asciiz "\nEnter an 8-bit seed:" 
msg3: .asciiz "\nEnter a message to encrypt/decrypt: " 
msg4: .asciiz "\nEncrypted/Decrypted message is: " 
msg5: .asciiz "\n Register Examined : "
brk: .asciiz "\n"
buffer: .space 101 # Assuming maximum message length is 100 characters 
bnum: .space 9 
Errmsg: .asciiz "One of the entered digits is not a binary digit, renter the number again\n" 
Errmsg2: .asciiz "Entered number is zero, renter the number again\n" 
################# Code segment ##################### 
.text 
.globl main 
main: # main program entry 

# Getting an 8-bit feedback polynomial (so this would be secure for 16 bits of messages, might want to make this a bit bigger)
 li $v0, 4 						# service 4 is print string
 la $a0, msg1 					# prepare msg1 to be printed
 syscall 						# print msg1 ("Enter an 8-bit feedback polynomial: ")
 jal ReadB 						# jump to ReadB, store current address for returning
 move $s0, $v0 					# $s0 = feedback polynomial

# Getting an 8-bit seed 
 li $v0, 4 						# service 4 is print string
 la $a0, msg2 					# prepare msg2 to be printed
 syscall 						# print msg2 ("\nEnter an 8-bit seed:" )
 jal ReadB 						# jump to ReadB, store current address for returning
 move $s1, $v0 					# $s1 = seed

 # Reading the message to be encrypted/decrypted 
 li $v0, 4 						# service 4 is print string			
 la $a0, msg3 					# prepare msg3 to be printed
 syscall 						# print msg3 ("\nEnter a message to encrypt/decrypt: " )
 li $v0, 8 						# service 8 is read string
 la $a0, buffer 				# $a0 = address of 101 bit buffer
 li $a1, 101 					# load 101 into $a1 (prepares for a string of length x <= |length - 1|)
 syscall 						# read in string

# Encrypting/Decrypting message 
 li $v0, 4						# service 4 is print string
 la $a0, msg4 					# prepare msg4 to be printed
 syscall 						# print msg3 ("\nEncrypted/Decrypted message is: " )
 li $s4, 10 					# set $s4 = 10
 li $s5, 100 					# loop counter 
 la $s2, buffer 				# set $s2 = address of 101 bit buffer


NextChar: 
 lb $s3, ($s2) 					# Load $s3 into buffer
 beq $s3, $s4, DoneE 			# if $s3 == 10 go to line 66
 # Generating next random number 
 move $a0, $s0 					# set $a0 = feedback polynomial
 move $a1, $s1 					# set $a1 = seed
 jal RAND8 						# jump to line 118, saving current address for return
 move $s1, $v0 					# storing returned number as next seed 

 # Combining the random number generated with the character in the string
 move $t2, $v0 					# $t2 = last generated seed 
 srl $t2, $t2, 4 				# shift seed 4 bits to the left
 andi $v0, $v0, 15 				# overwrite last 4 bits of seed with 1111
 xor $v0, $v0, $t2 				# bitwise xor of seed with shifted seed
 xor $s3, $s3, $v0 				# bitwise xor of loaded character with xored shifted seed
 sb $s3, ($s2) 					# store loaded (now encrypted) character into into buffer

 addi $s2, $s2, 1 				# increment $s2 by 1 (go to next character)
 addi $s5, $s5, -1 				# decrement $s5 by 1 (reduce loop counter)
 bnez $s5, NextChar 			# if $s5 != 0, read next character

DoneE: 
 li $v0, 4 						# service 4 is print string
 la $a0, buffer 				# prepare to print encrypted/ decrypted message
 syscall 						# print
 li $v0, 10 					# service 10 is exit
 syscall						# exit

# Procedure for reading an 8-bit binary number 
# The read number will be returned in $v0. 
ReadB: 
# Reading the number as a string 
Again: 
 xor $v1, $v1, $v1 			# to hold binary number 
 li $v0, 8 					
 la $a0, bnum 
 move $a2, $a0 
 li $a1, 9 
 syscall 
 li $t0, 8 #loop counter 
 li $t2, 10 
 li $t3, '0' 
 li $t4, '1' 
Next: 
 lb $t1, ($a2) 
 beq $t1, $t2, Done 
 sll $v1, $v1, 1  
 beq $t1, $t3, Bdigit 
 bne $t1, $t4, Error
Bdigit: 
 andi $t1, $t1, 1 
 or $v1, $v1, $t1 
 addi $a2, $a2, 1 
 addi $t0, $t0, -1 
 bnez $t0, Next 
 bnez $v1, Done 
 la $a0, Errmsg2 
 li $v0, 4 
 syscall 
 j Again 
Error: 
 la $a0, Errmsg 
 li $v0, 4 
 syscall 
 j Again 
Done: 
 move $v0, $v1 
 jr $ra

# Procedure for implementing an 8-bit LFSR-based pseudo random 
# number generater. The procedure is given the Feedback polynomial, 
# and the seed as parameters in $a0 and $a1 registers and it generates 
# the next random number in $v0. 
RAND8: 
 move $v0, $a1 
 and $a1, $a1, $a0 #Mask the bits that should not be Xored 
# Count number of 1's in $a0 
 li $t0, 8 # Loop counter 
 xor $t1, $t1, $t1 # Number of ones 
Loop: 
 move $t2, $a1 
 andi $t2, $t2, 1 
 add $t1, $t1, $t2 
 srl $a1, $a1, 1 
 addi $t0, $t0, -1 
 bnez $t0, Loop 
 srl $v0, $v0, 1 
 andi $t1, $t1, 1 # Check if number of ones is even or odd 
 beqz $t1, Skip 
 ori $v0, 0x0080 
 add $a2, $v0, $0

Skip: 
 jr $ra 