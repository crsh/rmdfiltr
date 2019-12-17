
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rmdfiltr

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![Travis build
status](https://travis-ci.org/crsh/rmdfiltr.svg?branch=master)](https://travis-ci.org/crsh/rmdfiltr)
[![CRAN
status](https://www.r-pkg.org/badges/version/rmdfiltr)](https://cran.r-project.org/package=rmdfiltr)
\[![CRAN
downloads](https://cranlogs.r-pkg.org/badges/last-month/rmdfiltr)
<!-- badges: end -->

`rmdfiltr` provides a collection of
[Lua-filters](https://pandoc.org/lua-filters.html) that extend the
functionality of R Markdown templates.

## Installation

<!--
You can install the released version of rmdfiltr from [CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("rmdfiltr")
```
-->

You can install the development version from this GitHub repository
with:

``` r
# install.packages("remotes")
remotes::install_github("crsh/rmdfiltr")
```

## Example

You can add a filter to any R Markdown template that accepts additional
`pandoc` arguments.

``` yaml
---
title: "Word count test"
output:
  html_document:
    pandoc_args: !expr rmdfiltr::add_wordcount_filter()
---
```

Of course, you can also use the filters in a custom R Markdown format by
adding `pandoc` arguments with the preprocessor function.

``` r
wordcount_html_document = function(...) {
  format <- rmarkdown::html_document(...)
  format$pre_processor <- rmdfiltr::add_wordcount_filter
  format
}
```

See [R Markdown: The Definitive
Guide](https://bookdown.org/yihui/rmarkdown/new-formats.html) for
details on how to create custom formats.

# Contributions

Contributions of new filters are welcome. Pleas refer to the
[contributing
guidelines](https://github.com/crsh/rmdfiltr/blob/master/.github/CONTRIBUTING.md)
before you start working or open a pull request. Also, please note that
the `rmdfiltr` project is released with a [Contributor Code of
Conduct](https://github.com/crsh/rmdfiltr/blob/master/.github/CODE_OF_CONDUCT.md).
By contributing to this project, you agree to abide by its terms.
