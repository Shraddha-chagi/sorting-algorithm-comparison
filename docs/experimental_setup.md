# Experimental Setup — Statistical Comparison of Sorting Algorithms

## 1. Objective

To compare the execution-time performance of Bubble Sort, Insertion Sort, and Merge Sort under controlled input sizes and input arrangements.

## 2. Implementation

The three sorting algorithms were implemented in Python. Each algorithm accepts a list and returns a sorted list. The output is checked against Python's built-in sorted function for correctness.

## 3. Experimental Parameters

- Algorithms: Bubble Sort, Insertion Sort, Merge Sort
- Input sizes: 100, 500, 1,000, and 2,000 elements
- Input types: Random, ascending sorted, and reverse sorted
- Repetitions: 30 trials per algorithm, input size, and input type
- Total timing observations: 1,080
- Timing method: Python time.perf_counter()
- Output format: CSV

## 4. Data Collection

Input arrays were generated before timing began. Each algorithm received a copy of the same input for a corresponding trial. Only the sorting function call was timed. Each output was checked against the expected sorted array, and execution times were recorded in benchmark_results.csv.

## 5. Reproducibility

The benchmark uses a fixed random seed to make input generation reproducible. The Python version, operating system, and other relevant experimental conditions should be recorded with the final results.

## 6. Limitations

Execution times can be affected by background processes, system load, and execution order. The benchmark's algorithm execution order should be reviewed before final analysis. The results describe the tested implementation and environment and should not automatically be generalized to every system.

## 7. Deliverables

- Sorting algorithm implementations
- Benchmarking script
- Raw CSV dataset
- Dataset validation script
- Experimental setup documentation