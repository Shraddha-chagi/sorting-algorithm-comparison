#Load required libraries
library(dplyr)
library(ggplot2)

#Import Python-generated benchmark data
bench <- read.csv("results/benchmark_results.csv")

#Inspect and validate the data
cat("Total observations:", nrow(bench), "\n")
print(head(bench))
print(names(bench))
print(dim(bench))
print(str(bench))

cat("\nCorrectness validation:\n")
print(table(bench$correct))

cat("\nMissing values:\n")
print(colSums(is.na(bench)))

# Convert columns to appropriate types
bench$algorithm <- factor(bench$algorithm)
bench$input_type <- factor(bench$input_type)
bench$correct <- tolower(bench$correct) == "true"

#Calculate descriptive statistics
summary_stats <- bench %>%
  group_by(algorithm, input_size, input_type) %>%
  summarise(
    trials = n(),
    mean_seconds = mean(runtime_seconds),
    median_seconds = median(runtime_seconds),
    variance = var(runtime_seconds),
    sd_seconds = sd(runtime_seconds),
    .groups = "drop"
  )

print(summary_stats)

#Create output folders
dir.create("outputs/figures",
           recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables",
           recursive = TRUE, showWarnings = FALSE)

# Save summary table
write.csv(
  summary_stats,
  "outputs/tables/review1_summary.csv",
  row.names = FALSE
)

#Box plot for random inputs
random_data <- subset(bench, input_type == "random")

p_box <- ggplot(
  random_data,
  aes(x = algorithm,
      y = runtime_seconds * 1000,
      fill = algorithm)
) +
  geom_boxplot() +
  facet_wrap(~input_size, scales = "free_y") +
  labs(
    title = "Sorting Algorithm Runtime Comparison",
    subtitle = "Random inputs across input sizes",
    x = "Sorting Algorithm",
    y = "Runtime (milliseconds)"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

print(p_box)

ggsave(
  "outputs/figures/review1_boxplot.png",
  plot = p_box,
  width = 12,
  height = 7,
  dpi = 300
)

#Runtime versus input size
mean_runtime <- aggregate(
  runtime_seconds ~ algorithm + input_size,
  data = random_data,
  FUN = mean
)

p_runtime <- ggplot(
  mean_runtime,
  aes(x = input_size,
      y = runtime_seconds * 1000,
      color = algorithm,
      group = algorithm)
) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  labs(
    title = "Runtime vs Input Size",
    subtitle = "Mean runtime on random inputs",
    x = "Input Size",
    y = "Mean Runtime (milliseconds)",
    color = "Algorithm"
  ) +
  theme_minimal()

print(p_runtime)

ggsave(
  "outputs/figures/runtime_vs_input_size_review1.png",
  plot = p_runtime,
  width = 12,
  height = 7,
  dpi = 300
)

#95% confidence intervals
# Fixed condition: random inputs, input size 1000
ci_data <- subset(
  bench,
  input_size == 1000 & input_type == "random"
)

ci_results <- ci_data %>%
  group_by(algorithm) %>%
  summarise(
    n = n(),
    mean_seconds = mean(runtime_seconds),
    sd_seconds = sd(runtime_seconds),
    .groups = "drop"
  ) %>%
  mutate(
    standard_error = sd_seconds / sqrt(n),
    margin_error = qt(0.975, df = n - 1) * standard_error,
    lower_95 = mean_seconds - margin_error,
    upper_95 = mean_seconds + margin_error,
    mean_ms = mean_seconds * 1000,
    lower_95_ms = lower_95 * 1000,
    upper_95_ms = upper_95 * 1000
  )
print(ci_results)

write.csv(
  ci_results,
  "outputs/tables/confidence_intervals_review1.csv",
  row.names = FALSE
)

#Confidence interval plot
p_ci <- ggplot(
  ci_results,
  aes(x = algorithm, y = mean_ms, color = algorithm)
) +
  geom_point(size = 4) +
  geom_errorbar(
    aes(ymin = lower_95_ms, ymax = upper_95_ms),
    width = 0.18,
    linewidth = 1
  ) +
  labs(
    title = "95% Confidence Intervals for Runtime",
    subtitle = "Random inputs, input size 1000",
    x = "Sorting Algorithm",
    y = "Mean Runtime (milliseconds)"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

print(p_ci)

ggsave(
  "outputs/figures/confidence_intervals_review1.png",
  plot = p_ci,
  width = 10,
  height = 6,
  dpi = 300
)

#Verify saved outputs
cat("\nSaved figures:\n")
print(list.files("outputs/figures"))

cat("\nSaved tables:\n")
print(list.files("outputs/tables"))

cat("\ndemonstration completed successfully.\n")
