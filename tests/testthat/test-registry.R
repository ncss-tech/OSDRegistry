test_that("Two region test works", {
 test_download <- (length(list.files('OSD', "txt", recursive = TRUE)) > 0)
 skip_if_not(test_download)
 expect_equal(refresh_registry(test = TRUE), 0)
})
