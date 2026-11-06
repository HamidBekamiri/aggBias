.finite <- function(x) is.numeric(x) && all(is.finite(x))
.integer <- function(x, minimum) length(x) == 1L && .finite(x) && x == floor(x) && x >= minimum

io_model <- function(Z, f) {
  Z <- as.matrix(Z); f <- as.vector(f)
  n <- length(f)
  if (!n || !.finite(Z) || !.finite(f) || !identical(dim(Z), c(n, n)))
    stop("Z must be a finite square matrix and f a matching numeric vector")
  x <- rowSums(Z) + f
  if (any(x <= 0)) stop("Baseline output must be positive")
  A <- sweep(Z, 2, x, "/")
  L <- solve(diag(n) - A)
  structure(list(Z=Z, f=f, x=x, A=A, L=L, n=n), class="agg_bias_io")
}

make_G <- function(group) {
  if (!length(group) || !is.null(dim(group)) || anyNA(group)) stop("Invalid group labels")
  a <- match(group, sort(unique(group)))
  G <- matrix(0, length(a), max(a)); G[cbind(seq_along(a), a)] <- 1
  G
}

aggregate_io <- function(model, group) {
  G <- make_G(group)
  if (nrow(G) != model$n) stop("group length must match industries")
  io_model(t(G) %*% model$Z %*% G, as.vector(t(G) %*% model$f))
}

bias_matrix <- function(model, group) {
  agg <- aggregate_io(model, group); G <- make_G(group)
  t(G) %*% model$L - agg$L %*% t(G)
}

expected_bias <- function(model, group, mu=NULL, covariance=NULL, weights=NULL) {
  n <- model$n
  if (is.null(mu)) mu <- numeric(n)
  if (is.null(covariance)) covariance <- diag(model$f^2, n)
  S <- as.matrix(covariance)
  if (!.finite(mu) || length(mu) != n || !.finite(S) || !identical(dim(S), c(n,n)))
    stop("Shock moments have incorrect dimensions or nonfinite values")
  if (!isTRUE(all.equal(S, t(S), tolerance=1e-8)) ||
      min(eigen(S, symmetric=TRUE, only.values=TRUE)$values) < -1e-10 * max(1, norm(S, "2")))
    stop("covariance must be symmetric positive semidefinite")
  M <- bias_matrix(model, group)
  if (!is.null(weights)) {
    if (!.finite(weights) || length(weights) != n || any(weights < 0)) stop("Invalid priority weights")
    G <- make_G(group)
    w <- vapply(seq_len(ncol(G)), function(j) max(weights[G[,j] == 1]), numeric(1))
    M <- sweep(M, 1, sqrt(w), "*")
  }
  max(0, sum((M %*% mu)^2) + sum((M %*% S) * M))
}

bias_share <- function(model, group, shocks) {
  shocks <- as.matrix(shocks)
  if (!.finite(shocks) || ncol(shocks) != model$n) stop("shocks must have draws in rows")
  truth <- shocks %*% t(model$L) %*% make_G(group)
  denom <- rowSums(abs(truth))
  result <- rowSums(abs(shocks %*% t(bias_matrix(model, group)))) / denom
  result[denom == 0] <- NA_real_
  result
}

