# Install and load required packages
required_packages <- c("psych", "car", "MVN", "moments", "boot")

# Function to install and load packages
install_required_packages <- function(packages) {
  for (package in packages) {
    if (!requireNamespace(package, quietly = TRUE)) {
      message(sprintf("Package '%s' not found. Attempting to install...", package))
      
      # Check library write permissions
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
        install.packages(package, dependencies=TRUE, repos="https://cran.rstudio.com/")
        message(sprintf("Successfully installed %s package", package))
      }, error = function(e) {
        stop(sprintf("ERROR: Failed to install %s package: %s", package, e$message))
      })
    }
    
    # Load the package
    tryCatch({
      if (!require(package, quietly = TRUE, character.only = TRUE)) {
        stop(sprintf("ERROR: Package '%s' could not be loaded after installation attempt", package))
      }
      message(sprintf("Successfully loaded %s package", package))
    }, error = function(e) {
      stop(sprintf("ERROR: Error loading %s package: %s", package, e$message))
    })
  }
}

# Install and load all required packages
install_required_packages(required_packages)

# Function to validate data
validate_data <- function(data) {
  # Check dimensions
  if (nrow(data) < 2) stop("ERROR: Data must have at least 2 rows")
  if (ncol(data) < 2) stop("ERROR: Data must have at least 2 columns")
  
  # Check for missing values
  if (any(is.na(data))) warning("WARNING: Data contains missing values which may affect results")
  
  # Check for non-numeric data
  if (!all(sapply(data, is.numeric))) stop("ERROR: All columns must contain numeric data")
  
  # Check for zero variance columns
  var_zero <- sapply(data, var) == 0
  if (any(var_zero)) warning("WARNING: Some items have zero variance")
  
  # Check for reasonable value ranges
  if (any(data < 0, na.rm = TRUE)) warning("WARNING: Data contains negative values - verify this is intended")
  
  message("Data validation passed. Processing analysis...")
}

# Function to calculate bootstrap confidence intervals
calculate_bootstrap_ci <- function(data, R = 1000, conf.level = 0.95) {
  boot_alpha <- function(data, indices) {
    d <- data[indices,]
    return(psych::alpha(d)$total$raw_alpha)
  }
  
  boot_result <- boot(data = data, statistic = boot_alpha, R = R)
  ci <- boot.ci(boot_result, type = "bca", conf = conf.level)
  return(list(lower = ci$bca[4], upper = ci$bca[5]))
}

# Function to perform normality tests
check_normality <- function(data) {
  # Shapiro-Wilk test for each item
  sw_tests <- apply(data, 2, shapiro.test)
  sw_results <- data.frame(
    Statistic = sapply(sw_tests, function(x) x$statistic),
    P_Value = sapply(sw_tests, function(x) x$p.value)
  )
  
  # Mardia's multivariate normality test
  mardia_test <- mvn(data, multivariatePlot = "qq")
  
  return(list(shapiro = sw_results, mardia = mardia_test))
}

# Create sample data frame with error checking
tryCatch({
  data <- data.frame(
    Item1 = c(4, 3, 5, 2, 4, 3, 5, 2),
    Item2 = c(3, 4, 2, 5, 3, 4, 2, 5),
    Item3 = c(5, 4, 3, 4, 5, 4, 3, 4),
    Item4 = c(2, 5, 4, 3, 2, 5, 4, 3)
  )
  
  validate_data(data)
  
}, error = function(e) {
  stop(paste("ERROR: Failed to create or validate data frame:", e$message))
})

# Calculate comprehensive reliability statistics
tryCatch({
  # Basic alpha calculation
  alpha_result <- psych::alpha(data)
  
  # Bootstrap confidence intervals
  boot_ci <- calculate_bootstrap_ci(data)
  
  # Normality tests
  normality_tests <- check_normality(data)
  
  # McDonald's omega
  omega_result <- psych::omega(data)
  
  # Greatest lower bound
  glb_result <- psych::glb(data)
  
  message("Successfully calculated reliability statistics")
}, error = function(e) {
  stop(paste("ERROR: Failed to calculate reliability statistics:", e$message))
})

