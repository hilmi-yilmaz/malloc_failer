#!/bin/bash

# This program places a wrapper around your malloc's and fails it after being called X times

print_example ()
{
cat << _EOF_
Let say we have the following C program called "matrix.c":

1	#include <stdlib.h>
2
3	int	main(void)
4	{
5		int	i = 0;
6		int	j = 0;	
7		int	rows = 4;
8		int	columns = 4;
9		int **matrix;
10
11		matrix = (int **)malloc(sizeof(int *) * rows);
12		if (matrix == NULL)
13			return (-1);
14		while (i < rows)
15		{
16			matrix[i] = (int *)malloc(sizeof(int) * columns);
17			if (matrix[i] == NULL)
18				return (-1);
19			while (j < columns)
20			{
21				matrix[i][j] = 0;
22				j++;
23			}
24			j = 0;
25			i++;
26		}
27	
28		/* Free all data */
29		i = 0;
30		while (i < rows)
31		{
32			free(matrix[i]);
33			i++;
34		}
35		free(matrix);
36		return (0);
37	}

This program contains leaks when an allocation of matrix[i] fails (line 16).
To fail this malloc at the third time, you can run:

./malloc_failer.sh matrix.c 16 3

File to be tested				= matrix.c
Line number of malloc which we want to fail	= 16
Fail the chosen malloc after X times 		= 3

IMPORTANT: A new file will be created with the prefix "new_". In this case new_matrix.c.
You can run your code as usual but now with this new file. 

_EOF_
}

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

static void	*xmalloc(size_t size)
{
	int X = ${3};
	static int i = 1;

	if (i == X)
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
	print_example
	rm -f wrapper_malloc
	exit 0
elif [[ "$1" == "--reverse" && "$2" == "" ]]; then

	#Check whether .malloc_failer/ directory exists
	if [[ ! -d .malloc_failer/ ]]; then
		echo "There are no backup files. Run this tool first."
		echo "Run with: ./malloc_failer.sh [file_to_be_tested.c] [line_number_of_malloc] [at_which_malloc_to_fail]"
		echo "Before running with --reverse."
		rm -f wrapper_malloc
		exit 1
	else
		for file_orig in .malloc_failer/* ; do
			file=${file_orig%.orig} 			# if 	file_orig = .malloc_fail/test.c.orig
			file=${file##*/}					# then 	file = test.c
			cp $file_orig $file
			rm -f $file_orig
		done
		rm -df .malloc_failer/ wrapper_malloc
		exit 0
	fi
elif [[ "$1" == "" || "$2" == "" || "$3" == "" ]]; then
	echo "Error."
	echo "Use this tool as follows:"
	echo "./malloc_failer.sh [file_to_be_tested.c] [line_number_of_malloc] [at_which_malloc_to_fail]"
	echo ""
	echo "To seen an example run: ./malloc_failer.sh --help"
	echo "To get your original files back run: ./malloc_failer.sh --reverse"
	rm -f wrapper_malloc
	exit 1
else
	# Check whether the C file exists
	if [[ ! -e "$1" ]]; then
		echo "$1 doesn't exist."
		rm -f wrapper_malloc
		exit 1
	fi

	# Check that the line number is a positive integer
	if [[ ! "$2" =~ ^[0-9]+$ ]]; then
		echo "$2 is not a valid line number. Enter number starting from 1."
		rm -f wrapper_malloc
		exit 1
	fi

	# Check for the line number that it isn't 0
	if [[ "$2" == "0" ]]; then
		echo "$2 is not a valid line number. Enter number starting from 1."
		rm -f wrapper_malloc
		exit 1
	fi

	# Check that the "fail at X malloc" parameter is a positive integer. 
	if [[ ! "$3" =~ ^[0-9]+$ ]]; then
		echo "$3 is not a valid number to let your malloc fail at. Enter number starting from 1 (1 means fail first malloc)."
		rm -f wrapper_malloc
		exit 1
	fi

	# Check for the "fail at X malloc" parameter that it isn't 0
	if [[ "$3" == "0" ]]; then
		echo "$3 is not a valid number to let your malloc fail at. Enter number starting from 1 (1 means fail first malloc)."
		rm -f wrapper_malloc
		exit 1
	fi
fi

# Create .malloc_failer/ directory in which we are going to store the original files
[ ! -d .malloc_failer/ ] && mkdir .malloc_failer/

# Make a copy of the input C file
cp "$1" .malloc_failer/${1}.orig

# Concatenate the wrapper file and the C file
cat wrapper_malloc .malloc_failer/${1}.orig > ${1}

# The new "line number" of the malloc (it changed because we added wrapper malloc at the top of the file)
len_wrapper_file=$(wc -l < wrapper_malloc)
malloc_line_nb=$(($2 + $len_wrapper_file))

# Define malloc to be xmalloc
head -n $(($malloc_line_nb - 1)) ${1} > temp
echo "#define malloc(x) xmalloc(x)" >> temp
head -n $malloc_line_nb ${1} | tail -1 >> temp
echo "#undef malloc" >> temp
tail -n "+$(($2 + 1))" .malloc_failer/${1}.orig >> temp

# Set the temp to the new C file
cat temp > ${1}

# Delete temporary files
rm -f wrapper_malloc temp