################# Data segment #####################
.data
msg1: .asciiz "Enter an 8-bit feedback polynomial: "
msg2: .asciiz "\nEnter an 8-bit seed: "
msg3: .asciiz "\nEnter a file to encrypt/decrypt: "
msg4: .asciiz "Opening files...\n"
msg5en: .asciiz "Generating encryption...\n"
msg5de: .asciiz "Generating decryption...\n"
msg6: .asciiz "Closing files...\n"
msg7: .asciiz "Process Complete!\n"

Errmsg: .asciiz "One of the entered digits is not a binary digit, renter the number again\n"
Errmsg2: .asciiz "Entered number is zero, re-enter the number again\n"
Errmsg3: .asciiz "File not found! Re-entering the filename: "
Errmsg4: .asciiz "Failed to create an output file! Re-enter the filename: "

newLine: .ascii "\n"
percent: .ascii "%"
period: .ascii "."

file_in: .space 101 # space for the input file name
file_out: .space 101 # space for the output file name

buffer: .space 2 # space for the next bit of input
bnum: .space 9
################# Code segment #####################
.text
.globl main
main:

# Getting an 8-bit feedback polynomial
 li $v0, 4
 la $a0, msg1
 syscall					# print msg1 ("Enter an 8-bit feedback polynomial: ")
 jal ReadB					# jump to ReadB
 move $s0, $v0					# $s0 = feedback polynomial

# Getting an 8-bit seed
 li $v0, 4
 la $a0, msg2
 syscall					# print msg2 ("\nEnter an 8-bit seed:" )
 jal ReadB
 move $s1, $v0					# $s1 = seed

# Opening the file to encrypt/decrypt
 jal OpenFiles 					# open the files

# Encrypting/Decrypting message
 li $v0, 4
 beqz $s5, EncryptMsg
 la $a0, msg5de					# msg5 ("Generating decryption...\n")
 j MessageEnd
EncryptMsg:
 la $a0, msg5en					# msg5 ("Generating encryption...\n")
MessageEnd:
 syscall					# print msg5
 la $s2, buffer					# $s2 = address of input buffer
 
NextChar:
 # Read the next input character from the input file
 li $v0, 14					# read from the input file
 move $a0, $s6					# move the file descriptor to $a0
 la $a1, buffer					# load the address of the input buffer
 li $a2, 1					# always read 1 character
 syscall
 
 beqz $v0, DoneE 				# break if no more bytes are read
 lb $s3, ($s2) 					# Load buffer into $s3
 
 # Generating next random number
 move $a0, $s0					# set $a0 = feedback polynomial
 move $a1, $s1					# set $a1 = seed
 jal RAND8					# jump to pseudo-random number generator
 move $s1, $v0					# storing returned number as next seed

 # Generating next random number for second polynomial
 li $a2, 142                                    # pre-set polynomial to 10001110
 li $a3, 173                                    # pre-set seed to 10101101
 jal RAND2
 move $s4, $v0                                  # storing returned number as next seed

# Combining the random number generated with the character in the string
 move $t2, $s1 					# $t2 = last generated seed for first polynomial
 srl $t2, $t2, 4 				# shift seed 4 bits to the left
 andi $s1, $s1, 15 				# overwrite last 4 bits of seed with 1111
 xor $s1, $s1, $t2 				# bitwise xor of seed with shifted seed

 move $t5, $s4                                  # $t5 = last generated seed for second polynomial
 srl $t5, $t5, 4                                # shift seed 4 bits to the left
 andi $s4, $s4, 15                              # overwrite last 4 bits of seed with 1111
 xor $s4, $s4, $t5                              # bitwise xor of seed with shifted seed

 xor $t6, $s1, $s4                              # bitwise xor of two polynomials seeds (each previously xored)

 xor $s3, $s3, $t6 				# bitwise xor of loaded character with xored shifted seed
 sb $s3, ($s2) 					# store loaded (now encrypted) character into into buffer

 # Write the encrypted/decrypted character to the output file
 li $v0, 15					# write to a file
 move $a0, $s7					# move the file descriptor to $a0
 la $a1, buffer					# load the address of the character to written
 li $a2, 1					# always write 1 character
 syscall

 j NextChar

DoneE:

 jal CloseFiles					# close the files
 
 li $v0, 4
 la $a0, msg7
 syscall					# print msg7 ("Process Complete!\n")
 
 li $v0, 10
 syscall					# exit the program

