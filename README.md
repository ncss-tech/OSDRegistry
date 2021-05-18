# OSDRegistry

[![Refresh](https://github.com/ncss-tech/OSDRegistry/workflows/refresh-osd/badge.svg)](https://github.com/ncss-tech/OSDRegistry/actions?query=workflow%3Arefresh-osd)
[![R build status](https://github.com/ncss-tech/OSDRegistry/workflows/R-CMD-check/badge.svg)](https://github.com/ncss-tech/OSDRegistry/actions?query=workflow%3AR-CMD-check)
[![Download Weekly Snapshot](https://img.shields.io/badge/Download%20Snapshot-ZIP-blueviolet)](https://github.com/ncss-tech/OSDRegistry/releases/download/main/OSD-data-snapshot.zip)

Version control repository for [Official Series Descriptions](https://soilseries.sc.egov.usda.gov/) (OSDs). 

Official "Soil Series" are detailed soil types used by the USDA-NRCS and the National Cooperative Soil Survey program. The Soil Series is the lowest level in the United States National Soil Classification System hierarchy. Series are sometimes further subdivided into phases. Series names are correlated to soil survey map unit components based on specific conditions found within soil survey areas (SSA) and Major Land Resource Areas (MLRAs).

Key differentia between series are encoded in the narrative portions of OSDs. _OSDRegistry_ provides a readily-accessible, open-source, version-controlled resource for Series concepts in OSDs. 

You can download the weekly release of a "snapshot" of all OSDs (as .txt files) [here](https://github.com/ncss-tech/OSDRegistry/releases/download/main/OSD-data-snapshot.zip). These files are parsed and stored as JSON in the [ncss-tech/SoilKnowledgeBase](https://github.com/ncss-tech/SoilKnowledgeBase) repository and can be queried using the [ncss-tech/soilDB](https://github.com/ncss-tech/soilDB) R package `get_OSD_JSON` method.

## Recommended Citation

Soil Survey Staff, Natural Resources Conservation Service, United States Department of Agriculture. Official Soil Series Descriptions. Available online. Accessed [month/day/year].
