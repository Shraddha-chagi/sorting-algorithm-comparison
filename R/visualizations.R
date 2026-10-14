
plot_runtime_comparison <- function(data) {
  validate_benchmark_data(data)
  summary_data <- aggregate(
    runtime_ms ~ algorithm + input_size,
    data = data,
    FUN = median
  )
  algorithms <- unique(summary_data$algorithm)
  plot(
    NA,
    xlim = range(summary_data$input_size),
    ylim = range(summary_data$runtime_ms),
    xlab = "Input Size (number of elements)",
    ylab = "Median Runtime (milliseconds)",
    main = "Sorting Algorithm Runtime Comparison"
  )
  for (algo in algorithms) {
    subset_data <- summary_data[
      summary_data$algorithm == algo, ]
    lines(
      subset_data$input_size,
      subset_data$runtime_ms,
      type = "b",
      pch = match(algo, algorithms)
    )
  }
  legend(
    "topleft",
    legend = algorithms,
    col = seq_along(algorithms),
    pch = seq_along(algorithms),
    lty = 1,
    bty = "n"
  )
}

plot_runtime_boxplots <- function(data, size) {
  validate_benchmark_data(data)
  subset_data <- data[data$input_size == size, ]
  if (nrow(subset_data) == 0) {
    stop("No data available for this input size.")
  }
  boxplot(
    runtime_ms ~ algorithm,
    data = subset_data,
    xlab = "Sorting Algorithm",
    ylab = "Runtime (milliseconds)",
    main = paste("Runtime Variability: Input Size", size),
    col = "lightblue"
  )
}