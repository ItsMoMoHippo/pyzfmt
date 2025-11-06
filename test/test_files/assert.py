# Assert with error message
assert x > 0, "x must be positive"

# Assert with complex expression
assert len(items) > 0, f"Expected items, got {len(items)}"

# Assert with function call
assert is_valid(data), "Data validation failed"

# Multiple asserts (each is a separate statement)
assert x > 0
assert y > 0
assert x + y < 100

# Assert in code context
def divide(a, b):
    assert b != 0, "Cannot divide by zero"
    return a / b

# Assert with multiple conditions
assert x > 0 and y > 0, "Both x and y must be positive"

# Assert checking type
assert isinstance(value, int), f"Expected int, got {type(value)}"
