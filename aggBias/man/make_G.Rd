\name{make_G}
\alias{make_G}
\title{Make G}
\description{Shock-aware input-output aggregation using the manuscript expected squared error objective.}
\usage{make_G(group)}
\arguments{
\item{group}{Industry group labels; columns follow sorted unique labels.}
}
\value{A binary membership matrix.}
\details{The method uses local search and does not guarantee a global optimum. See the project README for equations, constraints and information-rung conventions.}
