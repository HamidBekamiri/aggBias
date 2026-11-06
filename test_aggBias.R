# ============================================================
# aggBias: Installation and Reproducibility Test
# GitHub: https://github.com/HamidBekamiri/aggBias
# ============================================================

# 1. Install required installer
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

# 2. Install aggBias from GitHub
remotes::install_github(
  "HamidBekamiri/aggBias",
  dependencies = TRUE,
  upgrade = "never",
  force = TRUE
)

# 3. Load the package
library(aggBias)

# 4. Display package information
cat("\n====================================\n")
cat("aggBias PACKAGE INFORMATION\n")
cat("====================================\n")

cat("Package version:",
    as.character(packageVersion("aggBias")), "\n")

cat("Installation location:",
    find.package("aggBias"), "\n")

cat("Package description:\n")
print(packageDescription("aggBias")$Description)

# 5. List exported functions
cat("\n====================================\n")
cat("AVAILABLE FUNCTIONS\n")
cat("====================================\n")

functions <- getNamespaceExports("aggBias")
print(functions)

# 6. Display arguments of every exported function
cat("\n====================================\n")
cat("FUNCTION ARGUMENTS\n")
cat("====================================\n")

for (fn in functions) {

  obj <- getExportedValue("aggBias", fn)

  if (is.function(obj)) {
    cat("\nFunction:", fn, "\n")
    print(args(obj))
  }
}

# 7. Check package documentation
cat("\n====================================\n")
cat("DOCUMENTATION\n")
cat("====================================\n")

help(package = "aggBias")

# 8. Run documented examples
cat("\n====================================\n")
cat("RUNNING DOCUMENTED EXAMPLES\n")
cat("====================================\n")

results <- data.frame(
  function_name = character(),
  status = character(),
  details = character()
)

for (fn in functions) {

  cat("\nTesting:", fn, "\n")

  status <- "PASS"
  details <- "Example executed"

  tryCatch({

    # Execute examples from documentation
    example(
      topic = fn,
      package = "aggBias",
      ask = FALSE,
      echo = TRUE,
      character.only = TRUE
    )

  }, error = function(e) {

    status <<- "ERROR"
    details <<- conditionMessage(e)

  })

  results <- rbind(
    results,
    data.frame(
      function_name = fn,
      status = status,
      details = details
    )
  )
}

# 9. Summary
cat("\n====================================\n")
cat("TEST RESULTS\n")
cat("====================================\n")

print(results, row.names = FALSE)

# 10. Reproducibility information
cat("\n====================================\n")
cat("SESSION INFORMATION\n")
cat("====================================\n")

sessionInfo()

cat("\nTest script completed.\n")
