# SC database
 
#' Download latest Series Classification (SC) Database via NASIS Web Report
#' Uses `soilDB::get_soilseries_from_NASISWebReport(soils = "%")`
#' @return a data.frame containing columns: "soilseriesname", "soilseriesstatus", "benchmarksoilflag", "statsgoflag", "mlraoffice", "areasymbol", "areatypename", "taxclname", "taxorder", "taxsuborder", "taxgrtgroup", "taxsubgrp", "taxpartsize", "taxpartsizemod", "taxminalogy", "taxceactcl", "taxreaction", "taxtempcl", "originyear", "establishedyear", "soiltaxclasslastupdated", "soilseriesiid", "areasymbol", "areaname", "areatypename"
#' @importFrom soilDB get_soilseries_from_NASISWebReport
#' @importFrom curl curl new_handle
#' @importFrom xml2 read_html
#' @importFrom rvest html_table
#' @noRd
#' @keywords internal
.download_NASIS_SC_webreport <- function() {
  try(soilDB::get_soilseries_from_NASISWebReport(soils = "%"))
}
