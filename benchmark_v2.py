import csv
import random
import time
import platform
from pathlib import Path
from algorithms.bubble_sort import bubble_sort
from algorithms.insertion_sort import insertion_sort
from algorithms.merge_sort import merge_sort
# Project paths
BASE_DIR = Path(__file__).resolve().parent
RESULTS_DIR = BASE_DIR / "results"
CSV_FILE = RESULTS_DIR / "benchmark_results_v2.csv"
# Experimental settings
INPUT_SIZES = [100, 500, 1000, 2000]
INPUT_TYPES = ["random", "sorted", "reverse"]
TRIALS = 30
ALGORITHMS = {
    "Bubble Sort": bubble_sort,
    "Insertion Sort": insertion_sort,
    "Merge Sort": merge_sort,
}
def generate_input(size, input_type, rng):
    """Generate one input array for a given size and input type."""
    arr = [rng.randint(0, size * 10) for _ in range(size)]
    if input_type == "sorted":
        arr.sort()
    elif input_type == "reverse":
        arr.sort(reverse=True)
    return arr
def main():
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    rng = random.Random(42)
    order_rng = random.Random(2026)
    total = (
        len(INPUT_SIZES)
        * len(INPUT_TYPES)
        * len(ALGORITHMS)
        * TRIALS
    )
    completed = 0
    with CSV_FILE.open("w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow([
            "algorithm",
            "input_size",
            "input_type",
            "trial",
            "runtime_seconds",
            "correct",
        ])
        for size in INPUT_SIZES:
            for input_type in INPUT_TYPES:
                for trial in range(1, TRIALS + 1):
                    original = generate_input(size, input_type, rng)
                    expected = sorted(original)
                    algorithm_items = list(ALGORITHMS.items())
                    order_rng.shuffle(algorithm_items)
                    for name, algorithm in algorithm_items:
                        # Give each algorithm its own copy.
                        test_data = original.copy()
                        # Time only the sorting operation.
                        start = time.perf_counter()
                        output = algorithm(test_data)
                        elapsed = time.perf_counter() - start
                        correct = output == expected
                        if not correct:
                            raise ValueError(
                                f"{name} failed: size={size}, "
                                f"type={input_type}, trial={trial}"
                            )
                        writer.writerow([
                            name,
                            size,
                            input_type,
                            trial,
                            f"{elapsed:.10f}",
                            correct,
                        ])
                        completed += 1
                print(
                    f"Completed size={size}, "
                    f"type={input_type}"
                )
    print(f"\nCompleted {completed} measurements.")
    print(f"CSV saved to: {CSV_FILE}")
    print(f"Python version: {platform.python_version()}")
    print(f"Platform: {platform.platform()}")
if __name__ == "__main__":
    main()