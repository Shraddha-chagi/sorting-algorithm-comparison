
# 03_run_analysis.R
# Reproducible statistical analysis of sorting algorithms

source("R/data_validation.R")
source("R/descriptive_statistics.R")
source("R/statistical_tests.R")
source("R/regression_analysis.R")

# 1. Load the saved benchmark data
benchmark_data <- read.csv(
  "data/raw/benchmark_results.csv"
)

# 2. Validate the data
validate_benchmark_data(benchmark_data)

# 3. Calculate descriptive statistics
summary_results <- calculate_descriptive_statistics(
  benchmark_data
)

write.csv(
  summary_results,
  "outputs/tables/descriptive_statistics.csv",
  row.names = FALSE
)

# 4. Run Friedman tests
friedman_results <- do.call(
  rbind,
  lapply(sort(unique(benchmark_data$input_size)), function(size) {
    test <- run_friedman_test(benchmark_data, size)
    
    data.frame(
      input_size = size,
      chi_squared = unname(test$statistic),
      degrees_of_freedom = unname(test$parameter),
      p_value = test$p.value,
      significant_at_5_percent = test$p.value < 0.05
    )
  })
)

write.csv(
  friedman_results,
  "outputs/tables/friedman_test_results.csv",
  row.names = FALSE
)

# 5. Run pairwise Wilcoxon tests with Holm correction
pairwise_results <- do.call(
  rbind,
  lapply(sort(unique(benchmark_data$input_size)), function(size) {
    results <- run_pairwise_tests(benchmark_data, size)
    results$input_size <- size
    results
  })
)

write.csv(
  pairwise_results,
  "outputs/tables/pairwise_test_results.csv",
  row.names = FALSE
)

# 6. Fit runtime regression models
regression_results <- fit_runtime_models(benchmark_data)

write.csv(
  regression_results,
  "outputs/tables/regression_results.csv",
  row.names = FALSE
)

# 7. Display results
cat("\n===== DESCRIPTIVE STATISTICS =====\n")
print(summary_results)

cat("\n===== FRIEDMAN TESTS =====\n")
print(friedman_results)

cat("\n===== PAIRWISE TESTS =====\n")
print(pairwise_results)

cat("\n===== REGRESSION RESULTS =====\n")
print(regression_results)

cat("\nAll statistical analyses completed successfully!\n")