#' Automatic update by regional queries to NASIS soil series server
#'
#' @param test Default: `FALSE`; run on a pair of small regions (MO 12, 13)
#' @param port Passed to [RSelenium::rsDriver()]. Default: `4567L`.
#' @param moID Region ID codes; see default argument value in function definition for details
#' @param home_dir Default: `path.expand("~")`. Used to find "Downloads" directory on some platforms depending on browser configuration.
#'
#' @description Text files are written to alphabetical (first letter) folders containing raw Official Series Descriptions (OSDs). This method is for use in automatic pipeline (e.g. a GitHub action) to regularly replicate changes that occur across the entire set of series for commit.
#'
#' There is an assumption that the files are downloaded to a Linux-like default \code{"Downloads"} folder \code{"~/Downloads"} or \code{"/home/user/Downloads"} which are standard on \code{"ubuntu-latest"} where these actions are typically run. The files matching the path \code{"osddwn.*zip$"} get moved to the repository "raw" folder.
#'
#' @return \code{0} if function completes.
#'
#' @details Thank goodness we don't need to read .doc files... the server delivers .txt masquerading as .doc. Queries that error are re-tried after splitting in half (established year before or after 1980).
#'
#' @export
#'
#' @author Andrew G. Brown
#'
#' @examples
#'
#' ## note: takes several minutes to run and downloads ~100MB .ZIP data
#' # refresh_registry()
#'
#' @importFrom utils unzip write.csv
#' @importFrom RSelenium rsDriver makeFirefoxProfile
refresh_registry <- function(
    test = FALSE,
    moID = c(
      `Alaska` = 36871,
      `North Central` = 117,
      `Northeast` = 153,
      `Northwest` = 134,
      `South Central` = 127,
      `Southeast` = 122,
      `Southwest` = 113,
      `Special Projects` = 44372
    ),
    port = 4567L,
    home_dir = path.expand("~")
) {

  message("Setting up RSelenium...")

  if (!requireNamespace("RSelenium"))
    stop("package `RSelenium` is required to download ZIP files")

  target_dir <- file.path(path.expand("~"), "Downloads") # file.path(getwd(), 'raw')

  if (!dir.exists(target_dir))
    dir.create(target_dir, recursive = TRUE)

  #2022-01-16- use firefox
  fprof <- RSelenium::makeFirefoxProfile(list(browser.download.dir = target_dir,
                                              browser.download.folderList = 2))
  eCaps <- list(
    firefox_profile = fprof$firefox_profile,
    "moz:firefoxOptions" = list(args = list('--headless'))
  )

  res <- try({
    rD <- RSelenium::rsDriver(
      browser = "firefox",
      chromever = NULL, 
      phantomver = NULL,
      extraCapabilities = eCaps,
      port = as.integer(port)
    )
  })

  ## chrome driver setup
  # eCaps <- list(chromeOptions =
  #                 list(
  #                   prefs = list(
  #                     "profile.default_content_settings.popups" = 0L,
  #                     "download.prompt_for_download" = FALSE,
  #                     "directory_upgrade" = TRUE,
  #                     "download.default_directory" = target_dir
  #                   ),
  #                   args = c('--headless')
  #                 ))
  # gcv <- trimws(gsub("Google Chrome ","\\1",
  #                    system("google-chrome --version", intern = TRUE)))
  # if(inherits(res, 'try-error')) {
  #   gcv.split <- strsplit(gsub("\\n", "",
  #                              gsub(".* = (.*)", "\\1",
  #                                   as.character(res))), ",")[[1]]
  #
  #   # selenium may not be available for patch versions corresponding to an available version
  #
  #   # get the latest chrome version without going newer
  #   idx.cv <- which.max(cumsum(gcv.split <= gcv))
  #   cv <- gcv.split[idx.cv]
  #   message(paste0("Using google-chrome ", cv, "..."))
  #   res <- try(rD <- RSelenium::rsDriver(browser = "chrome",
  #                                        chromever = cv,
  #                                        geckover = NULL,
  #                                        extraCapabilities = eCaps))
  #
  #   if(inherits(res, 'try-error'))
  #     stop("Cannot get latest Selenium driver")
  # }

  remDr <- rD[["client"]]
  remDr$open()
  on.exit(remDr$close())

  message("Refreshing OSDs...")

  idx <- moID

  # test with AK + Special Projects
  if (isTRUE(test))
    idx <- c(36871, 44372)

  # iterate over MO responsible codes
  zips <- character()
  for (i in idx) {
    a_region <- names(idx)[which(idx == i)]
    message("Downloading ", a_region, " OSDs...")
    # SWR and NWR have by far the most series, dont bother trying to do in one shot
    if (!i %in% c(113, 134)) {
      res <- try(.query_series_by_region(remDr, i, home_dir = home_dir))

      # try up to additional times
      if (inherits(res, 'try-error')) {
        res <- try(.query_series_by_region(remDr, i, home_dir = home_dir))
      }
    }

    if (i %in% c(113, 134) || inherits(res, 'try-error')) {
      # partition into chunks of established years
      message("\t - Fetching 1800 to 1975...")
      res1 <- try(.query_series_by_region(remDr, i, home_dir = home_dir,
                                          start_year = 1800,
                                          end_year = 1975))
      message("\t - Fetching 1976 to 1990...")
      res2 <- try(.query_series_by_region(remDr, i, home_dir = home_dir,
                                          start_year = 1976,
                                          end_year = 1990))
      message("\t - Fetching 1991 to 2005...")
      res3 <- try(.query_series_by_region(remDr, i, home_dir = home_dir,
                                          start_year = 1991,
                                          end_year = 2005))
      message("\t - Fetching 2006 to current year...")
      res4 <- try(.query_series_by_region(remDr, i, home_dir = home_dir,
                                          start_year = 2006,
                                          end_year = format(Sys.Date(), "%Y")))
      
      # TODO: why does above cause 500 error? no established series in current year? 
      if (inherits(res4, 'try-error')) {
        message("\t - Fetching up to current year minus 1...")
        res4 <- try(.query_series_by_region(remDr, i,
                                            start_year = 2006,
                                            end_year = as.numeric(format(Sys.Date(), "%Y")) - 1))

      }

      if (!inherits(res1, 'try-error') &&
          !inherits(res2, 'try-error') &&
          !inherits(res3, 'try-error') &&
          !inherits(res4, 'try-error')) {
        res <- c(res1, res2, res3, res4)
      } else {
        res <- try(stop("splitting region " , a_region, " by year failed"))
      }
    }

    if (!inherits(res, 'try-error')) {
      if (all(!is.na(res)))
        zips <- c(zips, res)
    } else {
      message(paste0("Error querying OSDs region (", a_region, ")"))
    }
  }

  # unzip to single directory of .doc files
  lapply(zips, unzip, exdir = "raw/doc")

  # read .doc files
  docfiles <-  list.files("raw/doc", "doc$", recursive = TRUE)
  docletters <- toupper(substr(basename(docfiles), 0, 1))
  osds <- file.path("raw/doc", docfiles)
  osdlist <- split(unlist(osds), docletters)

  # create OSD/A, OSD/B, OSD/C, ...
  lapply(file.path("OSD", LETTERS), function(x) {
     if (!dir.exists(x))
       dir.create(x, recursive = TRUE)
    })

  # create .txt
  result <- lapply(1:length(LETTERS), function(i) {
      lapply(osdlist[[LETTERS[i]]], function(f) {
          suppressWarnings({
            nupath <- file.path("OSD", LETTERS[i], gsub("\\.doc", "\\.txt", basename(f)))
            write(readLines(f), nupath)
          })
        })
    })

  message("Refreshing SC database...")

  sc <- .download_NASIS_SC_webreport()

  if (inherits(sc, 'try-error') ||
      !inherits(sc, 'data.frame') ||
      nchar(as.character(sc[1])) == 0) {
    warning('Failed to update Series Classification database via NASIS Web Report', "\n\n",
            sc[1], call. = FALSE)
  } else {
    if (!dir.exists("SC"))
      dir.create("SC")
    if (nrow(sc) > 0) {
      write.csv(sc, file = file.path("SC", "SCDB.csv"), row.names = FALSE)
    }
  }

  file.remove(list.files(target_dir, "osddwn.*\\.zip$", full.names = TRUE))

  message("Done!")

  return((length(result) == 26) - 1)
}
