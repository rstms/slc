CC=gcc
WINDRES = windres
CFLAGS = -Wall -Wextra -Wno-unused-parameter -DANSI -mwindows
LDFLAGS = -mwindows
LIBS = -lstdc++ -luser32 -lgdi32 -lcomdlg32 -lcomctl32 -lshell32 -lgdiplus

PROGRAM = slc
COMPANY = Reliance Systems
VERSION != cat VERSION
MAJOR != awk <VERSION -F. '{print $$1}'
MINOR != awk <VERSION -F. '{print $$2}'
PATCH != awk <VERSION -F. '{print $$3}'

INSTALLER = $(PROGRAM)-v$(VERSION)-win32.exe
REPO_NAME = $(shell git remote -v | awk -F'[:/ ]' '/fetch/{print $$3}')
RELEASE_PATH = repos/$(GITHUB_ORG)/$(REPO_NAME)/releases
RELEASE_DATA = {\
 \"tag_name\":\"v$$(cat VERSION)\",\
 \"target_commitish\": \"master\",\
 \"name\": \"Release v$$(cat VERSION)\",\
 \"body\": \"Release v$$(cat VERSION)\",\
 \"draft\": false,\
 \"prerelease\": false\
 }
RELEASE_CURL = curl --fail-with-body -s -X POST -H "Authorization: token $(GITHUB_TOKEN)"


OBJS = $(PROGRAM).o

MACROS = \
  -D__VERSION__=$(VERSION) \
  -D__MAJOR__=$(MAJOR) \
  -D__MINOR__=$(MINOR) \
  -D__PATCH__=$(PATCH) \
  -D__PROGRAM__=$(PROGRAM) \
  -D__COMPANY__="$(COMPANY)" \
  -D__DESCRIPTION__='periodic screen capture logger' \
  -D__EXE_FILE__=$(PROGRAM).exe \
  -D__ICON_FILE__=$(PROGRAM).ico \
  -D__INSTALLER_FILE__=$(INSTALLER) \
  -D__ABOUT_URL__='https://github.com/rstms/RelianceScreenLogger' \
  -D__INSTALL_SIZE__=8192

$(PROGRAM).exe: $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $(OBJS) $(LIBS)

LICENSE.txt: LICENSE
	unix2dos -n $< $@

$(PROGRAM).o: $(PROGRAM).c $(PROGRAM).h
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f $(OBJS) *.exe LICENSE.txt .release*

sterile: clean

bump:	clean
	$(call GITCLEAN)
	@echo "$(MAJOR).$(MINOR).$(shell echo $$(($(PATCH) + 1)))" >VERSION
	$(MAKE) installer
	$(call GITCLEAN)
	git commit -a -m "v$$(cat VERSION)"
	git tag v$$(cat VERSION)
	git push 
	git push origin v$$(cat VERSION)

.release: installer
	$(call GITCLEAN)
	@$(RELEASE_CURL) -o $@ \
		-H "Content-Type: application/json" \
		-d "$(RELEASE_DATA)" \
		"https://api.github.com/$(RELEASE_PATH)" || { cat $@; false; }

.upload: .release
	$(call GITCLEAN)
	@$(RELEASE_CURL) -o $@ \
		-H "Content-Type: $(shell file --mime-type -b $(INSTALLER))" \
	  	--data-binary @$(INSTALLER) \
  	  	"https://uploads.github.com/$(RELEASE_PATH)/$(shell jq <$< '.id')/assets?name=$(shell basename $(INSTALLER))" \
	|| { cat $@; false; }

release: .upload

#
# functions
#

define GITCLEAN =
  $(if $(shell git status --porcelain),$(error git status is dirty),)
endef
