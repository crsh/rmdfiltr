#' Replace DOI citations in R Markdown document
#'
#' This function reads an R Markdown document and replaces all DOI citations
#' with the corresponding entries from a BibTeX file. Requires the package
#' `bibtex` to be installed.
#'
#' @param input_file Character. Path to the input file provided to the post-processor.
#' @param bib Character. A (vector of) path(s) to the BibTeX file(s).
#' @return Returns `TRUE` invisibly.
#' @export

post_process_doi_citations <- function(input_file, bib) {
  if(!requireNamespace("bibtex", quietly = TRUE)) {
    stop("The package `bibtex` is not avialable but required to replace DOI citations in a source document. Please install the package and try again.")
  }
  if(!requireNamespace("stringr", quietly = TRUE)) {
    stop("The package `stringr` is not avialable but required to replace DOI citations in a source document. Please install the package and try again.")
  }

  if(is.null(bib)) {
    return(invisible(FALSE))
  }

  # Ensure valid bib files
  existant_bib <- sapply(bib, file.exists)
  
  if(!any(existant_bib)) {
    stop(
      "None of the specified BibTeX files exists:\n"
      , paste(bib, sep = "\n")
    )
  }

  if(!all(existant_bib)) {
    warning(
      "The following specified BibTeX files do not exist:\n"
      , paste(bib[!existant_bib], sep = "\n")
    )
  }

  empty_bib <- sapply(bib[existant_bib], file.size) == 0

  # Process bib files
  entries <- lapply(bib[existant_bib & !empty_bib], bibtex::read.bib) |>
    do.call("c", args = _) |>
    (\(x) stats::setNames(x$doi, names(x)))()

  entries <- entries[!is.na(entries) & !duplicated(entries)]

  rmd <- gsub("\\.knit\\.md$", ".Rmd", input_file)
  if(!file.exists(rmd)) {
    rmd <- gsub("Rmd$", "rmd", rmd)
    if(!file.exists(rmd)) stop("Cannot locate source file at", rmd, "or", gsub("rmd$", "Rmd", rmd), ".")
  }

  stringr::str_replace_all(
    readLines_utf8(con = rmd)
    , stats::setNames(
      paste0("@", names(entries))
      , paste0("@(doi:|DOI:|(https://)*doi.org/)*((", toupper(entries), ")|(", tolower(entries), "))")
    )
  ) |>
    writeLines(con = rmd, useBytes = TRUE)

  invisible(TRUE)
}

#' @rdname post_process_doi_citations
#' @export

replace_resolved_doi_citations <- function() {
  rmd <- knitr::current_input()
  bib <- rmarkdown::metadata$bibliography
  if(file.exists(bib)) {
    rmdfiltr::post_process_doi_citations(rmd, bib)
  }
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
