# list_comprehension
squares = [x * x for x in range(10)]

# list_comprehension with condition
evens = [x for x in range(10) if x % 2 == 0]

# set_comprehension
unique_squares = {x * x for x in range(10)}

# set_comprehension with condition
even_set = {x for x in range(10) if x % 2 == 0}

# dictionary_comprehension
square_dict = {x : x * x for x in range(10)}

# dictionary_comprehension with condition
even_dict = {x : x * x for x in range(10) if x % 2 == 0}

# nested comprehensions
matrix = [[i * j for j in range(3)] for i in range(3)]

# comprehension with multiple for clauses
pairs = [(x, y) for x in range(3) for y in range(3)]

# comprehension with if-else (conditional_expression inside)
transformed = [x if x > 0 else 0 for x in [-1, 2, -3, 4]]
