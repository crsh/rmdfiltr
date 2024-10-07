#' Replace DOI citations in R Markdown document
#'
#' This function reads an R Markdown document and replaces all DOI citations
#' with the corresponding entries from a BibTeX file. Requires the package
#' `bibtex` to be installed.
#'
#' @param rmd A character vector specifying the path to the R Markdown file
#'   (UTF-8 encoding expected).
#' @param bib A character vector specifying the path to the BibTeX file
#'   (UTF-8 encoding expected).
#' @return Returns `TRUE` invisibly.
#' @examples
#' dontrun({
#' replace_doi_citations("myreport.Rmd")
#' })
#' @export

replace_doi_citations <- function(rmd, bib = NULL) {
  if(!require("bibtex", quietly = TRUE)) {
    stop("The package `bibtex` is not avialable but required to replace DOI citations in a source document. Please install the package and try again.")
  }
  if(!require("stringr", quietly = TRUE)) {
    stop("The package `stringr` is not avialable but required to replace DOI citations in a source document. Please install the package and try again.")
  }

  if(is.null(bib)) {
    return(invisible(FALSE))
  }

  entries <- lapply(bib, bibtex::read.bib) |>
    do.call("c", args = _) |>
    (\(x) x$doi)()

  entries <- entries[!is.na(entries) & !duplicated(entries)]

  rmd <- gsub("\\.knit\\.md$", ".Rmd", rmd)
  if(!file.exists(rmd)) {
    rmd <- gsub("Rmd$", "rmd", rmd)
    if(!file.exists(rmd)) stop("Cannot locate source file at", rmd, "or", gsub("rmd$", "Rmd", rmd), ".")
  }

  stringr::str_replace_all(
    readLines_utf8(con = rmd)
    , setNames(
      paste0("@", names(entries))
      , paste0("@(doi:|DOI:|(https://)*doi.org/)*", entries)
    )
  ) |>
    writeLines(con = rmd, useBytes = TRUE)

  invisible(TRUE)
}

#' @keywords internal

readLines_utf8 <- function(con) {
  if(is.character(con)) {
    con <- file(con, encoding = "utf8")
    on.exit(close(con))
  } else if(inherits(con, "connection")) {
    stop("If you want to use an already existing connection, you should use readLines(), directly.")
  }
  y <- try(readLines(con, encoding = "bytes"))
  if(inherits(y, "try-error")) stop("Reading from file ", encodeString(summary(con)$description, quote = "'"), " failed.")
  y
}

#' @keywords internal

writeLines_utf8 <- function(x, con) {
  if(is.character(con)) {
    con <- file(con, encoding = "utf8")
    on.exit(close(con))
  } else if(inherits(con, "connection")) {
    stop("If you want to use an already existing connection, you should use readLines(), directly.")
  }
  y <- try(writeLines(x, con, useBytes = TRUE))
  if(inherits(y, "try-error")) stop("Reading from file ", encodeString(summary(con)$description, quote = "'"), " failed.")
  y
}
