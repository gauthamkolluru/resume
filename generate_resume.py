#!/usr/bin/env python3
"""
Resume Generator Script

This script uses pandoc to convert resume.md to:
- resume.html (stored in current directory)
- resume.pdf (stored in pdfs directory)
"""

import subprocess
import sys
import os
from pathlib import Path


def run_command(command, description):
    """Run a subprocess command and handle errors."""
    print(f"Running: {description}")
    print(f"Command: {' '.join(command)}")
    
    try:
        result = subprocess.run(command, 
                              check=True, 
                              capture_output=True, 
                              text=True)
        print(f"✅ Success: {description}")
        if result.stdout:
            print(f"Output: {result.stdout.strip()}")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"❌ Error: {description}")
        print(f"Return code: {e.returncode}")
        print(f"Error output: {e.stderr}")
        return False
    
    except FileNotFoundError:
        print(f"❌ Error: pandoc not found. Please install pandoc first.")
        print("On macOS: brew install pandoc")
        return False


def check_prerequisites():
    """Check if required files and tools exist."""
    # Check if resume.md exists
    if not Path("resume.md").exists():
        print("❌ Error: resume.md not found in current directory")
        return False
    
    # Check if pdfs directory exists, create if not
    pdfs_dir = Path("pdfs")
    if not pdfs_dir.exists():
        print("Creating pdfs directory...")
        pdfs_dir.mkdir()
    
    return True


def generate_html():
    """Generate resume.html from resume.md."""
    command = [
        "pandoc",
        "resume.md",
        "-o", "resume.html",
        "--standalone",
        "--metadata", "title=Resume"
    ]
    
    return run_command(command, "Converting resume.md to resume.html")


def generate_pdf():
    """Generate resume.pdf from resume.md and save to pdfs directory."""
    command = [
        "pandoc",
        "resume.md",
        "-o", "pdfs/resume.pdf",
        # "--pdf-engine=wkhtmltopdf",
        "--metadata", "title=Resume"
    ]
    
    # Try with wkhtmltopdf first, fallback to other engines if needed
    success = run_command(command, "Converting resume.md to resume.pdf (using wkhtmltopdf)")
    
    if not success:
        print("Trying alternative PDF engine (xelatex)...")
        command = [
            "pandoc",
            "resume.md",
            "-o", "pdfs/resume.pdf",
            "--pdf-engine=xelatex",
            "--metadata", "title=Resume"
        ]
        success = run_command(command, "Converting resume.md to resume.pdf (using xelatex)")
    
    return success


def main():
    """Main function to orchestrate the resume generation."""
    print("🚀 Starting resume generation...")
    print("=" * 50)
    
    # Check prerequisites
    if not check_prerequisites():
        sys.exit(1)
    
    # Generate HTML
    html_success = generate_html()
    
    # Generate PDF
    pdf_success = generate_pdf()
    
    # Summary
    print("\n" + "=" * 50)
    print("📋 Summary:")
    
    if html_success:
        print("✅ resume.html generated successfully")
    else:
        print("❌ Failed to generate resume.html")
    
    if pdf_success:
        print("✅ resume.pdf generated successfully in pdfs/ directory")
    else:
        print("❌ Failed to generate resume.pdf")
    
    if html_success and pdf_success:
        print("\n🎉 All resume files generated successfully!")
        return 0
    else:
        print("\n⚠️  Some files failed to generate. Check the errors above.")
        return 1


if __name__ == "__main__":
    sys.exit(main())