from Determinant_Finder.matrix import ArrayMatrix


def run_script(input_path, output_path):
    """
    Iterates through the input file, stores matrix values into Matrix_Array(), finds determinant of each, then
    writes the calculated value to specified file output.
    :param input_path: User specified input file path
    :param output_path: User specified output file path
    """
    with input_path.open('r') as input_file, output_path.open('w') as output_file:

        output_string = ''
        matrix_initialized = False
        curr_matrix = None
        ready_to_process = False
        same_num = False  # For handling 2+ digit numbers in provided input arrays
        while True:
            char = input_file.read(1)

            # Outputs result of final matrix and handles end of file procedures
            if not char:
                det = curr_matrix.calc_determinant()
                output_string += f'The determinant is: {det}'
                output_string += '\n'
                output_file.write(output_string)
                # print("End of file")
                break

            # Initializes first matrix in file
            elif char.isnumeric() and not matrix_initialized:
                if int(char) >= 9:
                    raise Exception('Only 8x8 matrices or smaller can be evaluated')

                curr_matrix = ArrayMatrix(int(char))
                matrix_initialized = True
                output_string += char
                ready_to_process = False
                # print('Initializing matrix...')

            elif char == '\n':
                output_string += char
                same_num = False
                if curr_matrix.num_elements % curr_matrix.size != 0:
                    raise Exception('Number of elements in matrix does not match specified size')

                elif curr_matrix.is_full():
                    ready_to_process = True

            elif not char.isnumeric() and char != '-':
                output_string += char
                same_num = False

            # When at start of next matrix, calculates determinant of previous array if full and initializes new one
            elif curr_matrix.is_full() and char.isnumeric() and ready_to_process:
                # print('The matrix is '+str(curr_matrix.matrix))
                if int(char) >= 9:
                    raise Exception('Only 8x8 matrices or smaller can be evaluated')

                det = curr_matrix.calc_determinant()
                output_string += f'\nThe determinant is: {det}\n'
                output_string += '\n'
                output_file.write(output_string)
                output_string = str(char)
                curr_matrix = ArrayMatrix(int(char))
                # print("Writing to output file...\nInitializing new Matrix...")
                same_num = False
                ready_to_process = False

            elif char.isnumeric() and not same_num and not ready_to_process:
                output_string += char
                curr_matrix.insert_sequentially(int(char))
                same_num = True

            # Backtracks insert position if 2+ digit number found
            elif char.isnumeric() and same_num and not ready_to_process:
                output_string += char
                curr_matrix.num_elements -= 1
                curr_matrix.insert_sequentially(int(char))

            elif char.isnumeric() and ready_to_process:
                raise Exception('Number of elements provided rin matrix does not match specified length')

            # Handles negative signs, does not update number of elements stored so next integer stored there
            elif char == '-':
                output_string += char
                curr_matrix.insert_sequentially(char)
                # print(f"Read this char: {char}")

# python3 -m Determinant_Finder ./Resources/Input.txt ./Resources/Output.txt
