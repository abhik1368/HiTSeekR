output$uiOutput_mirna_targets <- renderUI({
  if(is.null(input$screenType) && input$screenType != "miRNA"){
    stop("miRNA target prediction is only available for miRNA inhibitor / mimics screens")
  }
  
  elements <- list(
    tabPanel("miRNA target genes",  
             sidebarPanel(
               selectInput("useConsensus", "Use hit list or consensus hit list for target identification?", c("hit list", "consensus hit list")),                    
               selectInput("selectedTargetDBs", "currently selected:", c(dbListTables(RmiR.Hs.miRNA_dbconn()), "RNAhybrid_hsa"), "RNAhybrid_hsa"),
               #helpText("tarbase is a database of experimentally verified targets. Other DBs deliver prediction based targets.")             
               conditionalPanel(
                 condition = "input.selectedTargetDBs=='RNAhybrid_hsa'",
                 selectInput("rnah.p.value.threshold", "p-value threshold", c(0.05, 0.01, 0.001, 0.0001), 0.05)
               )#,
               #conditionalPanel(
               # condition = "input.selectedTargetDBs!='RNAhybrid_hsa'",
               # checkboxInput("get.gene.symbols", "Fetch gene symbols?", FALSE)
               #)
               #sliderInput("group.miRNAs.threshold", "List only genes that are targeted by x miRNAs", min=1, max=50, value=2, step=1),
               #sliderInput("at.least.hits", "List only targets found at least x times in databases", min = 1, max = 1000, value = 1, step = 1),
               #sliderInput("at.least", "List only targets found in at least x databases", min = 1, max = 6, value = 3, step = 1),
               #checkboxInput("excludeDBcol", "Exclude database text column from gene target list", TRUE),
               #actionButton("updateTargets", "Update miRNA target list")
             ),mainPanel( 
             dataTableOutput("mirna.targets.table"),
             downloadButton('downloadTargets', 'Download miRNA target list')#,
             #downloadButton('downloadHotnetGeneList', 'Download hotnet2 heat scores')
             )
    ),
    tabPanel("miRNA family coverage", 
             shinyalert("miRNA_family_info", click.hide = TRUE),
             wellPanel(fluidRow(
               column(6, sliderInput("family_size_cutoff", "Family size cutoff:", min=0, max=20, value=0)),
               column(6, sliderInput("family_coverage_cutoff", "Family coverage cutoff:", min=0, max=100, value=0))
             )),
             dataTableOutput("family.hitrate")
  ),  
  tabPanel("miRNA high confidence targets", 
    sidebarPanel(
    selectInput("highConfidenceTargetsMethod", "Method:", c("permutation test", "hypergeometric test"), "hypergeometric test"),    
    conditionalPanel(
      condition = "input.highConfidenceTargetsMethod == 'permutation test'",
      numericInput("mirna.target.permutations", "Number of permutations", value=1000, min=10, max=10000)
    ),
    sliderInput("mirna.target.permutation.num.of.mirnas.cutoff", "Minimal number of miRNAs from hit list targeting a gene", value=1, min = 0, max=100, step=1),
    numericInput("mirna.target.permutation.padj.cutoff", "adjusted p-value threshold", min=0, max=1, value=0.05),
    actionButton("mirna.target.permutation.button", "Start test")
    ), mainPanel(
    dataTableOutput("mirna.target.permutation.table"),    
    downloadButton("downloadTargetPermutationTestResult", "Download")
    )
  ),
  #tabPanel("Interaction Graph", plotOutput("interactionGraph")),
  tabPanel("miRcancer DB", shinyalert("mircancer_status"), dataTableOutput("mircancer.table"))
)

do.call(tabsetPanel, elements)
})


