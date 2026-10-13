import csv
from collections import Counter
from pathlib import Path
CSV_FILE = (
    Path(__file__).resolve().parent
    / "results"
    / "benchmark_results_v2.csv"
)
expected_algorithms = {
    "Bubble Sort",
    "Insertion Sort",
    "Merge Sort",
}
expected_sizes = {100, 500, 1000, 2000}
expected_types = {"random", "sorted", "reverse"}
expected_trials = set(range(1, 31))
with CSV_FILE.open(
    "r", newline="", encoding="utf-8"
) as file:
    rows = list(csv.DictReader(file))
print("Total data rows:", len(rows))
assert len(rows) == 1080, "Unexpected number of rows!"
algorithms = {row["algorithm"] for row in rows}
assert algorithms == expected_algorithms, "Algorithm mismatch!"
assert all(
    int(row["input_size"]) in expected_sizes
    for row in rows
), "Unexpected input size!"
assert all(
    row["input_type"] in expected_types
    for row in rows
), "Unexpected input type!"
assert all(
    row["correct"].strip().lower() == "true"
    for row in rows
), "Some results failed correctness checks!"
counts = Counter(row["algorithm"] for row in rows)
print("\nMeasurements per algorithm:")
for algorithm, count in sorted(counts.items()):
    print(f"{algorithm}: {count}")
groups = Counter(
    (
        row["algorithm"],
        int(row["input_size"]),
        row["input_type"],
    )
    for row in rows
)
assert len(groups) == 36, "Unexpected number of experiment groups!"
assert all(count == 30 for count in groups.values()), (
    "Some groups do not have 30 trials!"
)
assert all(
    float(row["runtime_seconds"]) >= 0
    for row in rows
), "Negative runtime found!"
print("\nAll validation checks passed!")