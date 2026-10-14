
# 04_generate_figures.R
# Generate and save project visualizations

source("R/algorithms.R")
source("R/benchmark_utils.R")
source("R/data_validation.R")
source("R/descriptive_statistics.R")
source("R/visualizations.R")

benchmark_data <- read.csv(
  "data/raw/benchmark_results.csv"
)

validate_benchmark_data(benchmark_data)

# Figure 1: Runtime comparison
png(
  "outputs/figures/runtime_comparison.png",
  width = 1200,
  height = 800,
  res = 120
)

plot_runtime_comparison(benchmark_data)

dev.off()

# Figure 2: Runtime variability at input size 500
png(
  "outputs/figures/runtime_boxplot_500.png",
  width = 1200,
  height = 800,
  res = 120
)

plot_runtime_boxplots(benchmark_data, size = 500)

dev.off()

cat("Figures generated successfully!\n")
cat("Check the outputs/figures folder.\n")
