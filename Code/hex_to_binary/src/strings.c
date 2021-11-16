#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>


int main(int argc, char *argv[])
{
    FILE *hex_file, *bin_file;
    hex_file = fopen("hex_values.txt", "r");
    bin_file = fopen("binary_data.txt", "w");
    char line[150];

    while(!feof(hex_file)){
        fgets(line,100,hex_file);

        int i=0;
        char *bit_seq = "0000";
        while(line[i])
        {
        	switch(line[i])
        	{
        	case '0': bit_seq = "0000"; break;
        	case '1': bit_seq = "0001"; break;
        	case '2': bit_seq = "0010"; break;
        	case '3': bit_seq = "0011"; break;
        	case '4': bit_seq = "0100"; break;
        	case '5': bit_seq = "0101"; break;
        	case '6': bit_seq = "0110"; break;
        	case '7': bit_seq = "0111"; break;
        	case '8': bit_seq = "1000"; break;
        	case '9': bit_seq = "1001"; break;
        	case 'A': bit_seq = "1010"; break;
        	case 'B': bit_seq = "1011"; break;
        	case 'C': bit_seq = "1100"; break;
        	case 'D': bit_seq = "1101"; break;
        	case 'E': bit_seq = "1110"; break;
        	case 'F': bit_seq = "1111"; break;
        	case 'a': bit_seq = "1010"; break;
        	case 'b': bit_seq = "1011"; break;
        	case 'c': bit_seq = "1100"; break;
        	case 'd': bit_seq = "1101"; break;
        	case 'e': bit_seq = "1110"; break;
        	case 'f': bit_seq = "1111"; break;
        	default:  printf("\nInvalid hexadecimal digit %c ", line[i]);
        	}
        	i++;
        	fprintf(bin_file, "%s", bit_seq);
        }
        fprintf(bin_file, "%s", "\n");
    }
    fclose(hex_file);
    fclose(bin_file);
    getchar();
    return 0;
}




