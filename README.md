# Statistical Comparison of Sorting Algorithms

## Project Overview

This project compares Bubble Sort, Insertion Sort, and Merge Sort using controlled experiments and statistical analysis.

**Track:** Track 5 — Hypothesis Testing & Comparative Analysis

## Algorithms

- **Bubble Sort:** Repeatedly compares and swaps adjacent elements.
- **Insertion Sort:** Inserts each element into its correct position in the sorted portion.
- **Merge Sort:** Uses divide-and-conquer to sort and merge smaller lists.

## Experimental Configuration

- Input sizes: 100, 500, 1,000, and 2,000
- Input types: Random, sorted, and reverse sorted
- Repetitions: 30 trials per experimental combination
- Timing method: Python `time.perf_counter()`
- Expected observations per full run: 1,080

## Project Structure

- `algorithms/`: Sorting algorithm implementations
- `benchmark.py`: Original benchmarking program
- `benchmark_v2.py`: Benchmark with randomized algorithm execution order
- `validate_results.py`: Original dataset validation
- `validate_results_v2.py`: Revised dataset validation
- `results/`: CSV benchmark datasets
- `docs/`: Experimental setup documentation

## Running the Project

Run the original benchmark:

```bash
python benchmark.py
```

Run the revised benchmark:

```bash
python benchmark_v2.py
```

Validate the datasets:

```bash
python validate_results.py
python validate_results_v2.py
```

Run these commands from the project root. If Python is invoked as `py` on Windows, use `py` instead of `python`.

## Dataset

Each CSV contains the algorithm name, input size, input type, trial number, runtime in seconds, and correctness status.

## Limitations

Measured execution times depend on the hardware, operating system, Python environment, background processes, and experimental design. Results should be interpreted in the context of the tested setup.

## Team Handover

The raw CSV datasets are intended for statistical analysis in R/RStudio and visualization as part of the integrated project.
