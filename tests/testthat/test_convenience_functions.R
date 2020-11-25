test_that(
  "Convenience functions"
  , {
    expect_identical(
      add_lua_filter(filter_name = "wordcount", error = FALSE)
      , add_wordcount_filter(error = FALSE)
    )

    expect_identical(
      add_lua_filter(filter_name = "replace_ampersands", error = FALSE)
      , add_replace_ampersands_filter(error = FALSE)
    )

    skip_on_cran()


    if(rmarkdown::pandoc_version() >= "2.11") {
      filter_args <- "--citeproc"
    } else {
      citeproc_path <- utils::getFromNamespace("pandoc_citeproc", "rmarkdown")
      filter_args <- c("--filter", citeproc_path())
    }

    expect_identical(
      add_citeproc_filter(NULL, error = FALSE)
      , filter_args
    )
  }
)
