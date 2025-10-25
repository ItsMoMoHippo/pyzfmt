# type annotations
from typing import Callable

# Callable with specific parameters
callback: Callable[[int, str], bool] = lambda x, s: x > 0

# function with type annotations
def process(name: str, age: int, scores: list[float]) -> dict[str, int]:
    return {"count": len(scores)}

# variable annotations
count: int = 0
names: list[str] = ["Alice", "Bob"]
mapping: dict[str, int] = {"a": 1, "b": 2}

# optional and union types
from typing import Optional, Union

result: Optional[str] = None
value: Union[int, str] = 42