# Procedure for reading an 8-bit binary number
# The read number will be returned in $v0.
ReadB:
# Reading the number as a string
Again:
 xor $v1, $v1, $v1				# to hold binary number
 li $v0, 8
 la $a0, bnum
 move $a2, $a0
 li $a1, 9
 syscall
 li $t0, 8 					# loop counter
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
 and $a1, $a1, $a0 				# mask the bits that should not be Xored
 # Count number of 1's in $a0
 li $t0, 8					# loop counter
 xor $t1, $t1, $t1 				# number of ones
Loop:
 move $t2, $a1
 andi $t2, $t2, 1
 add $t1, $t1, $t2
 srl $a1, $a1, 1
 addi $t0, $t0, -1
 bnez $t0, Loop
 srl $v0, $v0, 1
 andi $t1, $t1, 1 				# check if number of ones is even or odd
 beqz $t1, Skip
 ori $v0, 0x0080
 add $a2, $v0, $0
 j Skip

RAND2: 
 move $v0, $a3 
 and $a3, $a3, $a2				# mask the bits that should not be Xored 
 # Count number of 1's in $a2 
 li $t0, 8					# loop counter 
 xor $t1, $t1, $t1				# number of ones 
Loop2: 
 move $t2, $a3 
 andi $t2, $t2, 1 
 add $t1, $t1, $t2 
 srl $a3, $a3, 1 
 addi $t0, $t0, -1 
 bnez $t0, Loop2 
 srl $v0, $v0, 1 
 andi $t1, $t1, 1 				# check if number of ones is even or odd 
 beqz $t1, Skip 
 ori $v0, 0x0080 
 add $a2, $v0, $0

Skip:
 jr $ra 

OpenFiles:
 li $v0, 4
 la $a0, msg3
 syscall					# print msg3 ("\nEnter a message to encrypt/decrypt: " )
InputFilename:
 li $v0, 8
 la $a0, file_in
 li $a1, 101
 syscall 					# read in the input filename
 
 li $s5, 0					# reset decryption flag
 
 # Strip the newLine at the end of input filename
 # and generate output filename
 la $t0, file_in
 la $t2, newLine
 lb $t3, ($t2)					# $t3 = "\n"
 la $t2, percent
 lb $t4, ($t2)					# $t4 = "%"
 la $t2, period
 lb $t5, ($t2)					# $t5 = "."
 la $t2, file_out
FileNameLoop:	
 lbu $t1, ($t0)
 beq $t1, $t3, RemoveNewline
 beq $t1, $t4, Decode
 beq $t1, $t5, Encode
 beqz $t1 FileNameEnd
 sb $t1, ($t2)
 addi $t0, $t0, 1
 addi $t2, $t2, 1
 j FileNameLoop
Decode:
 sb $t5, ($t2)
 addi $t0, $t0, 2
 addi $t2, $t2, 1
 addi $s5, $s5, 1				# set decryption flag
 j FileNameLoop
Encode:
 sb $t4, ($t2)
 sb $t5, 1($t2)
 addi $t0, $t0, 1
 addi $t2, $t2, 2
 j FileNameLoop
RemoveNewline:
 sb $zero, ($t0)	
FileNameEnd:
 sb $zero, ($t2)

 # Open 2 files: input and output
 li $t0, -1 
 
 li $v0, 4
 la $a0, msg4
 syscall					# print msg4 ("Opening files...\n")
 
 li $v0, 13
 la $a0, file_in
 li $a1, 0x0020					# read-only sequential file
 li $a2, 0x0000					# pmode doesn't matter 
 syscall		
 move $s6, $v0					# $s6 = file descriptor for input
 beq $s6, $t0, ReadFileFailure			# error check
 
 li $v0, 13
 la $a0, file_out
 li $a1, 0x0121					# write-only sequential file
 li $a2, 0x0180					# create a file with read and write permissions
 syscall
 move $s7, $v0					# $s7 = file descriptor for output
 beq $s7, $t0, WriteFileFailure			# error check
 
 jr $ra

CloseFiles:
 li $v0, 4
 la $a0, msg6
 syscall					# print msg6 ("Closing files...\n")

 li $v0, 16					# close a file
 move $a0, $s6					# file descriptor of input file
 syscall
 
 li $v0, 16
 move $a0, $s7					# file descriptor of output file
 syscall
 
 jr $ra

ReadFileFailure:
 li $v0, 4
 la $a0, Errmsg3
 syscall					# print file error message
 j InputFilename

WriteFileFailure:
 li $v0, 4
 la $a0, Errmsg4				# print file error message
 syscall
 li $v0, 16					# close read file
 move $a0, $s6					# file descriptor of input file
 syscall
 j InputFilename