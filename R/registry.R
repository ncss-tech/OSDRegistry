#' Refresh the repository/package data by automating regional queries to soil series server
#' @description Thank goodness we don't need to read .doc files... the server delivers .txt masquerading as .doc.
#' @return Text files written to alphabetical folders containing raw Official Series Description (OSD) text. For use in automatic pipeline to regularly commit changes across the entire set of OSDs.
#' @export
#' @importFrom utils unzip
refresh_registry <- function() {
  
  # message("Downloading data...")
  
  # TODO: download ZIPs (pain in the butt; automate ASPX form submission by region?)
  message("Refreshing OSDs...")
  
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
