# aggBias v0.1.0 — worked numerical example from the package validation tests
# Corresponds to the expected aggregation-bias objective used in the paper.
# Source: https://github.com/HamidBekamiri/aggBias

if (!requireNamespace("aggBias", quietly = TRUE)) {
  if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")
  remotes::install_github("HamidBekamiri/aggBias", upgrade = "never")
}
library(aggBias)

# 1. Original four-industry numerical test data
Z <- matrix(c(10,2,1,0,
              3,12,2,1,
              1,3,8,2,
              0,1,2,6), nrow = 4, byrow = TRUE)
f <- c(20,25,15,10)
rownames(Z) <- colnames(Z) <- paste0("Industry_", 1:4)
names(f) <- rownames(Z)

model <- io_model(Z, f)
cat("Detailed input-output coefficients:\n")
print(round(model$A, 4))

# 2. Group industries 1 & 2 and 3 & 4
initial_group <- c(1,1,2,2)
G <- make_G(initial_group)
aggregated <- aggregate_io(model, initial_group)
cat("\nAggregation matrix G:\n")
print(G)
cat("\nAggregated transaction matrix:\n")
print(aggregated$Z)
cat("\nAggregated final demand:\n")
print(aggregated$f)

# 3. Mean and covariance of additive final-demand shocks
# Exactly as specified in the package's validation test
mu <- c(1,2,-1,0)
Sigma <- diag(c(2,1,3,1))

# Paper's M(G) = G' L - L_aggregated G'
M <- bias_matrix(model, initial_group)

# Expected squared aggregation bias = systematic + stochastic
systematic <- sum((M %*% mu)^2)
stochastic <- sum((M %*% Sigma) * M)
J <- expected_bias(model, initial_group, mu, Sigma)
RMS <- sqrt(J)

cat("\n--- INITIAL GROUPING ---\n")
cat("Systematic squared error:", systematic, "\n")
cat("Stochastic squared error:", stochastic, "\n")
cat("Expected squared bias:", J, "\n")
cat("RMS aggregation bias:", RMS, "\n")
stopifnot(abs(J - 0.057755803080969614) < 1e-10)

# 4. Compare true and aggregated responses to a realized shock
shock <- c(1,2,-1,0)
true_agg_response <- as.vector(t(G) %*% model$L %*% shock)
model_agg_response <- as.vector(aggregated$L %*% t(G) %*% shock)
realized_error <- true_agg_response - model_agg_response
cat("\n--- SHOCK RESPONSE COMPARISON ---\n")
print(data.frame(
  sector = 1:2,
  true_response = true_agg_response,
  aggregated_model_response = model_agg_response,
  error = realized_error
))
stopifnot(isTRUE(all.equal(realized_error, as.vector(M %*% shock))))
cat("Realized bias share:", bias_share(model, initial_group, matrix(shock, nrow=1)), "\n")

# 5. Optimize grouping of four industries into two sectors
# Seed assures reproducibility; multistart is not proof of global optimality.
fit <- optimize_aggregation(model, k = 2, mu = mu,
                            covariance = Sigma,
                            starts = list(initial_group),
                            n_random = 10, seed = 123)
cat("\n--- OPTIMIZED TWO-SECTOR GROUPING ---\n")
print(data.frame(industry = rownames(Z),
                 initial_sector = initial_group,
                 optimized_sector = fit$group))
cat("Initial RMS:", RMS, "\n")
cat("Optimized RMS:", fit$rms_bias, "\n")
cat("Bias reduction (%):", 100*(1-fit$rms_bias/RMS), "\n")
stopifnot(fit$loss <= J + 1e-9)

# 6. Aggregation frontier for 1, 2, 3, 4 sectors
# All sector counts use the same random-start budget.
frontier <- aggregation_frontier(
  model, ks = 1:4,
  mu = mu, covariance = Sigma,
  n_random = 10, seed = 123
)
cat("\n--- AGGREGATION FRONTIER ---\n")
print(frontier$table)
stopifnot(abs(frontier$table$rms_bias[frontier$table$k == 4]) < 1e-10)

plot(frontier$table$k, frontier$table$rms_bias,
     type = "b", pch = 19, lwd = 2,
     xlab = "Number of aggregate sectors (K)",
     ylab = "RMS aggregation bias (input-data units)",
     main = "aggBias: four-industry numerical example")

write.csv(frontier$table, "aggBias_example_frontier.csv", row.names = FALSE)
cat("\nDone. Results saved to aggBias_example_frontier.csv\n")