optimize_aggregation <- function(model, k, mu=NULL, covariance=NULL,
    starts=list(), n_random=5L, seed=1L, max_pass=20L, tolerance=1e-9,
    weights=NULL, closed=list(), must_link=list(), cannot_link=list()) {
  n <- model$n
  if (!.integer(k, 1) || k > n || !.integer(n_random, 0) || !.integer(max_pass, 1) ||
      !.finite(tolerance) || length(tolerance) != 1 || tolerance < 0) stop("Invalid search settings")
  blocks <- c(closed, must_link); members <- unlist(blocks)
  indices <- c(members, unlist(cannot_link))
  if (any(lengths(blocks) == 0) || anyDuplicated(members) ||
      (length(indices) && (!.finite(indices) || any(indices != floor(indices)) || any(!indices %in% seq_len(n)))) ||
      any(lengths(cannot_link) != 2) || any(vapply(cannot_link, function(b) b[1] == b[2], logical(1))))
    stop("Invalid or overlapping constraint blocks/indices")
  p <- length(closed)
  units <- c(must_link, as.list(setdiff(seq_len(n), members)))
  groups <- setdiff(seq_len(k), seq_len(p))
  if (p > k || length(units) < length(groups) || (length(units) && !length(groups))) stop("Insufficient groups or units")
  valid <- function(a) {
    all(vapply(cannot_link, function(b) a[b[1]] != a[b[2]], logical(1))) &&
      all(vapply(blocks, function(b) length(unique(a[b])) == 1, logical(1))) &&
      all(vapply(closed, function(b) setequal(which(a == a[b[1]]), b), logical(1)))
  }
  # Restore the caller's random state, including its absence.
  had_seed <- exists(".Random.seed", envir=.GlobalEnv, inherits=FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir=.GlobalEnv)
  on.exit(if (had_seed) assign(".Random.seed", old_seed, envir=.GlobalEnv) else
    if (exists(".Random.seed", envir=.GlobalEnv, inherits=FALSE)) rm(".Random.seed", envir=.GlobalEnv))
  set.seed(seed)
  for (r in seq_len(n_random)) {
    found <- FALSE
    for (attempt in seq_len(1000)) {
      a <- integer(n)
      for (j in seq_along(closed)) a[closed[[j]]] <- j
      labels <- rep(groups, length.out=length(units))
      if (length(labels)) labels <- labels[sample.int(length(labels))]
      for (j in seq_along(units)) a[units[[j]]] <- labels[j]
      if (valid(a)) { starts[[length(starts)+1L]] <- a; found <- TRUE; break }
    }
    if (!found) stop("No feasible start in 1000 attempts; not proof of infeasibility")
  }
  if (!length(starts)) stop("Provide starts or n_random > 0")
  runs <- lapply(starts, function(a) {
    if (!.finite(a) || length(a) != n || !setequal(a, seq_len(k)) || !valid(a)) stop("Invalid starting partition")
    loss <- expected_bias(model, a, mu, covariance, weights); history <- loss
    for (pass in seq_len(max_pass)) {
      improved <- FALSE
      for (unit in units) {
        old <- a[unit[1]]
        if (sum(a == old) == length(unit)) next
        target <- old
        for (g in setdiff(groups, old)) {
          trial <- a; trial[unit] <- g
          if (!valid(trial)) next
          value <- expected_bias(model, trial, mu, covariance, weights)
          if (value < loss - tolerance) { loss <- value; target <- g }
        }
        if (target != old) { a[unit] <- target; improved <- TRUE }
      }
      history <- c(history, loss)
      if (!improved) break
    }
    list(group=a, loss=loss, converged=!improved, passes=pass, history=history)
  })
  best <- runs[[which.min(vapply(runs, function(r) r$loss, numeric(1)))]]
  list(group=best$group, loss=best$loss, rms_bias=sqrt(best$loss), runs=runs)
}

aggregation_frontier <- function(model, ks, mu=NULL, covariance=NULL, ...) {
  ks <- sort(unique(ks))
  if (!length(ks)) stop("ks cannot be empty")
  fits <- lapply(ks, function(k) optimize_aggregation(model, k, mu, covariance, ...))
  rms <- vapply(fits, function(f) f$rms_bias, numeric(1))
  previous <- rms[-length(rms)]
  gain <- c(NA_real_, ifelse(previous == 0, NA_real_, 100 * (previous-rms[-1])/previous))
  list(table=data.frame(k=ks, rms_bias=rms, best_so_far=cummin(rms), marginal_gain_pct=gain), fits=fits)
}
