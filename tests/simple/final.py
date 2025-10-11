# Class definition with methods
class DataProcessor:
    """A sample class with multiple statement types."""
    
    def __init__(self, name, values):
        # Assignment with attribute
        self.name = name
        self.values = values
        self.count = 0
    
    # Function definition with parameters
    def process_data(self, threshold=10, multiplier=2.5):
        """Process data with various operators and control flow."""
        # Assignment with binary operators
        result = threshold * multiplier
        adjusted = result + 100 - 50
        
        # Comparison and boolean operators
        if adjusted > 100 and threshold < 20:
            # Call with argument list
            self.increment_count(5)
        elif adjusted == 100 or multiplier > 2.0:
            result = result / 2
        else:
            # Unary operator
            result = -result
        
        # Return statement with parenthesized expression
        return (result + self.count)
    
    def increment_count(self, amount):
        # Binary operator in assignment
        self.count = self.count + amount
    
    def filter_values(self):
        """Demonstrate loops and subscript operations."""
        filtered = []
        
        # For statement with subscript
        for i in range(len(self.values)):
            # Subscript access
            value = self.values[i]
            
            # Not operator with comparison
            if not (value < 0):
                # Call with attribute and argument list
                filtered.append(value)
        
        # While statement
        index = 0
        while index < len(filtered) and filtered[index] < 100:
            # Subscript in assignment
            filtered[index] = filtered[index] * 2
            index += 1
        
        return filtered

# Function with multiple parameter types
def calculate_statistics(numbers, weights=None, normalize=True):
    """Standalone function with various expressions."""
    # Integer and float literals
    total = 0
    count = 0
    factor = 1.5
    
    # String literal
    operation = "sum"
    
    # List literal
    results = [0, 0, 0]
    
    # Tuple
    bounds = (0, 100)
    
    # For loop with tuple unpacking
    for idx, num in enumerate(numbers):
        # Parenthesized expression with multiple operators
        weighted = (num * factor) if weights is None else (num * weights[idx])
        
        # Boolean operator
        if weighted >= bounds[0] and weighted <= bounds[1]:
            total = total + weighted
            count += 1
    
    # Comparison operators
    if count == 0:
        return None
    
    # Binary operator with parenthesized expression
    average = total / (count if normalize else 1)
    
    # Return with call
    return round(average, 2)

# Create instance with call and argument list
processor = DataProcessor("TestProcessor", [10, 20, -5, 30, 45])

# Call with attribute access
result = processor.process_data(threshold=15, multiplier=3.0)

# Call standalone function with argument list
stats = calculate_statistics([1, 2, 3, 4, 5], normalize=False)

# Complex expression with multiple operators
final_value = (result + stats) * 2 if stats is not None else result

# Subscript with attribute
first_value = processor.values[0]

# Multiple boolean operators
is_valid = result > 0 and stats is not None and not (final_value < 0)

# Print call with multiple arguments
print("Result:", result, "Stats:", stats, "Valid:", is_valid)
