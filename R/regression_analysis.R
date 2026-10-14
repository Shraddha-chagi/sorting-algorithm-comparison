
fit_runtime_models <- function(data) {
  validate_benchmark_data(data)
  algorithms <- unique(data$algorithm)
  model_results <- lapply(algorithms, function(algo) {
    subset_data <- data[data$algorithm == algo, ]
    model <- lm(
      log(runtime_ms) ~ log(input_size),
      data = subset_data
    )
    coefficients <- coef(model)
    data.frame(
      algorithm = algo,
      intercept = unname(coefficients[1]),
      scaling_exponent = unname(coefficients[2]),
      r_squared = summary(model)$r.squared,
      stringsAsFactors = FALSE
    )
  })
  result <- do.call(rbind, model_results)
  rownames(result) <- NULL
  result
}
