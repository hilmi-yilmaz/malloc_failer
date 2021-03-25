#!/bin/bash

# This program places a wrapper around your malloc's and fails it after being called X times

cat << _EOF_ > example
Let say we have the following C program called "matrix.c":

0	#include <stdlib.h>
1
2	int	main(void)
3	{
4		int	i = 0;
5		int	j = 0;	
6		int	rows = 4;
7		int	columns = 4;
8		int **matrix;
9
10		matrix = (int **)malloc(sizeof(int *) * rows);
11		if (matrix == NULL)
12			return (-1);
13		while (i < rows)
14		{
15			matrix[i] = (int *)malloc(sizeof(int) * columns);
16			if (matrix[i] == NULL)
17				return (-1);
18			while (j < columns)
19			{
20				matrix[i][j] = 0;
21				j++;
22			}
23			j = 0;
24			i++;
25		}
26	
27		/* Free all data */
28		i = 0;
29		while (i < rows)
30		{
31			free(matrix[i]);
32			i++;
33		}
34		free(matrix);
35		return (0);
36	}

This program contains leaks when an allocation of matrix[i] fails when i > 0 (line 15).
To fail this malloc at the third time, you can run:

./fail_malloc.sh matrix.c 15 3

File to be tested				= matrix.c
Line number of malloc which we want to fail	= 15
Fail the chosen malloc after X times 		= 3

IMPORTANT: A new file will be created with the prefix "new_". In this case new_matrix.c.
You can run your code as usual but now with this new file. 

_EOF_

# The wrapper code
cat << _EOF_ > wrapper_malloc
/* ------------------------------------------------------------------------- */
/* ---------------------------- MALLOC WRAPPER ----------------------------- */
/* ------------------------------------------------------------------------- */

/*
** The below code block below is a wrapper for the malloc function.
** It fails after "fail" mallocs.
** Now you can be sure no leaks occur when your malloc fails!
*/

#include <stdlib.h>
#include <stddef.h>

static void	*xmalloc(size_t size)
{
	static int fail = ${3};
	static int i = 1;

	if (i == fail)
		return (NULL);
	i++;
	return (malloc(size));
}

/* ------------------------------------------------------------------------- */
/* ------------------------------------------------------------------------- */
/* ------------------------------------------------------------------------- */

_EOF_

# Input handling
if [[ "$1" == "--help" && "$2" == "" ]]; then
	cat example
	rm -f wrapper_malloc example
	exit 0
elif [[ "$1" == "" || "$2" == "" || "$3" == "" ]]; then
	echo "Error."
	echo "Use this tool as follows:"
	echo "./fail_malloc.sh [file_to_be_tested.c] [line_number_of_malloc] [at_which_malloc_to_fail]"
	echo ""
	echo "To seen an example run: ./fail_malloc.sh --help"
	rm -f wrapper_malloc example
	exit 1
else
	# Check whether the C file exists
	if [[ ! -e "$1" ]]; then
		echo "$1 doesn't exist."
		rm -f wrapper_malloc example
		exit 1
	fi

	# Check that the line number is a positive integer
	if [[ ! "$2" =~ ^[0-9]+$ ]]; then
		echo "$2 is not a valid line number. Enter number starting from 1."
		rm -f wrapper_malloc example
		exit 1
	fi

	# Check for the line number that it isn't 0
	if [[ "$2" == "0" ]]; then
		echo "$2 is not a valid line number. Enter number starting from 1."
		rm -f wrapper_malloc example
		exit 1
	fi

	# Check that the "fail @ X malloc" parameter starts from 0. 
	if [[ ! "$3" =~ ^[0-9]+$ ]]; then
		echo "$3 is not a valid number to let your malloc fail at. Enter number starting from 0."
		rm -f wrapper_malloc example
		exit 1
	fi
fi

# Check whether there is a malloc at the given line
# malloc_line=$(head -n "$2" "$1" | tail -1)
# if [[ ! "$malloc_line" =~ "malloc" ]]; then
# 	echo "There is no malloc on the given line."
# 	exit 1
# fi

# Make a copy of the input C file
cp "$1" copy_${1}

# Concatenate the wrapper file and the C file
cat wrapper_malloc copy_${1} > new_${1}

# The new "line number" of the malloc (it changed because we added wrapper malloc at the top of the file)
len_wrapper_file=$(wc -l < wrapper_malloc)
malloc_line_nb=$(($2 + $len_wrapper_file))

# Define malloc to be xmalloc
head -n $(($malloc_line_nb - 1)) new_${1} > temp
echo "#define malloc(x) xmalloc(x)" >> temp
head -n $malloc_line_nb new_${1} | tail -1 >> temp
echo "#undef malloc" >> temp
tail -n "+$(($2 + 1))" copy_${1} >> temp

# Set the temp to the new C file
cat temp > new_${1}

# Delete temporary files
rm -f example wrapper_malloc copy_${1} temp