# Print comprehensive results
cat("\n====================================================")
cat("\nCOMPREHENSIVE RELIABILITY ANALYSIS RESULTS")
cat("\n====================================================\n")

# Main reliability metrics
cat("\nRELIABILITY METRICS:")
cat("\n----------------------------------------------------")
cat(sprintf("\nCronbach's Alpha (raw): %.3f", alpha_result$total$raw_alpha))
cat(sprintf("\nCronbach's Alpha (standardized): %.3f", alpha_result$total$std.alpha))
cat(sprintf("\nMcDonald's Omega (total): %.3f", omega_result$omega.tot))
cat(sprintf("\nGreatest Lower Bound: %.3f", glb_result$glb))
cat(sprintf("\nAverage Inter-item Correlation: %.3f", alpha_result$total$average_r))
cat(sprintf("\nBootstrap 95%% CI: [%.3f, %.3f]", boot_ci$lower, boot_ci$upper))

# Sample characteristics
cat("\n\nSAMPLE CHARACTERISTICS:")
cat("\n----------------------------------------------------")
cat("\n1. Sample size:", nrow(data), "observations")
cat("\n2. Number of items:", ncol(data), "items")
cat("\n3. Missing data:", sum(is.na(data)), "cells")

# Normality assessment
cat("\n\nNORMALITY ASSESSMENT:")
cat("\n----------------------------------------------------")
cat("\nShapiro-Wilk Test Results:\n")
print(normality_tests$shapiro)
cat("\nMardia's Multivariate Normality Test:\n")
print(normality_tests$mardia$multivariateNormality)

# Item analysis
cat("\n\nITEM ANALYSIS:")
cat("\n----------------------------------------------------")
cat("\nReliability if Item Dropped:\n")
print(alpha_result$alpha.drop)

# Detailed item statistics
cat("\nDetailed Item Statistics:\n")
item_stats <- describe(data)
print(item_stats[,c("n","mean","sd","min","max","skew","kurtosis","se")])

# Inter-item correlations
cat("\nINTER-ITEM CORRELATION MATRIX:")
cat("\n----------------------------------------------------\n")
cor_matrix <- cor(data)
print(round(cor_matrix, 3))

# Factor analysis suggestion
if(ncol(data) >= 3) {
  cat("\nFACTOR ANALYSIS INDICATORS:")
  cat("\n----------------------------------------------------")
  kmo <- KMO(cor_matrix)
  cat(sprintf("\nKMO Measure of Sampling Adequacy: %.3f", kmo$MSA))
  bartlett <- cortest.bartlett(data)
  cat(sprintf("\nBartlett's Test p-value: %.3e", bartlett$p.value))
}

# Interpretation guidelines
cat("\n\nINTERPRETATION GUIDELINES:")
cat("\n----------------------------------------------------")
cat("\nReliability Coefficient Interpretation:")
cat("\n< 0.50: Unacceptable")
cat("\n0.50 - 0.59: Poor")
cat("\n0.60 - 0.69: Questionable")
cat("\n0.70 - 0.79: Acceptable")
cat("\n0.80 - 0.89: Good")
cat("\n>= 0.90: Excellent")

cat("\n\nKMO Interpretation:")
cat("\n>= 0.90: Marvelous")
cat("\n0.80 - 0.89: Meritorious")
cat("\n0.70 - 0.79: Middling")
cat("\n0.60 - 0.69: Mediocre")
cat("\n0.50 - 0.59: Miserable")
cat("\n< 0.50: Unacceptable")

cat("\n\nAnalysis completed successfully")
cat("\n====================================================\n")

# Save results to file if desired
# write.csv(item_stats, "reliability_analysis_results.csv")
