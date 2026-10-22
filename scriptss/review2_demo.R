
# Hypothesis Testing and Comparative Analysis
library(dplyr)

# Load benchmark data
bench <- read.csv("results/benchmark_results.csv", stringsAsFactors = FALSE)

# Validate columns
required <- c(
  "algorithm", "input_size", "input_type",
  "trial", "runtime_seconds", "correct"
)

if (!all(required %in% names(bench))) {
  stop("Dataset is missing one or more required columns.")
}

# Prepare data types
bench$algorithm <- factor(bench$algorithm)
bench$input_type <- factor(bench$input_type)
bench$input_size <- as.numeric(bench$input_size)
bench$trial <- as.integer(bench$trial)
bench$runtime_seconds <- as.numeric(bench$runtime_seconds)
bench$correct <- tolower(as.character(bench$correct)) == "true"

# Validate observations
cat("Total observations:", nrow(bench), "\n")
cat("Algorithms:", levels(bench$algorithm), "\n")
cat("Input sizes:", sort(unique(bench$input_size)), "\n")
cat("Input types:", levels(bench$input_type), "\n")
cat("Incorrect results:", sum(!bench$correct, na.rm = TRUE), "\n")
cat("Missing values:", sum(is.na(bench)), "\n")

if (anyNA(bench[, required])) {
  stop("Missing or invalid values found in required columns.")
}

if (any(!is.finite(bench$runtime_seconds)) ||
    any(bench$runtime_seconds < 0)) {
  stop("Invalid runtime measurements found.")
}

if (!all(bench$correct)) {
  stop("Some algorithm correctness checks failed.")
}

# Create output folders
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)

# Check for duplicate measurements
duplicate_rows <- bench %>%
  count(input_size, input_type, trial, algorithm) %>%
  filter(n != 1)

if (nrow(duplicate_rows) > 0) {
  stop("Duplicate algorithm measurements found within a trial.")
}

# Prepare result containers
algorithms <- levels(droplevels(bench$algorithm))
conditions <- unique(bench[c("input_size", "input_type")])

friedman_list <- list()
pairwise_list <- list()

# Run tests for each input size and input type
for (i in seq_len(nrow(conditions))) {
  
  size_i <- conditions$input_size[i]
  type_i <- as.character(conditions$input_type[i])
  
  d <- subset(
    bench,
    input_size == size_i & input_type == type_i
  )
  
  # Match each algorithm by trial number
  wide <- reshape(
    d[, c("trial", "algorithm", "runtime_seconds")],
    idvar = "trial",
    timevar = "algorithm",
    direction = "wide"
  )
  
  expected_cols <- paste0("runtime_seconds.", algorithms)
  
  if (!all(expected_cols %in% names(wide))) {
    stop("An algorithm is missing from one or more test conditions.")
  }
  
  wide <- wide[complete.cases(wide[, expected_cols]), ]
  
  if (nrow(wide) < 2) {
    stop("Not enough matched trials to perform statistical tests.")
  }
  
  runtime_matrix <- as.matrix(wide[, expected_cols])
  storage.mode(runtime_matrix) <- "numeric"
  colnames(runtime_matrix) <- algorithms
  
  # Friedman test
  friedman_test <- friedman.test(runtime_matrix)
  
  friedman_list[[length(friedman_list) + 1]] <- data.frame(
    input_size = size_i,
    input_type = type_i,
    trials = nrow(runtime_matrix),
    statistic = unname(friedman_test$statistic),
    df = unname(friedman_test$parameter),
    p_value = friedman_test$p.value
  )
  
  # Pairwise paired Wilcoxon tests
  algorithm_pairs <- combn(algorithms, 2, simplify = FALSE)
  condition_results <- list()
  
  for (j in seq_along(algorithm_pairs)) {
    
    pair <- algorithm_pairs[[j]]
    x <- runtime_matrix[, pair[1]]
    y <- runtime_matrix[, pair[2]]
    
    wilcox_test <- wilcox.test(
      x, y,
      paired = TRUE,
      exact = FALSE
    )
    
    condition_results[[j]] <- data.frame(
      input_size = size_i,
      input_type = type_i,
      algorithm_1 = pair[1],
      algorithm_2 = pair[2],
      median_paired_difference = median(x - y),
      p_value = wilcox_test$p.value
    )
  }
  
  # Adjust the three pairwise tests within this condition
  condition_table <- do.call(rbind, condition_results)
  
  condition_table$adjusted_p_value <- p.adjust(
    condition_table$p_value,
    method = "holm"
  )
  
  condition_table$significant <- (
    condition_table$adjusted_p_value < 0.05
  )
  
  pairwise_list[[length(pairwise_list) + 1]] <- condition_table
}

