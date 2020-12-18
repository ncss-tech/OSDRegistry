test_that("Two region test works", {
 test_download <- FALSE
 skip_if_not(test_download)
 expect_equal(refresh_registry(test = TRUE), 0)
})
