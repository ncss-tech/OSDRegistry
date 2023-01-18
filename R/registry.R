#' Automatic update by regional queries to NASIS soil series server
#'
#' @param test Default: `FALSE`; run on a pair of small regions (MO 3, 7)
#' @param port Passed to [RSelenium::rsDriver()]. Default: `4567L`.
#' @param moID Region ID codes (Default `1:13`, or `c(3,7)` when `test=TRUE`)
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
refresh_registry <- function(test = FALSE, moID = 1:13, port = 4567L) {

  message("Setting up RSelenium...")

  if(!requireNamespace("RSelenium"))
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

  res <- try(rD <- RSelenium::rsDriver(browser = "firefox",
                                       chromever = NULL,
                                       extraCapabilities = eCaps,
                                       port = as.integer(port)))

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

  on.exit(remDr$close())

  message("Refreshing OSDs...")

  idx <- moID
  if(test == TRUE)
    idx <- c(3,7)

  # iterate over MO responsible codes 1:13
  zips <- character()
  for(i in idx) {
    res <- .query_series_by_region(remDr, i)
    if (inherits(res, 'try-error')) {
      res1 <- .query_series_by_region(remDr, i,
                                      start_year = 1800,
                                      end_year = 1980)
      res2 <- .query_series_by_region(remDr,
                                      i,
                                      start_year = 1980,
                                      end_year = format(Sys.Date(), "%Y"))
      if (!inherits(res1, 'try-error') &&
          !inherits(res2, 'try-error')) {
        res <- c(res1, res2)
      }
    }

    if (!inherits(res, 'try-error')) {
      zips <- c(zips, res)
    } else {
      message(paste0("Error querying OSDs region (", i, ")"))
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

  if (inherits(sc, 'try-error')) {
    warning('Failed to update Series Classification database via NASIS Web Report', "\n\n",
            sc[1], call. = FALSE)
  } else {
    if (!dir.exists("SC")) dir.create("SC")
    write.csv(sc, file = file.path("SC", "SCDB.csv"), row.names = FALSE)
  }

  file.remove(list.files(target_dir, "osddwn.*\\.zip$", full.names = TRUE))

  message("Done!")

  return((length(result) == 26) - 1)
}