# Combine test results
friedman_results <- do.call(rbind, friedman_list)
pairwise_results <- do.call(rbind, pairwise_list)

# Adjust the 12 Friedman tests for multiple comparisons
friedman_results$adjusted_p_value <- p.adjust(
  friedman_results$p_value,
  method = "holm"
)

friedman_results$significant <- (
  friedman_results$adjusted_p_value < 0.05
)

# Save results
write.csv(
  friedman_results,
  "outputs/tables/friedman_test_results_review2.csv",
  row.names = FALSE
)

write.csv(
  pairwise_results,
  "outputs/tables/pairwise_test_results_review2.csv",
  row.names = FALSE
)

# Display results
cat("\nFriedman Test Results:\n")
print(friedman_results)

cat("\nPairwise Wilcoxon Test Results:\n")
print(pairwise_results)

cat("\nSaved statistical results to outputs/tables.\n")
cat("hypothesis testing completed successfully.\n")



# ==========================================
# COMPARATIVE ANALYSIS VISUALIZATIONS
# ==========================================

library(ggplot2)
library(dplyr)

# Load benchmark data
bench <- read.csv(
  "results/benchmark_results.csv",
  stringsAsFactors = FALSE
)

bench$algorithm <- factor(bench$algorithm)
bench$input_type <- factor(
  bench$input_type,
  levels = c("random", "sorted", "reverse")
)

# Create output folders
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)


# ------------------------------------------
# PLOT 1: Runtime vs Input Size
# ------------------------------------------

