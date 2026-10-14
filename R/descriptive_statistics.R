
calculate_descriptive_statistics <- function(data) {
  validate_benchmark_data(data)
  
  groups <- split(
    data,
    interaction(data$algorithm, data$input_size, drop = TRUE)
  )
  
  summary_list <- lapply(groups, function(group) {
    runtimes <- group$runtime_ms
    data.frame(
      algorithm = group$algorithm[1],
      input_size = group$input_size[1],
      trials = length(runtimes),
      mean_ms = mean(runtimes),
      median_ms = median(runtimes),
      sd_ms = if (length(runtimes) > 1) sd(runtimes) else NA_real_,
      min_ms = min(runtimes),
      q1_ms = unname(quantile(runtimes, 0.25)),
      q3_ms = unname(quantile(runtimes, 0.75)),
      max_ms = max(runtimes),
      stringsAsFactors = FALSE
    )
  })
  result <- do.call(rbind, summary_list)
  rownames(result) <- NULL
  result
}
