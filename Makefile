# ======================================================================
# Makefile - creates PDF, HTML, and plain text files from LaTeX
# ======================================================================

# Directory added to HEVEA search path
WEBTEX = $(HOME)/texmf/tex/latex/webtex

# Commands
LATEXMK  = latexmk
QPDF     = qpdf
HEVEA    = hevea
TIDY     = tidy
SED      = sed
W3M      = w3m
COMPRESS = yui-compressor
CHKTEX   = chktex
LACHECK  = lacheck

# Command options
LATEXMK_FLAGS = -pdf
QPDF_FLAGS    = --linearize --deterministic-id
HEVEA_FLAGS   = -I $(WEBTEX) -I include -fix -O -exec xxdate.exe
TIDY_FLAGS    = -config $(TIDYCONF)
W3M_FLAGS     = -dump -cols 73 -T text/html

# Warning 38: You should not use punctuation in front of quotes.
CHKTEX_FLAGS = --verbosity=2 --quiet --nowarn=38

# HTML Tidy options
# https://api.html-tidy.org/tidy/quickref_next.html
css_prefix = tidy
tidy_html = --quiet yes --force-output yes --tidy-mark no --wrap 0 \
    --add-meta-charset yes --doctype html5 --output-html yes \
    --clean yes --quote-nbsp no --css-prefix $(css_prefix) \
    --enclose-block-text yes --enclose-text yes --hide-comments yes

# Transliterates characters for plain text output
#   U+00A0 NO-BREAK SPACE --> U+0020 SPACE
#   U+2501 BOX DRAWINGS HEAVY HORIZONTAL --> U+2014 EM DASH
sed_nbsp = 'y/ / /'
sed_hr   = 'y/━/—/'
sed_text = -e $(sed_nbsp) -e $(sed_hr)

# Fixes HTML Tidy output (assumes "css-prefix: tidy")
sed_utf8  = 's/<meta http-equiv=.*/<meta charset="utf-8">/'
sed_type  = 's/<style type="text\/css">/<style>/'
sed_table = '/table.tidy/d'
sed_html  = -e $(sed_utf8) -e $(sed_type) -e $(sed_table)

# Dependencies outside the local directory
dep_latex = $(WEBTEX)/webtex.sty $(WEBTEX)/webtex.tex
dep_hevea = $(WEBTEX)/webtex.hva $(WEBTEX)/webtex.tex
dep_tidy = $(TIDYCONF)

# List of files to build
files = $(addprefix docs/index.,pdf html txt)

# ======================================================================
# Pattern Rules
# ======================================================================

VPATH = src:include

tmp/%.pdf: %.tex $(dep_latex)
	$(LATEXMK) $(LATEXMK_FLAGS) -output-directory=$(@D) $<

docs/%.pdf: tmp/%.pdf
	$(QPDF) $(QPDF_FLAGS) $< $@

tmp/%.html: %.hva %.tex meta.html head.html foot.html $(dep_hevea)
	$(HEVEA) $(HEVEA_FLAGS) -o $@ $< $(word 2,$^)

docs/%.html: tmp/%.html $(dep_tidy)
	$(TIDY) $(tidy_html) $< | $(SED) $(sed_html) > $@

tmp/%.txt: docs/%.html
	$(W3M) $(W3M_FLAGS) $< > $@

docs/%.txt: tmp/%.txt
	$(SED) $(sed_text) $< > $@

# ======================================================================
# Explicit rules
# ======================================================================

.PHONY: all check clean

all: $(files) docs/styles/style.css

docs/styles/style.css: custom.css site.css
	$(COMPRESS) $^ > $@
	$(COMPRESS) $(word 2,$^) >> $@

check: index.tex
	$(CHKTEX) $(CHKTEX_FLAGS) $<
	$(LACHECK) $<

clean:
	rm -f tmp/*.* docs/*.* docs/styles/style.css
