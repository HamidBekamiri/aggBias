\name{io_model}
\alias{io_model}
\title{Io Model}
\description{Shock-aware input-output aggregation using the manuscript expected squared error objective.}
\usage{io_model(Z, f)}
\arguments{
\item{Z}{Square intermediate-flow matrix; supplier industries in rows.}
\item{f}{Baseline final-demand vector.}
}
\value{A list containing Z, f, x, A, L and n.}
\details{The method uses local search and does not guarantee a global optimum. See the project README for equations, constraints and information-rung conventions.}
