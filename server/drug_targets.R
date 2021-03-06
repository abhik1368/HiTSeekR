# compoundSelectedHitList <- reactive({
#   if(input$drugUseConsensus == "hit list") data <- outliers()
#   else data <- consensusHitList()
#   return(data)
# })

convertToCid <- function(data, type){
  if(type == "PubChem_CID"){
    data$PubChem_CID <- data$Accession
    return(data)
  }
  
  compound.mapping.db <- src_sqlite(paste(data.folder, "compound.mapping.sqlite3", sep=""))
  
  if(type == "Chembank")
  {
      compound.mapping <- tbl(compound.mapping.db, "chembank_to_cid")
      result <- filter(compound.mapping, Chembank_ID %in% data$Accession)
      result <- as.data.frame(result) %>% filter(complete.cases(.))
      result <- left_join(data, result, by=c("Accession" = "ChemBank_ID"))
      return(result)
  }
  else if(type == "PubChem_SID")
  {
      compound.mapping <- tbl(compound.mapping.db, "chembank_to_sid_cid")
      result <- filter(compound.mapping, PubChem_SID %in% data$Accession)
      result <- as.data.frame(result) %>% filter(complete.cases(.)) %>% select(-ChemBank_ID)
      result <- left_join(data, result, by=c("Accession" = "PubChem_SID"))    
      return(result)
  }
  
  stop("Do not know how to handle unknown compound / drug ID type.")
}

stitch.db <- src_sqlite(paste(data.folder, "stitch_hsa_protein_chemical_links_v4.0.sqlite3", sep=""))

drug.targets <- reactive({
  
  hits <- outliers()

  #convert ids to pubchem compound ids (CID) as used in STITCH
  hits <- convertToCid(hits, input$accessionColType)
  
  #add CID prefix and leading zeros for STITCH db
  hits[!is.na(hits$PubChem_CID), "PubChem_CID"] <- paste("CID", formatC(as.integer(hits[!is.na(hits$PubChem_CID), "PubChem_CID"]), width=9, flag="0"), sep="")
  
  tryCatch({
    hits.wo.nas <- na.omit(hits$PubChem_CID)
    targets <- tbl(stitch.db, "hs")
    targets <- filter(targets, PubChemID %in% hits.wo.nas)
    hits <- hits %>% dplyr::select(Sample, PubChem_CID) 
    hits <- inner_join(hits, targets, by=c("PubChem_CID" = "PubChemID"), copy=T)
  }, error = function(e){ showshinyalert(session, "general_status", paste("error:", e$message), "danger") })
  
  if(nrow(hits) == 0) stop("No target has been found.")
  
  return(hits)
})

drug.target.genes <- reactive({
  tryCatch({    
    targets <- tbl(stitch.db, "hs")
    return(as.data.frame(distinct(dplyr::select(targets, gene_id)))[-1,1])
  }, error = function(e){ showshinyalert(session, "general_status", paste("error:", e$message), "danger") })
  
  if(nrow(hits) == 0) stop("Problem encountered when extracting putative drug target genes.")
  
  return(hits)    
})

#indicator_matrix 
drug.indicator.matrix <- reactive({
  dr.targets <- drug.targets()  
  indicator.matrix <- as.data.frame.matrix(table(dr.targets[,c("gene_id", "PubChem_CID")]))
  indicator.matrix[indicator.matrix > 1] <- 1
  return(indicator.matrix)  
})
