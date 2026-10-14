
# ============================================================
# Project: Statistical Comparison of Sorting Algorithms
# File: algorithms.R
# Purpose: Implement and verify sorting algorithms
# ============================================================
# 1. Bubble Sort
bubble_sort <- function(x) {
  n <- length(x)
  if (n <= 1) {
    return(x)
  }
  for (i in seq_len(n - 1)) {
    swapped <- FALSE
    for (j in seq_len(n - i)) {
      if (x[j] > x[j + 1]) {
        temp <- x[j]
        x[j] <- x[j + 1]
        x[j + 1] <- temp
        swapped <- TRUE
      }
    }
    if (!swapped) {
      break
    }
  }
  return(x)
}

# 2. Insertion Sort
insertion_sort <- function(x) {
  n <- length(x)
  if (n <= 1) {
    return(x)
  }
  for (i in 2:n) {
    key <- x[i]
    j <- i - 1
    while (j >= 1 && x[j] > key) {
      x[j + 1] <- x[j]
      j <- j - 1
    }
    x[j + 1] <- key
  }
  return(x)
}

# 3. Merge Sort
merge_sort <- function(x) {
  n <- length(x)
  if (n <= 1) {
    return(x)
  }
  
  mid <- floor(n / 2)
  
  left <- merge_sort(x[seq_len(mid)])
  right <- merge_sort(x[(mid + 1):n])
  
  result <- numeric(n)
  i <- 1
  j <- 1
  k <- 1
  
  while (i <= length(left) && j <= length(right)) {
    if (left[i] <= right[j]) {
      result[k] <- left[i]
      i <- i + 1
    } else {
      result[k] <- right[j]
      j <- j + 1
    }
    k <- k + 1
  }
  while (i <= length(left)) {
    result[k] <- left[i]
    i <- i + 1
    k <- k + 1
  }
  while (j <= length(right)) {
    result[k] <- right[j]
    j <- j + 1
    k <- k + 1
  }
  return(result)
}