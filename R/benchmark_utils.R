
# ============================================================
# Project: Statistical Comparison of Sorting Algorithms
# File: benchmark_utils.R
# Purpose: Generate inputs and measure execution times
# ============================================================

# 1. Generate a reproducible random integer array
generate_input <- function(size) {
  if (length(size) != 1 || is.na(size) ||
      !is.finite(size) || size < 1 ||
      size != floor(size)) {
    stop("size must be a positive integer.")
  }
  sample.int(
    n = 1000000L,
    size = as.integer(size),
    replace = TRUE
  )
}


# 2. Measure execution time with adaptive repetitions
measure_runtime_ms <- function(sort_function,
                               input,
                               repetitions = 10L) {
  if (!is.function(sort_function)) {
    stop("sort_function must be a function.")
  }
  if (length(repetitions) != 1 ||
      is.na(repetitions) ||
      !is.finite(repetitions) ||
      repetitions < 1 ||
      repetitions != floor(repetitions)) {
    stop("repetitions must be a positive integer.")
  }
  # Warm-up
  invisible(sort_function(input))
  # Start with the requested number of repetitions.
  # Increase the batch until elapsed time is measurable.
  batch_size <- as.integer(repetitions)
  elapsed <- 0
  repeat {
    elapsed <- system.time({
      for (i in seq_len(batch_size)) {
        invisible(sort_function(input))
      }
    })[["elapsed"]]
    if (elapsed >= 0.05) {
      break
    }
    if (batch_size >= 10000000L) {
      stop("Unable to obtain a sufficiently measurable runtime.")
    }
    batch_size <- batch_size * 2L
  }
  # Average runtime per function call, in milliseconds
  (elapsed / batch_size) * 1000
}
# 3. Benchmark all three algorithms on the same input
benchmark_trial <- function(input, trial, repetitions = 10L) {
  algorithms <- list(
    "Bubble Sort" = bubble_sort,
    "Insertion Sort" = insertion_sort,
    "Merge Sort" = merge_sort
  )
  # Randomize measurement order to reduce systematic
  # bias from always measuring one algorithm first.
  order_names <- sample(names(algorithms))
  results <- lapply(order_names, function(name) {
    runtime <- measure_runtime_ms(
      sort_function = algorithms[[name]],
      input = input,
      repetitions = repetitions
    )
    data.frame(
      algorithm = name,
      input_size = length(input),
      trial = trial,
      runtime_ms = runtime,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, results)
}

# 4. Run the complete benchmark experiment
run_benchmarks <- function(input_sizes = c(100, 500, 1000, 2000),
                           trials = 30L,
                           repetitions = 10L,
                           seed = 207L) {
  set.seed(seed)
  all_results <- list()
  result_index <- 1L
  for (size in input_sizes) {
    for (trial in seq_len(trials)) {
      # Generate one input and share it across algorithms
      input <- generate_input(size)
      trial_results <- benchmark_trial(
        input = input,
        trial = trial,
        repetitions = repetitions
      )
      all_results[[result_index]] <- trial_results
      result_index <- result_index + 1L
    }
  }
  results <- do.call(rbind, all_results)
  rownames(results) <- NULL
  results
}