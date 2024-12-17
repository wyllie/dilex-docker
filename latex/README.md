# LaTeX Dockerfile


Use the make file do generate a pdf and/or docx file from the LaTeX source.
The name of the file should match the name of the directory the file is located
in.  So, to gen the code for a file called "MyCoolDoc.text", you would need to 
create a directory called "MyCoolDoc" and put "MyCoolDoc.tex" in that
directory.

The make commands will then look like this:

```
# Build the PDF
make NAME=MyCoolDoc

# Generate DOCX
make NAME=MyCoolDoc docx

# Watch for file changes
make NAME=MyCoolDoc watch

# get rid of LaTex temp files
make NAME=MyCoolDoc clean

# get rid of all the generated files
make NAME=MyCoolDoc really-clean
```
