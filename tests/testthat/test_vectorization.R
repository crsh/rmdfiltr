test_that(
  "Vectorization"
  , {
    expect_identical(
      add_lua_filter(filter_name = c("replace_ampersands", "wordcount"))
      , c(add_replace_ampersands_filter(), add_wordcount_filter())
    )
  }
)