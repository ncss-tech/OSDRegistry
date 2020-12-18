test_that("multiplication works", {
  expect_silent(expect_true(all(unlist(osd_to_json(osd_files = list.files("OSD/A",
                                       recursive = TRUE,
                                       full.names = TRUE)[1:100])))))
})
