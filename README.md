### About

**count_loc** scans a directory at a specfic path for any Git Repositories and revtires a line count for the repository based on certain flags.

**count_loc** includes a python and shell script each with their own caveats.

The output of **count_loc** will be put in either lines_per_repo.csv or lines_per_file.csv depending on whether the file-level counts flag is passed.

### Feature List

| Feature                     | count_loc.py | count_loc.sh |
|:---------------------------:|:------------:|:------------:|
| Specify scanning path	      | [x]          | [x]          |
| Omit blank lines            | [x]          | [x]          |
| File level line counts      | [x]          | [x]          |
| Filter extentions (global)  | [x]          | [x]          |
| Filter extentions (by repo) | [x]          | [x]          |

### Caveats

The performance of ***count_loc.sh*** is significantly slower than that of ***count_loc.py***. ***count_loc.py*** can scan 500,000 lines of code in a few seconds, whereas ***count_loc.sh*** will take a couple minutes.

Only use ***count_loc.sh*** if it is the only option.

To use ***count_loc.sh*** on MacOS you need to install GNU Grep 
```brew install grep```
and uncomment line 11 of ***count_loc.sh***.

### Usage

Filtering by extensions, getting file level line counts, and omitting blank lines are all optional.

Providing a path to scan is also optional. By default the current directory will be scanned.

The path to be scanned must follow this pattern.

```
Path of Directory to Be Scanned /
|
|____Git Repo #1/
|	 |___.git/
|	 |___Other files in repo/
|
|____Git Repo #2/
|	 |___.git/
|	 |___Other files in repo/
|
|____Git Repo #3/
 	 |___.git/
 	 |___Other files in repo/
```

Usage for **count_loc.py**

```
Usage: count_loc.py [-h] [-p [PATH]] [-o] [-f] [-e | -m]

Count Lines of Code in Git Repos

optional arguments:
  -h, --help            show this help message and exit
  -p [PATH], --path [PATH]
                        Path to folder with Git Repos to be scanned
  -o, --omit-blank-lines
                        Omit all blank lines of code
  -f, --file-level-counts
                        Get a line count by each file in repo
  -e, --filter-by-extensions
                        Filter files by certain file extensions in
                        file_extensions.txt
  -m, --filter-by-map   Filter files by extensions for each git repo in
                        file_extensions_map.txt
```
Usage for **count_loc.sh**

```
Usage: count_loc.sh [-p [scan_dir]] [-o] [-f] [-e | -m]

Count Lines of Code in Git Repos

optional arguments:
  -p [scan_dir]
        Path to folder with Git Repos to be scanned
  -o
        Omit all blank lines of code
  -f
        Get a line count by each file in repo
  -e
        Filter files by certain file extensions in
        file_extensions.txt
  -m  
        Filter files by extensions for 
        each git repo in file_extensions_map.txt
```

### Configuration

To filter by specfic extentions globally specify the relevant extensions in file_extensions.txt. See [file_extensions.txt](https://github.com/a-n-u-b-i-s/count_loc/blob/master/file_extensions.txt) in this repo for an example.

To filter by specfic extentions by repository specify the relevant extensions in file_extensions_map.txt. See [file_extensions_map.txt](https://github.com/a-n-u-b-i-s/count_loc/blob/master/file_extensions_map.txt) in this repo for an example.
