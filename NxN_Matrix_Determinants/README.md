# NxN Matrix Determinants

This program takes an input and an output filepath argument, iterates through input file to find NxN matrices, 
and recursively calculates the determinant of each matrix. Then, the matrix and along
with the calculated determinant solution are written to the output file in a standardized format. 


## Program Usage:

Ensure that the file has been unzipped and that your current working directory is NxN_Matrix_Determinants/ or that
you supply the proper filepath when calling the module.

```commandline
usage: python3 -m det_finder [-h] input_file output_file

Calculate the determinant of N x N matrices in the provided file

positional arguments:
   input_file   Starting Filepath
   output_file  Output Filepath

optional arguments:
  -h, --help   show this help message and exit
```

Example of command line argument using provided input/output files
```commandline
python3 -m det_finder ./Resources/Input_File.txt ./Resources/Output_File.txt
```
## Input File Organization
For optimal results using this program, you should ensure that the matrices in the provided input file adhere to 
the following formatting guidelines:
* Each provided matrix should have equal length sides (ex. 3x3, 4x4, etc)
  * Input matrices should be no larger than 8x8 in size
* The length of a single matrix side should be placed in the preceding line before any matrix values
* Spaces should separate distinct values in the same row of the matrix
  * multi-digit numbers and negative signs should be without spaces
* Each row of the matrix should have its own distinct line in the file

Example input file organization for a **3x3** and **2x2** matrix respectively:<br>

    3                                             (Indicates start of 3x3 matrix)
    1 0 0
    1 7 1
    0 4 9
    2                                             (Indicates start of 2x2 matrix)
    -10 1
    -1 0

## Project Layout

Description of files contained within 605.202.lab02

* NxN_Matrix_Determinants/: `The parent or "root" folder containing all the files within the program`
    * README.md:
      `This file! Contains instructions for how to use the program and a description of the package contents.`
    * Resources/:
      `Provided input and output files which can be used to test the program. Use of these files is optional 
      and any files can be used as long as a correct input filepath is specified. 
      If the specified output filepath does not exist, it will be created at the specified location`
    * Determinant_Finder/:
      `The module containing all of the code files that the program will run`
      * __init__.py
        `This file makes it easier for other files in the module to run the run_script() function which iterates 
        through the input_file, populates matrix objects, and then calls for the determinant function to run once they
        are full`
      * __main__.py
        `This file is the entrypoint of the program and makes sure that the command line arguments and 
        specified filepath locations are valid before calling the run_script function defined in lab02.py`
      * Matrix.py
        `This file contains the class definitions for a Matrix object which uses a 2-d array implementation, and 
        all of the methods available to Matrix objects.`
      * det_finder.py
        `This file contains the run_script function used to read through each input file character by character and
        fill Matrix objects as until filled. Once completely filled, the determinant is recursively calculated
        and the results are written to the specified output file.`

### Author
    Conner Engle
    Last Updated: 3/20/2022
    IDE Used: Pycharm
    Python Version: Python 3.8
    