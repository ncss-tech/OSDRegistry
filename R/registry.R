#' Automatic update by regional queries to NASIS soil series server
#' 
#' @description Text files are written to alphabetical (first letter) folders containing raw Official Series Descriptions (OSDs). This method is for use in automatic pipeline (e.g. a GitHub action) to regularly replicate changes that occur across the entire set of series for commit.
#' 
#' There is an assumption that the files are downloaded to a Linux-like default \code{"Downloads"} folder \code{"~/Downloads"} or \code{"/home/user/Downloads"} which are standard on \code{"ubuntu-latest"} where these actions are typically run. The files matching the path \code{"osddwn.*zip$"} get moved to the repository "raw" folder.
#' 
#' @return \code{0} if function completes.
#' @details Thank goodness we don't need to read .doc files... the server delivers .txt masquerading as .doc. Queries that error are re-tried after splitting in half (established year before or after 1980).
#' 
#' @export
#' 
#' @author Andrew G. Brown
#' 
#' @examples 
#' 
#' # refresh_registry()
#' 
#' @importFrom utils unzip
#' @importFrom RSelenium rsDriver
refresh_registry <- function() {
  
  message("Refreshing OSDs...")
  
  if(!requireNamespace("RSelenium"))
    stop("package `RSelenium` is required to download ZIP files")
  
  rD <- RSelenium::rsDriver()
  remDr <- rD[["client"]]
  # this relies on MO responsible codes 1:12
  for(i in 1:12) {
    res <- .query_series_by_region(remDr, i)
    if(inherits(res, 'try-error')) {
      try(.query_series_by_region(remDr, i, start_year = 1800, end_year = 1980))
      try(.query_series_by_region(remDr, i, start_year = 1980, end_year = format(Sys.Date(),"%Y")))
    }
  }
  
  # unzip to single directory of .doc files
  lapply(file.path("raw", 
                   list.files("raw", "zip", 
                              recursive = TRUE, 
                              ignore.case = TRUE)), 
         unzip, exdir = "raw/doc")
  
  # read .doc files
  docfiles <-  list.files("raw/doc", "doc$", recursive = TRUE)
  docletters <- toupper(substr(basename(docfiles), 0, 1))
  
  osds <- file.path("raw/doc", docfiles)
  
  osdlist <- split(unlist(osds), docletters)
  
  lapply(file.path("OSD", LETTERS), function(x) if (!dir.exists(x)) dir.create(x, recursive = TRUE))
  
  result <- lapply(1:length(LETTERS), function(i) {
      lapply(osdlist[[LETTERS[i]]], function(f) {
          suppressWarnings({
            write(readLines(f), 
                  file.path("OSD", 
                            LETTERS[i], 
                            gsub("\\.doc", 
                                 "\\.txt", 
                                 basename(f))))
          })
        })
    })
  
  message("Done!")
  
  return((length(result) == 26) - 1)
}
