try:
    result = 10 / 0
except ZeroDivisionError:
    result = None
except ValueError as e:
    print(e)
finally:
    print("Done")
