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
#' @return A Zip File containing series from the selected region.
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

  ## -- STEP 2 - VIEW results (in separate window for "big" queries)
  if (inherits(osd_result2, 'try-error')) {
    # osd_result2 <- try(submit_form(osd_session, osd_request2, "download"))
    stop('This utility only works with queries that require a separate page for viewing.')
  } else {
    osd_hidden_report <- rvest::html_form(osd_result2)[[1]]$fields$hidden_report_filename
    url2 <- sprintf("https://soilseries.sc.egov.usda.gov/osdquery_view.aspx?query_file=%s&",
                    osd_hidden_report$value)
    osd_session2 <- rvest::session(url2)
    osd_query2 <- rvest::html_form(osd_session2)[[1]]
    osd_request3 <- osd_query2

    ## -- STEP 3 - DOWNLOAD
    osd_result3 <- rvest::session_submit(osd_session2, osd_request3, submit = "download")
    remDr$open()
    remDr$navigate(osd_result3$url)

    target_dir <- file.path(getwd(), 'raw')
    if (!dir.exists(target_dir))
      dir.create(target_dir, recursive = TRUE)

    # default_dir <- file.path("/home", Sys.info()[["user"]], "Downloads")
    # if (!dir.exists(default_dir))
    #   dir.create(default_dir, recursive = TRUE)

    file_name <- list.files(target_dir, "osddwn.*zip$")

    webElem <- remDr$findElement("id", "download")
    webElem$clickElement()

    orig_file_name <- file_name
    ncycle <- 0
    while(length(file_name) <= length(orig_file_name)) {
      file_name <- list.files(target_dir, "osddwn.*zip$")
      Sys.sleep(1)
      ncycle <- ncycle + 1
      if(ncycle > 240)
        break;
    }

    new_file_name <- file_name[!file_name %in% orig_file_name]
    if (length(new_file_name) > 0) {
      if(file.rename(file.path(target_dir, new_file_name),
                     file.path(target_dir, paste0(sprintf("r%s_",x), new_file_name)))) {
        message(sprintf("Downloaded: %s", new_file_name))
      } else {
        warning(sprintf("Failed to relocate file: %s", file_name))
      }
    } else {
      warning(sprintf("Problem with OSD Download for Region %s", x))
    }
  }

  remDr$close()
  return(0)
}
