#' Add Lua filter to pandoc arguments
#'
#' Adds a Lua filter supplied by \pkg{rmdfiltr} to the vector of pandoc command
#' line arguments.
#'
#' @param args Character. (Vector of) pandoc command line arguments.
#' @param filter_name Character. Name of the Lua filter to add. See details.
#' @inheritParams verify_pandoc_version
#'
#' @details The following Lua filters are available. Convenience functions named
#'   after the filter are available (e.g. \code{add_*_filter()}).
#'
#' \describe{
#'   \item{\code{citeproc}}{Resolves and formats citations using a bibliography
#'      file and a CSL stylesheet via \code{pandoc-citeproc}. This filter is
#'      usually applied automatically in R Markdown, but specifying it manually
#'      grants control over the order with which filters are applied. Be sure to
#'      set \code{citeproc: no} in the YAML front matter of the document.
#'      Otherwise \code{pandoc-citeproc} is applied twice.}
#'   \item{\code{replace_ampersands}}{Searches for citations added by
#'     \code{pandoc-citeproc} and replaces \code{&} with \code{and} in all
#'     in-text citations (e.g., as required by APA style). If \code{lang} is
#'     specified in the documents YAML front matter, the corresponding
#'     translation is used, if available. Be sure to set \code{citeproc: no} in
#'     the YAML front matter of the document and call \code{pandoc-citeproc}
#'     manually (e.g., using \code{add_citeproc_filter}).}
#'   \item{\code{wordcount}}{The body of the text and reference sections are
#'     counted separately. The word count for the text body does not contain,
#'     tables or images (or their captions). The filter reports the word count in
#'     the console or the R Markdown tab in 'RStudio'.}
#' }
#'
#' @export
#'
#' @examples
#'
#' add_lua_filter(NULL, "wordcount")

add_lua_filter <- function(args = NULL, filter_name, report = "error") {
  if(!is.null(args)) assertthat::assert_that(is.character(args))
  assertthat::assert_that(is.character(filter_name))

  if(verify_pandoc_version(report = report)) {
    for(i in filter_name) {
      if(i == "citeproc") {
        citeproc_path <- utils::getFromNamespace("pandoc_citeproc", "rmarkdown")
        filter_path <- citeproc_path()
        args <- c(args, "--filter", filter_path)
      } else {
        filter_path <- system.file(paste0(i, ".lua"), package = "rmdfiltr")
        args <- c(args, "--lua-filter", filter_path)
      }


    }
  }

  args
}

#' @rdname add_lua_filter
#' @export
#' @examples
#' add_wordcount_filter(NULL)

add_wordcount_filter <- function(args = NULL, report = "error") {
  add_lua_filter(args, "wordcount", report = report)
}

#' @rdname add_lua_filter
#' @export
#' @examples
#' add_replace_ampersands_filter(NULL)

add_citeproc_filter <- function(args = NULL, report = "error") {
  add_lua_filter(args, "citeproc", report = report)
}

#' @rdname add_lua_filter
#' @export
#' @examples
#' add_replace_ampersands_filter(NULL)

add_replace_ampersands_filter <- function(args = NULL, report = "error") {
  add_lua_filter(args, "replace_ampersands", report = report)
}
