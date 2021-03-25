# :smiling_imp: malloc_failer :smiling_imp:

## :boom: Description

The malloc_failer let's you fail a specific malloc after X times. This can be used to check whether you have memory leaks when you exit your program because a malloc failed.

It adds the following wrapper code to your code (the X is given when running this script, explained in **_Usage_**):

```C
#include <stdlib.h>

static void	*xmalloc(size_t size)
{
	static int fail = X;
	static int i = 1;

	if (i == fail)
		return (NULL);
	i++;
	return (malloc(size));
}
```

It then sandwiches your malloc between this **_#define_** directive:

```C
#define malloc(x) xmalloc(x)
int **matrix = (int **)malloc(size); /* This would be the malloc you want to fail */
#undef malloc
```

## :gear: Installation and Setup

Clone this repository. The only file you need is **_malloc_failer.sh_**, which is an executable.

## :video_game: Usage

There are 3 things you need to specify:<br>

1. The file from which to fail a malloc.
2. The line number of the malloc.
3. X, which is a number at which to fail the malloc.

The format is:

```sh
./malloc_failer.sh [file_to_be_tested.c] [line_number_of_malloc] [at_which_malloc_to_fail]
```

## :soccer: Example

Below you can see an example program. Let's say this file is called **_matrix.c_**.

```C
#include <stdlib.h>

int	main(void)
{
	int	i = 0;
	int	j = 0;
	int	rows = 4;
	int	columns = 4;
	int **matrix;

	matrix = (int **)malloc(sizeof(int *) * rows);
	if (matrix == NULL)
		return (-1);
	while (i < rows)
	{
		matrix[i] = (int *)malloc(sizeof(int) * columns); /* ----- line 16 ----- */
		if (matrix[i] == NULL)
			return (-1);
		while (j < columns)
		{
			matrix[i][j] = 0;
			j++;
		}
		j = 0;
		i++;
	}
	/* Free all data */
	i = 0;
	while (i < rows)
	{
		free(matrix[i]);
		i++;
	}
	free(matrix);
	return (0);
}
```
This program contains leaks when an allocation of `matrix[i]` fails (line 16). To fail the malloc on line 16 at the third time, you can run:

```sh
./malloc_failer.sh matrix.c 16 3
```

This wil result in a new file with the prefix "new_", in this case the new file would be **_new_matrix.c_**. You can use this file when compiling your program, instead of the original **_matrix.c_**:

```sh
gcc -Wall -Wextra -Werror -fsanitize=address -g new_matrix.c
```

:warning: **Make sure you are using a memory error detection tool, so that leaks can be found. Examples of such detectors are ASAN (AdressSanitizer) or Valgrind.**

## :mailbox: Contribute

Found a bug? Ran into a specific problem? Missing a feature? Feel free to **file a new issue** with a respective title and description on the [issue page](https://github.com/hilmi-yilmaz/malloc_failer/issues). You can also ask questions in [GitHub Discussion](https://github.com/hilmi-yilmaz/malloc_failer/discussions). 

## :blue_book: License
[MIT](https://opensource.org/licenses/MIT)