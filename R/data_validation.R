
# ============================================================
# Project: Statistical Comparison of Sorting Algorithms
# File: data_validation.R
# Purpose: Validate benchmark data before statistical analysis
# ============================================================

validate_benchmark_data <- function(data) {
  required_columns <- c(
    "algorithm",
    "input_size",
    "trial",
    "runtime_ms"
  )
  
  # 1. Check required columns
  missing_columns <- setdiff(
    required_columns,
    names(data)
  )
  if (length(missing_columns) > 0) {
    stop(
      "Missing columns: ",
      paste(missing_columns, collapse = ", ")
    )
  }
  
  # 2. Check for missing values
  if (anyNA(data[, required_columns])) {
    stop("Dataset contains missing values.")
  }
  
  # 3. Check algorithm names
  allowed_algorithms <- c(
    "Bubble Sort",
    "Insertion Sort",
    "Merge Sort"
  )
  if (!all(data$algorithm %in% allowed_algorithms)) {
    stop("Dataset contains unknown algorithm names.")
  }
  
  # 4. Check numeric columns
  if (!is.numeric(data$input_size) ||
      !is.numeric(data$trial) ||
      !is.numeric(data$runtime_ms)) {
    stop("Input size, trial, and runtime must be numeric.")
  }
  
  # 5. Check positive integer input sizes and trial IDs
  if (any(!is.finite(data$input_size)) ||
      any(data$input_size < 1) ||
      any(data$input_size != floor(data$input_size))) {
    stop("Input sizes must be positive integers.")
  }
  if (any(!is.finite(data$trial)) ||
      any(data$trial < 1) ||
      any(data$trial != floor(data$trial))) {
    stop("Trial IDs must be positive integers.")
  }
  
  # 6. Check runtime measurements
  if (any(!is.finite(data$runtime_ms)) ||
      any(data$runtime_ms <= 0)) {
    stop("Runtime measurements must be finite and positive.")
  }
  
  # 7. Each algorithm should occur once per size and trial
  if (anyDuplicated(
    data[, c("algorithm", "input_size", "trial")]
  )) {
    stop("Duplicate algorithm/input-size/trial records found.")
  }
  
  # 8. Each trial must contain all three algorithms
  trial_groups <- split(
    data$algorithm,
    interaction(data$input_size, data$trial, drop = TRUE)
  )
  complete_trials <- vapply(
    trial_groups,
    function(x) {
      length(x) == length(allowed_algorithms) &&
        setequal(x, allowed_algorithms)
    },
    logical(1)
  )
  if (!all(complete_trials)) {
    stop("Some trials do not contain all three algorithms.")
  }
  message("Benchmark data validation passed.")
  invisible(TRUE)
}