p1 <- ggplot(
  bench,
  aes(
    x = input_size,
    y = runtime_seconds,
    color = algorithm,
    group = algorithm
  )
) +
  stat_summary(fun = mean, geom = "line", linewidth = 1) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  facet_wrap(~input_type, scales = "free_y") +
  labs(
    title = "Sorting Algorithm Runtime vs Input Size",
    subtitle = "Mean runtime across 30 trials",
    x = "Input Size",
    y = "Mean Runtime (seconds)",
    color = "Algorithm"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")

print(p1)

ggsave(
  "outputs/figures/runtime_comparison_review2.png",
  plot = p1,
  width = 10,
  height = 6,
  dpi = 300
)


# ------------------------------------------
# PLOT 2: Runtime Distribution at Size 2000
# ------------------------------------------

p2 <- ggplot(
  subset(bench, input_size == 2000),
  aes(
    x = algorithm,
    y = runtime_seconds,
    fill = algorithm
  )
) +
  geom_boxplot(alpha = 0.8, outlier.size = 1.5) +
  facet_wrap(~input_type, scales = "free_y") +
  labs(
    title = "Runtime Distribution at Input Size 2000",
    x = "Sorting Algorithm",
    y = "Runtime (seconds)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "none",
    axis.text.x = element_text(angle = 15, hjust = 1)
  )

print(p2)

ggsave(
  "outputs/figures/runtime_distribution_review2.png",
  plot = p2,
  width = 10,
  height = 6,
  dpi = 300
)


# ------------------------------------------
# PLOT 3: Mean Runtime by Input Type
# ------------------------------------------

mean_runtime <- bench %>%
  group_by(algorithm, input_type) %>%
  summarise(
    mean_runtime = mean(runtime_seconds),
    .groups = "drop"
  )

p3 <- ggplot(
  mean_runtime,
  aes(
    x = input_type,
    y = mean_runtime,
    fill = algorithm
  )
) +
  geom_col(position = "dodge") +
  labs(
    title = "Mean Runtime by Input Type",
    x = "Input Type",
    y = "Mean Runtime (seconds)",
    fill = "Algorithm"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")

print(p3)

ggsave(
  "outputs/figures/input_type_comparison_review2.png",
  plot = p3,
  width = 9,
  height = 6,
  dpi = 300
)


# ------------------------------------------
# PLOT 4: Runtime Growth on Log-Log Scales
# ------------------------------------------

p4 <- ggplot(
  bench,
  aes(
    x = input_size,
    y = runtime_seconds,
    color = algorithm,
    group = algorithm
  )
) +
  stat_summary(fun = mean, geom = "line", linewidth = 1) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  facet_wrap(~input_type) +
  scale_x_log10() +
  scale_y_log10() +
  labs(
    title = "Runtime Growth on Log-Log Scales",
    subtitle = "Mean runtime across trials",
    x = "Input Size (log scale)",
    y = "Mean Runtime (seconds, log scale)",
    color = "Algorithm"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")

print(p4)

ggsave(
  "outputs/figures/runtime_growth_loglog_review2.png",
  plot = p4,
  width = 10,
  height = 6,
  dpi = 300
)


# ------------------------------------------
# SAVE SUMMARY TABLE
# ------------------------------------------

write.csv(
  mean_runtime,
  "outputs/tables/mean_runtime_by_input_type_review2.csv",
  row.names = FALSE
)

cat("\nAll four plots displayed and saved successfully!\n")

# ==========================================
# REGRESSION ANALYSIS
# ==========================================

library(ggplot2)
library(dplyr)

# Load benchmark data
bench <- read.csv(
  "results/benchmark_results.csv",
  stringsAsFactors = FALSE
)

bench$algorithm <- factor(bench$algorithm)
bench$input_type <- factor(
  bench$input_type,
  levels = c("random", "sorted", "reverse")
)

dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------
# 1. Fit regression models for each condition
# ------------------------------------------

regression_results <- data.frame()

for (alg in levels(bench$algorithm)) {
  for (typ in levels(bench$input_type)) {
    
    d <- subset(
      bench,
      algorithm == alg & input_type == typ
    )
    
    model <- lm(runtime_seconds ~ input_size, data = d)
    model_summary <- summary(model)
    coefficients <- coef(model_summary)
    
    regression_results <- rbind(
      regression_results,
      data.frame(
        algorithm = alg,
        input_type = typ,
        observations = nrow(d),
        intercept = unname(coef(model)[1]),
        slope = unname(coef(model)[2]),
        r_squared = model_summary$r.squared,
        adjusted_r_squared = model_summary$adj.r.squared,
        slope_p_value = coefficients[2, "Pr(>|t|)"]
      )
    )
  }
}

# Save regression results
write.csv(
  regression_results,
  "outputs/tables/regression_results_review2.csv",
  row.names = FALSE
)

cat("\nREGRESSION RESULTS\n")
print(regression_results)


# ------------------------------------------
# 2. Regression plots for each input type
# ------------------------------------------

for (typ in levels(bench$input_type)) {
  
  d <- subset(bench, input_type == typ)
  
  p <- ggplot(
    d,
    aes(
      x = input_size,
      y = runtime_seconds,
      color = algorithm
    )
  ) +
    geom_point(alpha = 0.45) +
    geom_smooth(
      method = "lm",
      formula = y ~ x,
      se = TRUE
    ) +
    labs(
      title = paste("Linear Regression:", typ, "inputs"),
      subtitle = "Runtime versus input size",
      x = "Input Size",
      y = "Runtime (seconds)",
      color = "Algorithm"
    ) +
    theme_minimal(base_size = 12) +
    theme(legend.position = "bottom")
  
  # Display in RStudio
  print(p)
  
  # Save to repository
  filename <- paste0(
    "outputs/figures/regression_",
    typ,
    "_review2.png"
  )
  
  ggsave(
    filename,
    plot = p,
    width = 9,
    height = 6,
    dpi = 300
  )
}

cat("\nRegression analysis completed successfully!\n")




