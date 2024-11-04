# Install and load the psych package if not already installed
if (!requireNamespace("psych", quietly = TRUE)) {
  message("psych package not found. Attempting to install...")
  
  # Check if we can write to the library
  lib_paths <- .libPaths()
  can_write <- FALSE
  for (path in lib_paths) {
    if (file.access(path, mode=2) == 0) {
      can_write <- TRUE
      break
    }
  }
  
  if (!can_write) {
    stop("ERROR: No writeable R library paths found. Please contact your system administrator.")
  }
  
  # Try installing the package
  tryCatch({
    install.packages("psych", dependencies=TRUE, repos="https://cran.rstudio.com/")
    message("Successfully installed psych package")
  }, error = function(e) {
    stop(paste("ERROR: Failed to install psych package:", e$message))
  })
}

# Verify the package can be loaded
tryCatch({
  if (!require("psych", quietly = TRUE, character.only = TRUE)) {
    stop("ERROR: Package 'psych' could not be loaded after installation attempt")
  }
  message("Successfully loaded psych package")
}, error = function(e) {
  stop(paste("ERROR: Error loading psych package:", e$message)) 
})

# Create sample data frame with error checking
tryCatch({
  data <- data.frame(
    Item1 = c(4, 3, 5, 2),
    Item2 = c(3, 4, 2, 5),
    Item3 = c(5, 4, 3, 4)
  )
  
  # Validate data
  if (nrow(data) < 2) {
    stop("ERROR: Data must have at least 2 rows")
  }
  if (ncol(data) < 2) {
    stop("ERROR: Data must have at least 2 columns")
  }
  if (any(is.na(data))) {
    warning("WARNING: Data contains missing values which may affect results")
  }
  
  message("\nData validation passed. Processing analysis...")
  
}, error = function(e) {
  stop(paste("ERROR: Failed to create or validate data frame:", e$message))
})

# Calculate Cronbach's Alpha with error handling
tryCatch({
  alpha_result <- psych::alpha(data)
  message("Successfully calculated Cronbach's Alpha")
}, error = function(e) {
  stop(paste("ERROR: Failed to calculate Cronbach's Alpha:", e$message))
})

# Print detailed results with formatting
cat("\n============================================")
cat("\nCRONBACH'S ALPHA ANALYSIS RESULTS")
cat("\n============================================\n")

# Main results
cat("\nRELIABILITY METRICS:")
cat("\n--------------------------------------------")
cat(sprintf("\nRaw Alpha: %.3f", alpha_result$total$raw_alpha))
cat(sprintf("\nStandardized Alpha: %.3f", alpha_result$total$std.alpha))
cat(sprintf("\nAverage Inter-item Correlation: %.3f", alpha_result$total$average_r))

# Sample information
cat("\n\nSAMPLE INFORMATION:")
cat("\n--------------------------------------------")
cat("\n1. Sample size:", nrow(data), "observations")
cat("\n2. Number of items:", ncol(data), "items")

# Reliability if items dropped
cat("\n\nRELIABILITY IF ITEM DROPPED:")
cat("\n--------------------------------------------\n")
print(alpha_result$alpha.drop)

# Item statistics
cat("\nITEM STATISTICS:")
cat("\n--------------------------------------------\n")
item_stats <- describe(data)
print(item_stats[,c("n","mean","sd","min","max","skew","kurtosis")])

# Correlation matrix with formatting
cat("\nINTER-ITEM CORRELATION MATRIX:")
cat("\n--------------------------------------------\n")
cor_matrix <- cor(data)
print(round(cor_matrix, 3))

# Interpretation guidelines
cat("\nINTERPRETATION GUIDELINES:")
cat("\n--------------------------------------------")
cat("\nCronbach's Alpha interpretation:")
cat("\n< 0.50: Unacceptable")
cat("\n0.50 - 0.59: Poor")
cat("\n0.60 - 0.69: Questionable")
cat("\n0.70 - 0.79: Acceptable")
cat("\n0.80 - 0.89: Good")
cat("\n>= 0.90: Excellent")

cat("\n\nAnalysis completed successfully")
cat("\n============================================\n")
