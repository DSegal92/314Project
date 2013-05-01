FILE: README.txt

To operate this program, enter an 8-bit feedback polynomial, 8-bit seed, and file to encrypt/decrypt. When specifying the filename, make sure to indicate the absolute path to the file. See the example below:

Enter a file to encrypt/decrypt: C:\Users\Bob\Desktop\test.txt

For encrypting files, the filename must not contain any %s. %s indicate that the file is already encrypted. As an output, the program create a file in the same directory as the input file with a % at the end of the filename. For the example above, the encrypted file would be as follows:

test%.txt located in the directory C:\Users\Bob\Desktop\

For decrypting a file, the filename should only contain the % at the end of the filename. The program will then output a file with the original filename (without any %s). This file will contain the decrypted message.
