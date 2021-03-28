# :smiling_imp: malloc_failer :smiling_imp:

### :warning: **This tool modifies your original files. Make sure you backup all your files before using this tool. This tool comes with the option to get your original file back like nothing changed. But if something goes wrong because of a bug, it is all your responsibility.** 

## :boom: Description

The malloc_failer let's you fail a specific malloc after X times. This can be used to check whether you have memory leaks when you exit your program because a malloc failed.

It adds the following wrapper code to your code (the X is given when running this script, explained in the **_Usage_** section):

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

Your original file is modified. A copy of your file is saved in the **_.malloc_failer/_** directory with the *.orig* prefix. Now you can run your program as always with a memory error detection tool, like:

```sh
gcc -Wall -Wextra -Werror -fsanitize=address -g matrix.c
```

To get your original file back, you can run:

```sh
./malloc_failer.sh --reverse
```

The reverse option makes sure your project directory is the same as before you ran the *malloc_failer*.

:warning: **Make sure you are using a memory error detection tool, so that leaks can be found. Examples of such detectors are ASAN (AdressSanitizer) and Valgrind.**

## :compass: Roadmap
- Add calloc and realloc.
- Make more user friendly.

## :mailbox: Contribute

Found a bug? Ran into a specific problem? Missing a feature? Feel free to **file a new issue** with a respective title and description on the [issue page](https://github.com/hilmi-yilmaz/malloc_failer/issues). You can also ask questions in [GitHub Discussion](https://github.com/hilmi-yilmaz/malloc_failer/discussions). 

## :credit_card: Credits
Thanks **_Tishj_** for finding some bugs and coming up with ideas for the _malloc_failer_!

## :blue_book: License
[MIT](https://opensource.org/licenses/MIT)