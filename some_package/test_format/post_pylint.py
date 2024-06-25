#### This is the example formatted script
#### Note that black formats and writes over the file

def example_function(param1, param2):
    """
Black is an opinionated formatter for Python code, but it focuses on reformatting code style elements like indentation, spacing, and line length. It does not modify identifiers such as variable names, function names, or class names to follow naming conventions like snake_case or camelCase.
"""
    print("This is an example function")
    if param1 > param2:
        print("param1 is greater")
    else:
        print("param2 is greater or equal")


class MyClass:
    def __init__(self, value):
        self.value = value

    def get_value(self):
        return self.value


def example_FuncTion_2(param1, param2):
    # Black does not edit any 
    print("This is an example function")
    if param1 > param2:
        print("param1 is greater")
    else:
        print("param2 is greater or equal")
