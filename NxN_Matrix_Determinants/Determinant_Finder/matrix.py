class ArrayMatrix:
    def __init__(self, size=0):
        """
        This class is used to store elements found while iterating through the input file into a 2-D array.
        Stored elements are retrieved when calculating the determinant and minors of the matrix are generated.
        :param size: The size of the n x n array initialized determined by the line preceding each matrix.
        """
        self.size = size
        self.num_elements = 0
        self.matrix = []
        self.minors = []

        for x in range(size):
            row = []
            for y in range(size):
                row.append('')
            self.matrix.append(row)

    def is_full(self):
        """
        Used to determine if initialized array is full.
        :return: Return True if number of elements in matrix equals size squared.
        """
        if self.num_elements > self.size ** 2 or self.num_elements < 0:
            raise IndexError('Number of elements outside of specified matrix bounds.')

        else:
            return self.num_elements == self.size ** 2

    def insert_at(self, column: int, row: int, value):
        """
        Inserts at specified column, row position if insert location is valid.
        :param column: int index of column number value is being inserted.
        :param row: int index of row number value is being inserted.
        :param value: character value being inserted into array column, row array location
        :return: Raises exception if insert location outside of specified bounds.
        """
        if row < 0 or row > self.size - 1 or column < 0 or column > self.size - 1:
            raise IndexError('Insert location outside of specified matrix bounds')

        elif value == '-':  # If character is a minus sign, does not move to next position
            self.matrix[column][row] = value

        elif self.matrix[column][row] == '-':  # If already stored value is a minus sign, replaces it with -value
            self.matrix[column][row] = -1*value
            self.num_elements += 1

        elif self.matrix[column][row] != '':  # Useful for 2+ digit numbers stored in array
            temp = str(self.matrix[column][row])
            value = str(value)
            value = temp+value
            self.matrix[column][row] = int(value)
            self.num_elements += 1

        else:
            #  print('inserting ' + str(value) + ' at: ' + str(row) + ', ' + str(column))
            self.matrix[column][row] = value
            self.num_elements += 1

    def insert_sequentially(self, value):
        """
        Used to insert in row major order into an empty array based on matrix size - utilizing the insert_at() method.
        :param value: Character value being stored into the array matrix location.
        :return: Raises exception if attempting to insert into an already full matrix.
        """
        row = int((self.num_elements/self.size))
        column = int(self.num_elements-int(row*self.size))

        if self.is_full():
            raise Exception('Matrix is already full')

        else:
            self.insert_at(column, row, value)

    def generate_minors(self):
        """
        Used to iterate through filled array matrix and store array minors for calculating the determinant.
        :return: Raises exception if attempting to generate minors for a partially-filled matrix.
        """
        if not self.is_full():
            raise Exception('The matrix is not completely filled')

        elif not len(self.minors) == 0:
            pass

        elif self.size == 1:  # 1 x 1 matrix does not have any minors
            return

        # Stores sub-arrays determined in row major order into self.minors
        else:
            i = 0
            while i < self.size:
                minor = ArrayMatrix(self.size - 1)
                x = 0
                y = 1
                while y < self.size:
                    while x < self.size:
                        if x != i:
                            minor.insert_sequentially(self.matrix[x][y])
                        x += 1
                    y += 1
                    x = 0
                self.minors.append(minor)
                i += 1

    def calc_determinant(self):
        """
        Used to recursively calculated determinant of n x n matrix using minors if matrix side length is greater than 2.
        Stopping cases for recursive function are n = 1 and n = 2.
        :return: Return summed integer determinant value after conclusion of recursive call.
        """
        if self.size == 1:
            return int(self.matrix[0][0])

        elif self.size == 2:
            return int(self.matrix[0][0]*int(self.matrix[1][1]))-(int(self.matrix[0][1])*int(self.matrix[1][0]))

        else:
            determinant = 0
            self.generate_minors()
            for minor in self.minors:
                determinant += ((-1)**(self.minors.index(minor)) *
                                self.matrix[self.minors.index(minor)][0]) * minor.calc_determinant()
                #  print(f'The determinant is {determinant}')

            return determinant
