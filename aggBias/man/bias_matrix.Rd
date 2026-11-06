\name{bias_matrix}
\alias{bias_matrix}
\title{Bias Matrix}
\description{Shock-aware input-output aggregation using the manuscript expected squared error objective.}
\usage{bias_matrix(model, group)}
\arguments{
\item{group}{Industry group labels; columns follow sorted unique labels.}
\item{model}{An io_model result.}
}
\value{The matrix mapping detailed shocks into aggregation errors.}
\details{The method uses local search and does not guarantee a global optimum. See the project README for equations, constraints and information-rung conventions.}
