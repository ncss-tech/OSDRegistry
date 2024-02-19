#' Regional Soil Series Data Download
#'
#' @description Download ZIP files containing multiple (>1000) Official Series Descriptions (OSDs) into local Downloads folder. Files matching "osddwn.*zip$" are moved to the package raw directory. The function will wait up to 2 minutes for the server to complete the ZIP file result, but will complete as soon as the result is detected.
#'
#' @param remDr RSelenium Client
#' @param x A value
#' @param start_year Optional: Start of target "origin" year interval
#' @param end_year Optional: End of target "origin" year interval
#'
#' @details Need to maintain a single session throughout a sequence of horrid ASPX form steps. Individual sessions maintained via __VIEWSTATE, __EVENTVALIDATION and other "secret" fields.
#'
#' @return Path to a Zip File containing series from the selected region.
#' @author Andrew G. Brown
#'
#' @importFrom rvest session html_form session_submit html_form_set
#' @importFrom RSelenium rsDriver
.query_series_by_region <- function(remDr, x, start_year = NULL, end_year = NULL) {

  ## -- STEP 1 - SUBMIT query
  url1 <- "https://soilseries.sc.egov.usda.gov/osdquery.aspx"
  osd_session <- rvest::session(url1)
  osd_query <- rvest::html_form(osd_session)[[1]]

  # modify request
  osd_request1 <- rvest::html_form_set(
      osd_query,
      ddl_resp_mo = as.character(x),
      estab_year1 = as.character(start_year),
      estab_year2 = as.character(end_year)
    )

  osd_result1 <- rvest::session_submit(osd_session, osd_request1, "submit_query")
  Sys.sleep(0.5)

  osd_request2 <- rvest::html_form(osd_result1)[[1]]
  osd_result2 <- try(rvest::session_submit(osd_session, osd_request2, "view"))
  Sys.sleep(0.5)

  ## Create download directories
  # ideally we would be able to use RSelenium and browser options to go right to /raw
  target_dir <- file.path(getwd(), 'raw')
  if (!dir.exists(target_dir))
    dir.create(target_dir, recursive = TRUE)

  # but it may download to the default path (user Downloads folder)
  default_dir <- file.path(path.expand('~'), "Downloads")
  # if (!dir.exists(default_dir))
  #   dir.create(default_dir, recursive = TRUE)

  ## -- STEP 2 - VIEW results (in separate window for "big" queries)
  if (inherits(osd_result2, 'try-error')) {
    # osd_result2 <- try(submit_form(osd_session, osd_request2, "download"))
    message('This utility only works with queries that require a separate page for viewing. Skipping region: ', x)
    return(NA_character_)
  } else {
    osd_hidden_report <- rvest::html_form(osd_result2)[[1]]$fields$hidden_report_filename
    url2 <- sprintf("https://soilseries.sc.egov.usda.gov/osdquery_view.aspx?query_file=%s&",
                    osd_hidden_report$value)
    osd_session2 <- rvest::session(url2)
    osd_query2 <- rvest::html_form(osd_session2)[[1]]
    osd_request3 <- osd_query2

    ## -- STEP 3 - DOWNLOAD
    osd_result3 <- rvest::session_submit(osd_session2, osd_request3, submit = "download")
    remDr$navigate(osd_result3$url)

    file_name <- list.files(target_dir, "osddwn.*zip$")
    dfile_name <- list.files(default_dir, "osddwn.*zip$")

    webElem <- remDr$findElement("id", "download")
    webElem$clickElement()

    # keep track of files originally in target download folders
    orig_file_name <- file_name
    orig_dfile_name <- dfile_name
    ncycle <- 0

    # wait for downloaded file to appear in browser download directory
    while (length(file_name) <= length(orig_file_name) &
           length(dfile_name) <= length(orig_dfile_name)) {
      file_name <- list.files(target_dir, "osddwn.*zip$")
      dfile_name <- list.files(default_dir, "osddwn.*zip$")
      Sys.sleep(1)
      ncycle <- ncycle + 1
      if (ncycle > 480)
        break
    }

    new_file_name <- character(0)

    # allow download to default directory, just move to target first
    new_dfile_name <- dfile_name[!dfile_name %in% orig_dfile_name]

    # if (length(new_dfile_name) > 0) {
    #   new_file_name <- new_dfile_name
    #   target_file_name <- file.path(target_dir, paste0(sprintf("r%s_", x), new_file_name))
    #   if (!file.copy(file.path(default_dir, new_dfile_name), target_dir, recursive = TRUE)) {
    #     warning(sprintf("Failed to relocate file: %s", new_file_name))
    #   }
    #   # file.remove(file.path(default_dir, new_dfile_name))
    # } else {
    #   new_file_name <- file_name[!file_name %in% orig_file_name]
    #   target_file_name <- file.path(target_dir, paste0(sprintf("r%s_", x), new_file_name))
    #   if (!file.rename(file.path(target_dir, new_file_name), target_file_name)) {
    #     warning(sprintf("Failed to relocate file: %s", new_file_name))
    #   }
    # }

    if (length(new_dfile_name) > 0 && file.exists(file.path(default_dir, new_dfile_name))) {
      message(sprintf("Downloaded: %s", new_dfile_name))
    } else {
      return(try(stop(sprintf("Problem with OSD Download for Region %s", x), call. = FALSE)))
    }
    file.path(default_dir, new_dfile_name)
  }

}
