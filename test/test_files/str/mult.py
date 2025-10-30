# multi-line string with triple double quotes
text1 = """This is a
multi-line
string"""

# multi-line f-string
name = "Alice"
message = f"""Hello {name},
This is a multi-line
formatted string."""

# multi-line byte
data3 = b"""multi
line
bytes"""

# raw multi-line string
regex_pattern = r"""
\d+\.?\d*  # numbers
\s+        # whitespace
[a-zA-Z]+  # letters
"""

# unicode multi-line string
text = u"""Hello
世界
Multiple lines"""

# raw unicode multi-line
combined = ru"""C:\Users\name
C:\Documents\files
Multiple paths"""

# raw f-string multi-line
name = "Alice"
path = rf"""User: {name}
Path: C:\Users\{name}\documents
Files: C:\Users\{name}\files"""
