SPLITSH_LITE_PATH=/Users/kevinr/Downloads/splitsh-lite
$SPLITSH_LITE_PATH --prefix=slave1/

#!/bin/sh
#
# splitmono.sh: split subtrees within a monolithic repository to many repositories.

# Default timezone for dates in logs
: "${TZ:=MST7}"

# Main branch name
: "${UAQSRTOOLS_MAINBRANCH:=master}"

# Stem for writable repository URLs
: "${UAQSRTOOLS_REPOSTEM:=git@github.com:kraynel/}"

# Suffix for writable repository URLs
: "${UAQSRTOOLS_REPOSUFFIX:=.git}"

# Directory holding the monorepo clone
: "${UAQSRTOOLS_MONOCLONE:=$PWD}"

# Relative paths to the subtrees of interest
: "${UAQSRTOOLS_PATHLIST:=.}"

# Splitting utility name
: "${UAQSRTOOLS_SPLITTER:=splitsh-lite}"

# Executable path
if [ -z "$UAQSRTOOLS_EXEPATH" ]; then
  UAQSRTOOLS_EXEPATH="/Users/kevinr/Downloads/"
fi

#------------------------------------------------------------------------------
# Utility functions definitions.

errorexit () {
  echo "** $1." >&2
  exit 1
}

# Show progress on STDERR, unless explicitly quiet.
if [ -z "$UAQSRTOOLS_QUIET" ]; then
  logmessage () {
    echo "$1..." >&2
  }
  normalexit () {
    echo "$1." >&2
    exit 0
  }
else
  logmessage () {
    return
  }
  normalexit () {
    exit 0
  }
fi

#------------------------------------------------------------------------------
# Initial run-time error checking.

[ -d "$UAQSRTOOLS_MONOCLONE" ] \
  || errorexit "The monorepo clone directory ${UAQSRTOOLS_MONOCLONE} does not exist"
cd "$UAQSRTOOLS_MONOCLONE"
git status \
  || errorexit "No repository in the ${UAQSRTOOLS_MONOCLONE} directory"
logmessage "In the monorepo Git repository directory ${UAQSRTOOLS_MONOCLONE}"

#------------------------------------------------------------------------------
# Iterate over the paths within the monorepo containing subtrees

for relpath in $UAQSRTOOLS_PATHLIST ; do
  [ -d "$relpath" ] \
    || errorexit "Cannot find a directory holding subtrees to split at ${relpath}"
  logmessage "Looking within ${relpath} for directories holding subtrees to split"
  # Assume that any directory found holds a subttree to be split
  for splitprefix in "${relpath}/"* ; do
    if [ -d "$splitprefix" ]; then
      manyname=$(basename "$splitprefix")
      sha=$("${UAQSRTOOLS_EXEPATH}${UAQSRTOOLS_SPLITTER}" --prefix="$splitprefix" --target="refs/heads/${manyname}") \
        || errorexit "${UAQSRTOOLS_SPLITTER} crashed with status ${?} when splitting ${splitprefix}"
      [ -n "$sha" ] \
        || "Could not split ${splitprefix} from the monorepo"
      logmessage "Split ${splitprefix} from the monorepo as ${sha}"
      splitrepo="${UAQSRTOOLS_REPOSTEM}${manyname}${UAQSRTOOLS_REPOSUFFIX}"
      git push -f "$splitrepo" "+${manyname}:${UAQSRTOOLS_MAINBRANCH}" \
        || errorexit "Could not push the split for ${splitprefix} to ${splitrepo}"
      logmessage "Pushed the split for ${splitprefix} to ${splitrepo}"
    fi
  done
done

normalexit "Finished processing paths"