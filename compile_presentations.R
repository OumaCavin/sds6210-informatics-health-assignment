#!/usr/bin/env Rscript
# ============================================================================
# LaTeX Beamer Presentation Compiler for Health Informatics Assignment
# Author: Cavin Otieno
# ============================================================================

# Required packages (optional - script works without them)
if (!require("tools", quietly = TRUE)) {
  message("Package 'tools' not found, using base R functions only")
}

# ============================================================================
# Configuration
# ============================================================================

# Project root directory (where this script is located)
project_root <- if (interactive()) {
  dirname(sys.frame(1)$ofile)
} else {
  getwd()
}

# Set working directory to project root
setwd(project_root)

# LaTeX compiler to use
latex_engine <- "pdflatex"

# Number of compilation passes (for references)
passes <- 2

# Output directory for PDFs
output_dir <- file.path(project_root, "pdf_output")

# ============================================================================
# Helper Functions
# ============================================================================

#' Find all .tex files in the project
#' @param root_dir Root directory to search
#' @param pattern Pattern to match (default: *.tex)
#' @return Vector of file paths
find_tex_files <- function(root_dir = ".", pattern = "\\.tex$") {
  files <- list.files(
    path = root_dir,
    pattern = pattern,
    recursive = TRUE,
    full.names = TRUE
  )
  # Filter out files starting with . and in certain directories
  files <- files[!grepl("^\\./\\.", files)]
  files <- files[!grepl("/\\.", files)]
  return(files)
}

#' Compile a single LaTeX file
#' @param tex_file Path to the .tex file
#' @param engine LaTeX engine to use
#' @param passes Number of compilation passes
#' @return TRUE if successful, FALSE otherwise
compile_latex_file <- function(tex_file, engine = "pdflatex", passes = 2) {
  # Get file info
  file_dir <- dirname(tex_file)
  file_name <- basename(tex_file)
  base_name <- sub("\\.tex$", "", file_name)

  # Change to file directory for compilation
  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  setwd(file_dir)

  message(sprintf("\n[%s] Compiling: %s", Sys.time(), file_name))

  # Build compile command
  cmd <- sprintf("%s -interaction=nonstopmode -shell-escape %s",
                 engine, file_name)

  # Run compilation for specified passes
  success <- FALSE
  for (pass in 1:passes) {
    message(sprintf("  Pass %d/%d...", pass, passes))

    result <- tryCatch({
      system(cmd, intern = FALSE, ignore.stdout = FALSE, ignore.stderr = FALSE)
    }, error = function(e) {
      message(sprintf("  Error: %s", e$message))
      1
    })

    if (result == 0) {
      success <- TRUE
    }
  }

  if (success) {
    message(sprintf("  [SUCCESS] %s compiled successfully!", file_name))

    # Move PDF to output directory if it exists
    pdf_file <- paste0(base_name, ".pdf")
    if (file.exists(pdf_file)) {
      if (!dir.exists(output_dir)) {
        dir.create(output_dir, recursive = TRUE)
      }

      # Preserve relative path structure
      relative_dir <- sub("^\\./", "", file_dir)
      pdf_output_dir <- if (relative_dir == ".") {
        output_dir
      } else {
        file.path(output_dir, relative_dir)
      }

      if (!dir.exists(pdf_output_dir)) {
        dir.create(pdf_output_dir, recursive = TRUE)
      }

      pdf_destination <- file.path(pdf_output_dir, pdf_file)
      file.copy(pdf_file, pdf_destination, overwrite = TRUE)
      message(sprintf("  PDF saved to: %s", pdf_destination))
    }
  } else {
    message(sprintf("  [FAILED] %s compilation failed!", file_name))
  }

  return(success)
}

#' Compile all Beamer presentations
#' @param tex_files Vector of .tex file paths
#' @param engine LaTeX engine
#' @param passes Number of passes
#' @return Summary data frame
compile_all_presentations <- function(tex_files, engine = "pdflatex", passes = 2) {
  message("============================================================")
  message("  LaTeX Beamer Presentation Compiler")
  message("  Health Informatics Assignment - Cavin Otieno")
  message("============================================================")
  message(sprintf("\nProject root: %s", project_root))
  message(sprintf("LaTeX engine: %s", engine))
  message(sprintf("Files to compile: %d", length(tex_files)))
  message(sprintf("Output directory: %s", output_dir))
  message("\nStarting compilation...\n")

  # Track results
  results <- data.frame(
    file = character(),
    status = character(),
    stringsAsFactors = FALSE
  )

  # Compile each file
  for (tex_file in tex_files) {
    success <- compile_latex_file(tex_file, engine, passes)
    results <- rbind(results, data.frame(
      file = tex_file,
      status = ifelse(success, "SUCCESS", "FAILED"),
      stringsAsFactors = FALSE
    ))
  }

  # Print summary
  message("\n============================================================")
  message("  Compilation Summary")
  message("============================================================")

  success_count <- sum(results$status == "SUCCESS")
  failed_count <- sum(results$status == "FAILED")

  message(sprintf("  Total files: %d", nrow(results)))
  message(sprintf("  Successful:  %d", success_count))
  message(sprintf("  Failed:      %d", failed_count))

  if (failed_count > 0) {
    message("\n  Failed files:")
    failed_files <- results$status == "FAILED"
    for (f in results$file[failed_files]) {
      message(sprintf("    - %s", f))
    }
  }

  message("\n============================================================")

  return(results)
}

# ============================================================================
# Main Execution
# ============================================================================

main <- function() {
  # Find all .tex files
  tex_files <- find_tex_files(project_root)

  # Filter to only Beamer/presentation files (optional - include all)
  beamer_files <- tex_files[grepl("\\.tex$", tex_files)]

  # Sort files for consistent output
  beamer_files <- sort(beamer_files)

  # Compile all presentations
  results <- compile_all_presentations(beamer_files, latex_engine, passes)

  # Save compilation log
  log_file <- file.path(project_root, "compilation_log.txt")
  writeLines(c(
    sprintf("Compilation Log - %s", Sys.time()),
    sprintf("Project: %s", project_root),
    sprintf("Engine: %s", latex_engine),
    "",
    "Results:",
    paste(sprintf("  %s: %s", results$file, results$status), collapse = "\n"),
    "",
    sprintf("Total: %d, Success: %d, Failed: %d",
            nrow(results),
            sum(results$status == "SUCCESS"),
            sum(results$status == "FAILED"))
  ), log_file)

  message(sprintf("\nCompilation log saved to: %s", log_file))

  # Return results for programmatic use
  return(results)
}

# Run if executed as script
if (!interactive() || identical(Sys.getenv("RUN_MAIN"), "TRUE")) {
  main()
}
