# aggBias — reproducible example reading CSV input data
# Methodology: expected aggregation bias from the paper
# Data: four-industry numerical validation example distributed with aggBias 0.1.0
# Files required in same directory:
#   transactions.csv, final_demand.csv, shocks.csv, covariance.csv,
#   initial_grouping.csv

# Install aggBias from GitHub if unavailable (internet required only for install)
if (!requireNamespace("aggBias", quietly = TRUE)) {
  if (!requireNamespace("remotes", quietly = TRUE))
    install.packages("remotes")
  remotes::install_github("HamidBekamiri/aggBias", upgrade = "never")
}
library(aggBias)

# Locate the directory containing this R script when run using Rscript.
# When running lines interactively from RStudio, set working directory to
# the downloaded example folder before sourcing.
script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg)) {
  data_dir <- dirname(normalizePath(sub("^--file=", "", script_arg[1])))
} else {
  data_dir <- getwd()
}
read_input <- function(filename) {
  path <- file.path(data_dir, filename)
  if (!file.exists(path)) stop("Missing file: ", path)
  read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
}

# 1. READ DATA FROM CSV (not hard-coded matrices)
tab_Z <- read_input("transactions.csv")
tab_f <- read_input("final_demand.csv")
tab_s <- read_input("shocks.csv")
tab_S <- read_input("covariance.csv")
tab_g <- read_input("initial_grouping.csv")

industries <- tab_Z$industry
stopifnot(length(industries) == length(unique(industries)),
          identical(colnames(tab_Z)[-1], industries),
          identical(tab_f$industry, industries),
          identical(tab_s$industry, industries),
          identical(tab_S$industry, industries),
          identical(colnames(tab_S)[-1], industries),
          identical(tab_g$industry, industries))

Z <- as.matrix(tab_Z[, -1, drop = FALSE]); storage.mode(Z) <- "double"
rownames(Z) <- industries
f <- tab_f$final_demand
mu <- tab_s$mean_shock
shock <- tab_s$realized_shock
Sigma <- as.matrix(tab_S[, -1, drop = FALSE]); storage.mode(Sigma) <- "double"
rownames(Sigma) <- industries
group <- as.integer(tab_g$sector)

cat("Loaded", nrow(Z), "industries from CSV files.\n")
cat("Transaction matrix (Z):\n"); print(Z)
cat("Final demand (f):\n"); print(f)

# 2. Build the detailed IO model
model <- io_model(Z, f)
G <- make_G(group)
agg <- aggregate_io(model, group)
cat("\nTechnical coefficients (A):\n"); print(round(model$A, 4))
cat("\nAggregated transactions:\n"); print(agg$Z)

# 3. Expected squared aggregation bias and its components
M <- bias_matrix(model, group)
systematic <- sum((M %*% mu)^2)
stochastic <- sum((M %*% Sigma) * M)
J <- expected_bias(model, group, mu, Sigma)
stopifnot(isTRUE(all.equal(J, systematic + stochastic, tolerance = 1e-12)))
stopifnot(abs(J - 0.057755803080969614) < 1e-10)
cat("\nOriginal grouping expected squared bias =", format(J, digits=10), "\n")
cat("Systematic component =", systematic, "\n")
cat("Stochastic component =", stochastic, "\n")
cat("RMS bias =", sqrt(J), "\n")

# 4. Realized shock response (true aggregated vs coarse model)
truth <- as.vector(t(G) %*% model$L %*% shock)
coarse <- as.vector(agg$L %*% t(G) %*% shock)
response <- data.frame(sector=seq_along(truth), true_response=truth,
                       aggregate_model_response=coarse, error=truth-coarse)
cat("\nShock response comparison:\n"); print(response)
stopifnot(isTRUE(all.equal(truth - coarse, as.vector(M %*% shock))))
cat("Realized bias share =",
    bias_share(model, group, matrix(shock, nrow = 1)), "\n")

# 5. Optimize the sector grouping
fit <- optimize_aggregation(
  model, k=2, mu=mu, covariance=Sigma,
  starts=list(group), n_random=10, seed=123
)
new_grouping <- data.frame(industry=industries,
                           original_group=group, optimized_group=fit$group)
cat("\nOptimal grouping found by multistart search:\n"); print(new_grouping)
cat("Optimized RMS bias =", fit$rms_bias, "\n")
cat("Estimated reduction (%) =", 100*(1-fit$rms_bias/sqrt(J)), "\n")
stopifnot(fit$loss <= J + 1e-9)

# 6. Frontier for 1 to 4 sectors, equal search settings
frontier <- aggregation_frontier(
  model, ks=1:4, mu=mu, covariance=Sigma,
  n_random=10, seed=123
)
cat("\nAggregation frontier:\n"); print(frontier$table)
stopifnot(abs(frontier$table$rms_bias[frontier$table$k == 4]) < 1e-10)

# 7. SAVE outputs next to source data
write.csv(response, file.path(data_dir, "output_shock_responses.csv"), row.names=FALSE)
write.csv(new_grouping, file.path(data_dir, "output_grouping.csv"), row.names=FALSE)
write.csv(frontier$table, file.path(data_dir, "output_frontier.csv"), row.names=FALSE)
png(file.path(data_dir, "output_frontier.png"), width=960, height=640)
plot(frontier$table$k, frontier$table$rms_bias,
     type="b", lwd=2, pch=19,
     xlab="Number of aggregate sectors (K)",
     ylab="RMS aggregation bias (input-data units)",
     main="aggBias: four-industry numerical example")
dev.off()
cat("\nDone! Wrote three output CSVs and output_frontier.png to:\n", data_dir, "\n")
