library(aggBias)
Z <- matrix(c(10,2,1,0,3,12,2,1,1,3,8,2,0,1,2,6),4,byrow=TRUE)
f <- c(20,25,15,10); m <- io_model(Z,f); g <- c(1,1,2,2)
G <- make_G(g); Za <- t(G)%*%Z%*%G; fa <- as.vector(t(G)%*%f)
La <- solve(diag(2)-sweep(Za,2,rowSums(Za)+fa,"/"))
M <- t(G)%*%m$L-La%*%t(G); mu <- c(1,2,-1,0); S <- diag(c(2,1,3,1))
reference <- sum((M%*%mu)^2)+sum((M%*%S)*M)
stopifnot(abs(expected_bias(m,g,mu,S)-reference)<1e-13,
          abs(reference-0.057755803080969614)<1e-12,
          max(abs(bias_matrix(m,1:4)))<1e-14,
          max(abs(aggregate_io(m,g)$x-as.vector(t(G)%*%m$x)))<1e-12,
          is.na(bias_share(m,g,matrix(0,1,4))))
fit <- optimize_aggregation(m,2,n_random=4,closed=list(1),must_link=list(c(2,3)))
stopifnot(fit$group[1]!=fit$group[2],fit$group[2]==fit$group[3])
for (run in fit$runs) stopifnot(all(diff(run$history)<=0),length(unique(run$group))==2)
a <- optimize_aggregation(m,2,cannot_link=list(c(1,2)))
b <- optimize_aggregation(m,2,cannot_link=list(c(1,2)))
stopifnot(identical(a$group,b$group),a$group[1]!=a$group[2])
stopifnot(nrow(aggregation_frontier(m,c(1,2,4),n_random=2)$table)==3)
stopifnot(inherits(try(expected_bias(m,g,covariance=-diag(4)),silent=TRUE),"try-error"))
