# 'Makefile'

# Where sources are located
SOURCE_DIR = .
# Where all the compiled sources will be
TARGET_DIR = docs

# Where assets are located
ASSETS_DIR = assets
# Where all the compiled assets will be
BUILDS_DIR = $(TARGET_DIR)/$(ASSETS_DIR)

# use --toc option generate links to anchors
MD = pandoc --data-dir=$(CURDIR) --from markdown \
	--template documentary.html --standalone \
	--filter plugins/graphviz.py

DOT = dot -Tsvg

ASSETS_SOURCES = $(shell find $(ASSETS_DIR) -type f | grep -E ".*(css|js|woff|ttf|eot)" | cut -sd / -f 2-)
ASSETS_TARGETS = $(ASSETS_SOURCES:%=$(BUILDS_DIR)/%)

# MD_SOURCES = $(shell find $(SOURCE_DIR) -name 'index.md' | cut -sd / -f 2-)
# MD_SOURCES = $(shell find $(SOURCE_DIR) -name '*.md' | cut -sd / -f 2-)
MD_TARGETS = $(TARGET_DIR)/index.html

DOT_SOURCES = $(shell find $(SOURCE_DIR) -name '*.dot' | cut -sd / -f 2-)
DOT_TARGETS = $(DOT_SOURCES:%.dot=$(TARGET_DIR)/%.svg)

all: assets sources

assets: $(ASSETS_TARGETS)

$(ASSETS_TARGETS): $(BUILDS_DIR)/%: $(ASSETS_DIR)/%
	@mkdir -p $(@D)
	cp -f $< $@

sources: $(MD_TARGETS) $(DOT_TARGETS)

SLIDES = $(shell find \
	revisions* \
	git* \
	init* \
)

index.md: $(SLIDES)
	$^ | xargs -I{} sh -c "echo '<section class=\"center\">'; cat {}; echo '\n</section>\n'" > $@

$(TARGET_DIR)/%.html: $(SOURCE_DIR)/%.md $(SOURCE_DIR)/makefile plugins/graphviz.py templates/documentary.html
	@mkdir -p $(@D)
	$(MD) --to html5 $< --output $@
	@sed -i '' -e '/href="./s/\.md/\.html/g' $@
	@sed -i '' -e '/src="./s/\.dot/\.svg/g' $@

$(TARGET_DIR)/%.svg: $(SOURCE_DIR)/%.dot makefile
	@mkdir -p $(@D)
	$(DOT) $< -o $@

PHONY: watch serve clean debug

watch:
	(while true; do make; sleep 1; done) | grep -v 'make\[1\]'

serve:
	cd $(TARGET_DIR) && python -m SimpleHTTPServer 8000

clean:
	rm -rf $(TARGET_DIR)/*

debug:
	@echo $(SLIDES)
