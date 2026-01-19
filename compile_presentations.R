# ============================================================================
# LaTeX Beamer Presentation Compiler for Health Informatics Assignment
# Author: Cavin Otieno
# ============================================================================

# SIMPLE INSTRUCTIONS:
# 1. Copy ALL the code below (from line 1 to the end)
# 2. Paste it ALL into R/RStudio console
# 3. Press Enter to run
# ============================================================================

cat("\n========================================\n")
cat("  LaTeX Beamer Presentation Compiler\n")
cat("  Health Informatics Assignment\n")
cat("========================================\n\n")

# --- Step 1: Set project directory ---
project_root <- getwd()
cat(sprintf("Project directory: %s\n\n", project_root))

# --- Step 2: Find all .tex files ---
cat("Finding .tex files...\n")
tex_files <- list.files(
  path = project_root,
  pattern = "\\.tex$",
  recursive = TRUE,
  full.names = TRUE
)
# Remove hidden/system files
tex_files <- tex_files[!grepl("/\\.", tex_files)]
tex_files <- sort(tex_files)
cat(sprintf("Found %d .tex files\n\n", length(tex_files)))

# --- Step 3: Check for LaTeX compiler ---
latex_engine <- "pdflatex"
latex_path <- Sys.which(latex_engine)

if (latex_path == "") {
  stop("\nERROR: pdflatex not found!\n",
       "Please install a LaTeX distribution first:\n",
       "  - Windows: Download MiKTeX from https://miktex.org\n",
       "  - Mac: Download MacTeX from https://www.tug.org/mactex\n",
       "  - Linux: Run: sudo apt install texlive-full\n")
}
cat(sprintf("LaTeX compiler: %s\n\n", latex_path))

# --- Step 4: Create output directory ---
output_dir <- file.path(project_root, "pdf_output")
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}
cat(sprintf("Output directory: %s\n\n", output_dir))

# --- Step 5: Compile function ---
compile_file <- function(tex_file) {
  file_dir <- dirname(tex_file)
  file_name <- basename(tex_file)
  base_name <- sub("\\.tex$", "", file_name)

  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  setwd(file_dir)

  cat(sprintf("Compiling: %s\n", file_name))

  # Build command
  cmd <- sprintf('%s -interaction=nonstopmode "%s"', latex_engine, file_name)

  # Compile (2 passes for references)
  for (pass in 1:2) {
    cat(sprintf("  Pass %d/2...\n", pass))
    result <- system(cmd, intern = FALSE)
  }

  # Check if PDF was created
  pdf_file <- paste0(base_name, ".pdf")
  if (file.exists(pdf_file)) {
    # Preserve folder structure in output
    rel_dir <- sub("^\\./", "", file_dir)
    pdf_dest_dir <- if (rel_dir == ".") output_dir else file.path(output_dir, rel_dir)

    if (!dir.exists(pdf_dest_dir)) {
      dir.create(pdf_dest_dir, recursive = TRUE)
    }

    pdf_dest <- file.path(pdf_dest_dir, pdf_file)
    file.copy(pdf_file, pdf_dest, overwrite = TRUE)
    cat(sprintf("  SUCCESS: %s -> %s\n", pdf_file, pdf_dest))
    return(TRUE)
  } else {
    cat(sprintf("  FAILED: %s\n", file_name))
    return(FALSE)
  }
}

# --- Step 6: Compile all files ---
cat("========================================\n")
cat("  Starting Compilation\n")
cat("========================================\n\n")

results <- list()
success_count <- 0
failed_count <- 0

for (tex_file in tex_files) {
  success <- compile_file(tex_file)
  results[[tex_file]] <- success

  if (success) {
    success_count <- success_count + 1
  } else {
    failed_count <- failed_count + 1
  }
  cat("\n")
}

# --- Step 7: Print summary ---
cat("========================================\n")
cat("  Compilation Summary\n")
cat("========================================\n")
cat(sprintf("Total files:  %d\n", length(tex_files)))
cat(sprintf("Successful:   %d\n", success_count))
cat(sprintf("Failed:       %d\n", failed_count))

if (failed_count > 0) {
  cat("\nFailed files:\n")
  failed_files <- names(results)[!unlist(results)]
  for (f in failed_files) {
    cat(sprintf("  - %s\n", f))
  }
}

cat(sprintf("\nPDFs saved to: %s\n", output_dir))
cat("========================================\n\n")

# --- Step 8: Save log file ---
log_file <- file.path(project_root, "compilation_log.txt")
writeLines(c(
  sprintf("Compilation Log - %s", Sys.time()),
  sprintf("Project: %s", project_root),
  sprintf("LaTeX: %s", latex_path),
  "",
  "Results:",
  paste(sprintf("  %s: %s", names(results),
        ifelse(unlist(results), "SUCCESS", "FAILED")),
      collapse = "\n"),
  "",
  sprintf("Total: %d, Success: %d, Failed: %d",
          length(tex_files), success_count, failed_count)
), log_file)

cat(sprintf("Log saved to: %s\n", log_file))
cat("\nDone! All compilations complete.\n\n")
