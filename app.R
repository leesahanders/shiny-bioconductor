options(repos=c(BiocManager::repositories()))

library(shiny)
library(bslib)
library(DT)
library(plotly)

# Bioconductor packages
library(Biostrings)
library(GenomicRanges)
library(IRanges)

# UI
ui <- page_sidebar(
  title = "Bioconductor Packages Showcase",
  sidebar = sidebar(
    h4("DNA Sequence Analysis"),
    textAreaInput("dna_seq", 
                  "Enter DNA Sequence:", 
                  value = "ATCGATCGATCGATCG",
                  placeholder = "Enter DNA sequence (A, T, C, G)"),
    
    hr(),
    
    h4("Genomic Ranges"),
    numericInput("num_ranges", "Number of ranges:", value = 5, min = 1, max = 20),
    numericInput("chr_length", "Chromosome length:", value = 1000, min = 100, max = 10000),
    actionButton("generate_ranges", "Generate Random Ranges", class = "btn-primary"),
    
    hr(),
    
    h4("Sequence Pattern"),
    textInput("pattern", "Pattern to search:", value = "ATG"),
    width = 300
  ),
  
  layout_columns(
    card(
      card_header("DNA Sequence Properties"),
      verbatimTextOutput("seq_info")
    ),
    
    card(
      card_header("Nucleotide Composition"),
      plotlyOutput("composition_plot")
    ),
    
    col_widths = c(6, 6)
  ),
  
  layout_columns(
    card(
      card_header("Pattern Matches"),
      DTOutput("pattern_matches")
    ),
    
    card(
      card_header("Reverse Complement"),
      verbatimTextOutput("rev_comp")
    ),
    
    col_widths = c(6, 6)
  ),
  
  card(
    card_header("Genomic Ranges Analysis"),
    DTOutput("genomic_ranges_table"),
    br(),
    verbatimTextOutput("ranges_summary")
  )
)

# Server
server <- function(input, output, session) {
  
  # Reactive DNA sequence
  dna_sequence <- reactive({
    req(input$dna_seq)
    # Clean and validate sequence
    seq_clean <- toupper(gsub("[^ATCG]", "", input$dna_seq))
    if (nchar(seq_clean) == 0) {
      return(DNAString("ATCG"))
    }
    DNAString(seq_clean)
  })
  
  # DNA sequence information
  output$seq_info <- renderText({
    seq <- dna_sequence()
    paste(
      "Length:", length(seq), "nucleotides\n",
      "GC Content:", round(letterFrequency(seq, "GC", as.prob = TRUE) * 100, 2), "%\n",
      "AT Content:", round(letterFrequency(seq, "AT", as.prob = TRUE) * 100, 2), "%\n",
      "Molecular Weight:", round(sum(letterFrequency(seq, c("A", "T", "C", "G")) * 
                                       c(331.2, 322.2, 307.2, 347.2)), 1), "g/mol"
    )
  })
  
  # Nucleotide composition plot
  output$composition_plot <- renderPlotly({
    seq <- dna_sequence()
    freq <- letterFrequency(seq, c("A", "T", "C", "G"))
    
    df <- data.frame(
      Nucleotide = c("A", "T", "C", "G"),
      Count = as.numeric(freq),
      Percentage = as.numeric(freq) / length(seq) * 100
    )
    
    p <- plot_ly(df, x = ~Nucleotide, y = ~Count, type = 'bar',
                 text = ~paste("Count:", Count, "<br>Percentage:", round(Percentage, 1), "%"),
                 textposition = 'outside',
                 marker = list(color = c('#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4'))) %>%
      layout(title = "Nucleotide Frequency",
             xaxis = list(title = "Nucleotide"),
             yaxis = list(title = "Count"),
             showlegend = FALSE)
    
    p
  })
  
  # Pattern matching
  output$pattern_matches <- renderDT({
    req(input$pattern)
    seq <- dna_sequence()
    pattern <- toupper(input$pattern)
    
    if (nchar(pattern) == 0 || !grepl("^[ATCG]+$", pattern)) {
      return(data.frame(Message = "Please enter a valid DNA pattern (A, T, C, G only)"))
    }
    
    matches <- matchPattern(pattern, seq)
    
    if (length(matches) == 0) {
      return(data.frame(Message = paste("No matches found for pattern:", pattern)))
    }
    
    df <- data.frame(
      Match = 1:length(matches),
      Start = start(matches),
      End = end(matches),
      Sequence = as.character(matches)
    )
    
    df
  }, options = list(pageLength = 5, dom = 't'))
  
  # Reverse complement
  output$rev_comp <- renderText({
    seq <- dna_sequence()
    rev_comp <- reverseComplement(seq)
    paste(
      "Original:  5'-", as.character(seq), "-3'\n",
      "Rev Comp:  3'-", as.character(rev_comp), "-5'"
    )
  })
  
  # Reactive genomic ranges
  genomic_ranges <- eventReactive(input$generate_ranges, {
    n <- input$num_ranges
    chr_len <- input$chr_length
    
    # Generate random ranges
    starts <- sort(sample(1:(chr_len-50), n))
    widths <- sample(10:100, n, replace = TRUE)
    ends <- pmin(starts + widths - 1, chr_len)
    
    GRanges(
      seqnames = paste0("chr", sample(1:3, n, replace = TRUE)),
      ranges = IRanges(start = starts, end = ends),
      strand = sample(c("+", "-"), n, replace = TRUE),
      gene_id = paste0("gene_", 1:n),
      score = round(runif(n, 0, 100), 2)
    )
  }, ignoreNULL = FALSE)
  
  # Initialize ranges on startup
  observe({
    genomic_ranges()
  })
  
  # Genomic ranges table
  output$genomic_ranges_table <- renderDT({
    ranges <- genomic_ranges()
    
    df <- data.frame(
      Chromosome = as.character(seqnames(ranges)),
      Start = start(ranges),
      End = end(ranges),
      Width = width(ranges),
      Strand = as.character(strand(ranges)),
      Gene_ID = ranges$gene_id,
      Score = ranges$score
    )
    
    df
  }, options = list(pageLength = 10, scrollX = TRUE))
  
  # Ranges summary
  output$ranges_summary <- renderText({
    ranges <- genomic_ranges()
    
    paste(
      "Total Ranges:", length(ranges), "\n",
      "Chromosomes:", paste(unique(as.character(seqnames(ranges))), collapse = ", "), "\n",
      "Total Width:", sum(width(ranges)), "bp\n",
      "Average Width:", round(mean(width(ranges)), 1), "bp\n",
      "Strand Distribution:\n",
      "  Forward (+):", sum(strand(ranges) == "+"), "\n",
      "  Reverse (-):", sum(strand(ranges) == "-"), "\n",
      "Average Score:", round(mean(ranges$score), 2)
    )
  })
}

# Run the application
shinyApp(ui = ui, server = server)



