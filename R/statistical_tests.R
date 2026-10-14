
run_friedman_test <- function(data, size) {
  validate_benchmark_data(data)
  subset_data <- data[data$input_size == size, ]
  if (nrow(subset_data) == 0) {
    stop("No data available for this input size.")
  }
  runtime_matrix <- reshape(
    subset_data[, c("trial", "algorithm", "runtime_ms")],
    idvar = "trial",
    timevar = "algorithm",
    direction = "wide"
  )
  expected_columns <- paste0(
    "runtime_ms.",
    c("Bubble Sort", "Insertion Sort", "Merge Sort")
  )
  if (!all(expected_columns %in% names(runtime_matrix))) {
    stop("Each trial must contain all three algorithms.")
  }
  runtime_matrix <- runtime_matrix[
    order(runtime_matrix$trial),
    expected_columns,
    drop = FALSE
  ]
  if (nrow(runtime_matrix) < 2) {
    stop("At least two matched trials are needed for this test.")
  }
  result <- friedman.test(as.matrix(runtime_matrix))
  return(result)
}

run_pairwise_tests <- function(data, size) {
  validate_benchmark_data(data)
  subset_data <- data[data$input_size == size, ]
  runtime_matrix <- reshape(
    subset_data[, c("trial", "algorithm", "runtime_ms")],
    idvar = "trial",
    timevar = "algorithm",
    direction = "wide"
  )
  runtime_matrix <- runtime_matrix[
    order(runtime_matrix$trial),
    ,
    drop = FALSE
  ]
  algorithms <- c(
    "Bubble Sort",
    "Insertion Sort",
    "Merge Sort"
  )
  pairs <- combn(algorithms, 2, simplify = FALSE)
  results <- lapply(pairs, function(pair) {
    col1 <- paste0("runtime_ms.", pair[1])
    col2 <- paste0("runtime_ms.", pair[2])
    test <- wilcox.test(
      runtime_matrix[[col1]],
      runtime_matrix[[col2]],
      paired = TRUE,
      exact = FALSE
    )
    data.frame(
      algorithm_1 = pair[1],
      algorithm_2 = pair[2],
      p_value = test$p.value,
      stringsAsFactors = FALSE
    )
  })
  result <- do.call(rbind, results)
  result$adjusted_p_value <- p.adjust(
    result$p_value,
    method = "holm"
  )
  result$significant_at_5_percent <-
    result$adjusted_p_value < 0.05
  
  rownames(result) <- NULL
  result
}
