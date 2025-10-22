# with_statement
with open("file.txt") as f:
    content = f.read()

# with_statement (multiple items)
with open("input.txt") as fin, open("output.txt") as fout:
    fout.write(fin.read())
