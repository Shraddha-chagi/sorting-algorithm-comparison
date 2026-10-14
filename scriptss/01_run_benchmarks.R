
# 01_run_benchmarks.R
# Benchmark Bubble Sort, Insertion Sort, and Merge Sort

# 1. Load required functions
source("R/algorithms.R")
source("R/benchmark_utils.R")
source("R/data_validation.R")

cat("Starting sorting algorithm benchmarks...\n")

# 2. Configure the experiment
input_sizes <- c(100, 300, 500, 800)
trials <- 10
repetitions <- 10

# 3. Run benchmarks
set.seed(207)

benchmark_data <- run_benchmarks(
  input_sizes = input_sizes,
  trials = trials,
  repetitions = repetitions
)

# 4. Validate the results
validate_benchmark_data(benchmark_data)

# 5. Save the raw measurements
output_file <- "data/raw/benchmark_results.csv"

write.csv(
  benchmark_data,
  file = output_file,
  row.names = FALSE
)

# 6. Display a summary
cat("\nBenchmark completed successfully!\n")
cat("Algorithms:", length(unique(benchmark_data$algorithm)), "\n")
cat("Input sizes:", length(input_sizes), "\n")
cat("Trials per input size:", trials, "\n")
cat("Total measurements:", nrow(benchmark_data), "\n")
cat("Saved to:", output_file, "\n")

print(
  aggregate(
    runtime_ms ~ algorithm + input_size,
    data = benchmark_data,
    FUN = median
  )
)
