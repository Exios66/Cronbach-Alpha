# Create example data frame
example_data <- data.frame(
  Item1 = c(4, 3, 5, 2, 4, 3, 5, 2, 4, 3),
  Item2 = c(3, 4, 4, 5, 3, 4, 4, 5, 3, 4),
  Item3 = c(5, 2, 3, 4, 5, 2, 3, 4, 5, 2),
  Item4 = c(2, 5, 4, 3, 2, 5, 4, 3, 2, 5),
  Item5 = c(4, 3, 5, 2, 4, 3, 5, 2, 4, 3)
)

# Save as .RData file
save(example_data, file = "example_data.RData")

# Also save as CSV for easier cross-language usage
write.csv(example_data, file = "example_data.csv", row.names = FALSE) 