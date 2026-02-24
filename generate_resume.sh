#!/bin/bash

# Resume Generator Script
# 
# This script uses pandoc to convert resume.md to:
# - resume.html (stored in current directory)
# - resume.pdf (stored in pdfs directory)

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Success/failure tracking
html_success=false
pdf_success=false

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_success() {
    print_status "$GREEN" "✅ $1"
}

print_error() {
    print_status "$RED" "❌ $1"
}

print_warning() {
    print_status "$YELLOW" "⚠️  $1"
}

print_info() {
    print_status "$BLUE" "$1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to run command with error handling
run_command() {
    local description=$1
    shift  # Remove first argument, rest are the command
    
    print_info "Running: $description"
    print_info "Command: $*"
    
    if "$@"; then
        print_success "$description"
        return 0
    else
        local exit_code=$?
        print_error "$description (exit code: $exit_code)"
        return $exit_code
    fi
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if pandoc is installed
    if ! command_exists pandoc; then
        print_error "pandoc not found. Please install pandoc first."
        print_info "On macOS: brew install pandoc"
        return 1
    fi
    
    # Check if resume.md exists
    if [[ ! -f "resume.md" ]]; then
        print_error "resume.md not found in current directory"
        return 1
    fi
    
    # Create pdfs directory if it doesn't exist
    if [[ ! -d "pdfs" ]]; then
        print_info "Creating pdfs directory..."
        mkdir -p pdfs
    fi
    
    print_success "Prerequisites check passed"
    return 0
}

# Generate HTML
generate_html() {
    if run_command "Converting resume.md to resume.html" \
       pandoc resume.md -o resume.html --standalone --metadata title=Resume; then
        html_success=true
        return 0
    else
        return 1
    fi
}

# Generate PDF
generate_pdf() {
    # Try default PDF engine first
    if run_command "Converting resume.md to resume.pdf (default engine)" \
       pandoc resume.md -o pdfs/resume.pdf --metadata title=Resume; then
        pdf_success=true
        return 0
    fi
    
    # Try with wkhtmltopdf if available
    if command_exists wkhtmltopdf; then
        print_info "Trying with wkhtmltopdf engine..."
        if run_command "Converting resume.md to resume.pdf (wkhtmltopdf)" \
           pandoc resume.md -o pdfs/resume.pdf --pdf-engine=wkhtmltopdf --metadata title=Resume; then
            pdf_success=true
            return 0
        fi
    fi
    
    # Try with xelatex if available
    if command_exists xelatex; then
        print_info "Trying with xelatex engine..."
        if run_command "Converting resume.md to resume.pdf (xelatex)" \
           pandoc resume.md -o pdfs/resume.pdf --pdf-engine=xelatex --metadata title=Resume; then
            pdf_success=true
            return 0
        fi
    fi
    
    print_warning "All PDF generation attempts failed. You may need to install additional dependencies:"
    print_info "For wkhtmltopdf: brew install --cask wkhtmltopdf"
    print_info "For LaTeX: brew install --cask mactex-no-gui"
    return 1
}

# Main function
main() {
    print_info "🚀 Starting resume generation..."
    echo "=================================================="
    
    # Check prerequisites
    if ! check_prerequisites; then
        exit 1
    fi
    
    echo ""
    
    # Generate HTML
    generate_html || true  # Continue on failure
    
    echo ""
    
    # Generate PDF  
    generate_pdf || true  # Continue on failure
    
    # Summary
    echo ""
    echo "=================================================="
    print_info "📋 Summary:"
    
    if $html_success; then
        print_success "resume.html generated successfully"
    else
        print_error "Failed to generate resume.html"
    fi
    
    if $pdf_success; then
        print_success "resume.pdf generated successfully in pdfs/ directory"
    else
        print_error "Failed to generate resume.pdf"
    fi
    
    echo ""
    if $html_success && $pdf_success; then
        print_success "🎉 All resume files generated successfully!"
        exit 0
    elif $html_success || $pdf_success; then
        print_warning "Some files generated successfully, but there were errors."
        exit 1
    else
        print_error "All generation attempts failed. Check the errors above."
        exit 1
    fi
}

# Run main function
main "$@"