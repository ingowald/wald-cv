.SUFFIXES: eps/%.eps pdf/%.pdf

PAPER = wald-cv

.PHONY: epsfiles 
.PHONY: pngfromppm
.PHONY: all

all: $(PAPER).dvi $(PNG2EPS)

.PHONY: $(PAPER).dvi

#input files
PNG    	= $(wildcard png/*.png)
GNUPLOT = $(wildcard gnuplot/*.plot)
FIG 	= $(wildcard fig/*.fig)
SRCEPS 	= $(wildcard fig/*.eps)

#output files
PNG2EPS	= $(patsubst png/%.png, eps/%.eps, $(PNG))
FIG2PDF	= $(patsubst fig/%.fig, pdf/%.pdf, $(FIG))
FIG2EPS	= $(patsubst fig/%.fig, fig/%.eps, $(FIG))
GNU2EPS = $(patsubst gnuplot/%.plot, eps/%.eps, $(GNUPLOT))
GNU2PDF = $(patsubst gnuplot/%.plot, pdf/%.pdf, $(GNUPLOT))
EPS2PDF = $(patsubst fig/%.eps, pdf/%.pdf, $(SRCEPS))

eps2pdf:
	echo $(EPS2PDF)

png2eps:
	echo $(PNG2EPS)

fig2pdf: $(FIG2PDF)

eps2pdf: $(EPS2PDF)

fig/%.eps: fig/%.fig 
	fig2dev -L pstex $< $@
#	fig2dev -L eps $< $@

eps/%.eps: png/%.png 
	@mkdir -p eps
	convert $< -resize 120 $@
#	convert $< $@

pdf/%.pdf: fig/%.fig 
	@mkdir -p png
	fig2dev -L pdf -p bla  $< $@

#	fig2dev -L ps -p bla  $< $(patsubst fig/%.fig, fig/%.eps, $<)
#	perl ./eps2pdf.perl $(patsubst fig/%.fig, fig/%.eps, $<) --outfile=$@

eps/%.eps: gnuplot/%.plot
	gnuplot $<

pdf/%.pdf: gnuplot/%.plot
	gnuplot $<
	perl ./eps2pdf.perl $(patsubst gnuplot/%.plot, eps/%.eps, $<) --outfile=$(patsubst gnuplot/%.plot,pdf/%.pdf, $<)

pdf/%.pdf: fig/%.eps
	perl ./eps2pdf.perl $< --outfile=$@


$(PAPER).ps: $(PAPER).dvi
	dvips -Ppdf -G0 -o $@ $<


SOURCES = $(wildcard *.tex)


# this is all automatic, new citations will be detected as well as reference changes
# BUT: if some citations are no longer needed you have to run bibtex manually
#      otherwise there will be not (no longer) referenced bib entries
$(PAPER).dvi: $(PNG2EPS) $(GNU2EPS) $(SOURCES) $(FIG2EPS) $(PAPER).tex
	touch lastrun
	latex $(PAPER)
	if test "`grep -cs Citation.*undefined $(PAPER).log`" != "0" ; then bibtex $(PAPER); latex $(PAPER); fi
	until test "`fgrep -cs Rerun $(PAPER).log`" = "0" ; do latex $(PAPER); done

# as recommend by EG, remember to adjust 'convert' to avoid downscaled images
$(PAPER).pdf: $(FIG2PDF) $(PAPER).ps
	ps2pdf -dMaxSubsetPct=100 \
               -dCompatibilityLevel=1.3 \
               -dSubsetFonts=true \
               -dEmbedAllFonts=true \
               -dAutoFilterColorImages=false \
               -dAutoFilterGrayImages=false \
               -dColorImageFilter=/FlateEncode \
               -dGrayImageFilter=/FlateEncode \
               -dMonoImageFilter=/FlateEncode \
               $(PAPER).ps $@ 

pdf: $(PAPER).pdf

# depend on $(PAPER).dvi to get all dependencies and references right, then just pdflatex
final: $(FIG2PDF) $(GNU2PDF) $(PAPER).dvi
	pdflatex $(PAPER)


.PHONY: realclean clean final pdf
clean:
	$(RM) -f $(PAPER).aux $(PAPER).bbl $(PAPER).blg $(PAPER).dvi $(PAPER).lbl $(PAPER).log $(PAPER).pdf $(PAPER).ps

realclean: clean
	$(RM) -rf eps
