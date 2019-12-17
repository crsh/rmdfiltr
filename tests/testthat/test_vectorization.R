test_that(
  "Vectorization"
  , {
    expect_identical(
      add_lua_filter(filter_name = c("replace_ampersands", "wordcount"), error = FALSE)
      , c(add_replace_ampersands_filter(error = FALSE), add_wordcount_filter(error = FALSE))
    )

    expect_identical(
      add_custom_filter(filter_path = c("foo/bar", "bar/foo"), lua = c(TRUE, FALSE), error = FALSE)
      , c("--lua-filter", "foo/bar", "--filter", "bar/foo")
    )

    expect_identical(
      add_custom_filter(filter_path = c("foo/bar", "bar/foo"), lua = TRUE, error = FALSE)
      , c("--lua-filter", "foo/bar", "--lua-filter", "bar/foo")
    )
  }
)
