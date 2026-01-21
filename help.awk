# ex: sw=4 ts=4 et ai
###############################################################################
# Makefile self-documenting help generator (POSIX awk compatible)
# See https://github.com/jin-gizmo/makehelp for more information.
#
# Version !VERSION!
#
#       If it ain't broke, it doesn't have enough features yet.
#
# Murray Andrews
###############################################################################

BEGIN {
    load_theme(theme)

    # width can be set as command line var or we work it out ourself
    WIDTH = width > 0 ? width : tty_columns()
    if (WIDTH < 65) WIDTH = 65

    # Set hr to "yes" on command line to enable horizontal lines.
    # Suppress for none theme. Won't work on some terminals (e.g macOS Terminal.app)
    if (hr == "yes" && theme != "none")
        HR = sprintf("%s\033[37;2;9m%s%s", spaces(I_L_HR), spaces(WIDTH - I_L_HR - I_R_HR), R_ALL)
    else
        HR = ""

    DEPENDENCY_RECURSION_LIMIT = 10
    DEPENDENCY_RESOLUTION = (resolve_dependencies != "") ? resolve_dependencies : "yes"
    DEFAULT_CATEGORY = default_category ? default_category : "Targets"
    DEFAULT_VAR_CATEGORY = default_var_category ? default_var_category : "Variables"
    # DEFAULT_VALUE is for unset variables. Variables explicitly set to empty
    # don't use this.
    # DEFAULT_VALUE = "..."
    DEFAULT_VALUE = ""
    HELP_CATEGORY = (help_category != "") ? help_category : DEFAULT_CATEGORY

    # Initialise state trackers
    RequiredArgs = ""
    OptionalArgs = ""
    TargetCategory = DEFAULT_CATEGORY
    VarCategory = DEFAULT_VAR_CATEGORY
    split("", MakeVars)             # #@var declarations
    split("", TargetCategorySet)    # #@cat category-name --> order of occurrence
    split("", VarCategorySet)       # #@vcat category-name --> order of occurrence
    split("", TargetDeps)           # Target dependencies for resolution
    split("", PendingReq)           # PendingReq[var] = value
    split("", PendingOpt)           # PendingOpt[var] = value
    split("", TargetReq)            # TargetReq[tgt, var] = value-or-empty
    split("", TargetOpt)            # TargetOpt[tgt, var] = value-or-empty
    split("", ResolvedReq)          # After recursive resolution of dependencies.
    split("", ResolvedOpt)
    PrologueCount = 0
    EpilogueCount = 0
}

# ------------------------------------------------------------------------------
# Utility functions
# ------------------------------------------------------------------------------

# Format / theme setup
function load_theme(theme) {
    # Basic theme
    THEMES["basic", "category"] = "\033[31m"    # red
    THEMES["basic", "target"] = "\033[36m"      # cyan
    THEMES["basic", "argument"] = "\033[33m"    # yellow
    THEMES["basic", "value"] = "\033[33;4m"     # yellow + underline
    THEMES["basic", "prologue"] = ""
    THEMES["basic", "description"] = ""
    THEMES["basic", "warning"] = "\033[1;93;7m"
    THEMES["basic", "code"] = "\033[4;2m"       # underline for code in backticks
    THEMES["basic", "code-reset"] = "\033[24;22m"
    THEMES["basic", "bold"] = "\033[1m"
    THEMES["basic", "bold-reset"] = "\033[22m"
    THEMES["basic", "italic"] = "\033[3m"
    THEMES["basic", "italic-reset"] = "\033[23m"
    THEMES["basic", "underline"] = "\033[4m"
    THEMES["basic", "underline-reset"] = "\033[24m"
    THEMES["basic", "reset"] = "\033[0m"        # reset everything

    # Dark theme
    THEMES["dark", "category"] = "\033[35m"     # magenta
    THEMES["dark", "target"] = "\033[32m"       # green
    THEMES["dark", "argument"] = "\033[34m"     # blue
    THEMES["dark", "value"] = "\033[34;4m"      # blue + underline
    THEMES["dark", "prologue"] = ""
    THEMES["dark", "description"] = ""
    THEMES["dark", "warning"] = "\033[1;93;7m"
    THEMES["dark", "code"] = "\033[4;2m"         # underline for code in backticks
    THEMES["dark", "code-reset"] = "\033[24;22m"
    THEMES["dark", "bold"] = "\033[1m"
    THEMES["dark", "bold-reset"] = "\033[22m"
    THEMES["dark", "italic"] = "\033[3m"
    THEMES["dark", "italic-reset"] = "\033[23m"
    THEMES["dark", "underline"] = "\033[4m"
    THEMES["dark", "underline-reset"] = "\033[24m"
    THEMES["dark", "reset"] = "\033[0m"         # reset everything

    # Light theme
    THEMES["light", "category"] = "\033[91m"    # bright red
    THEMES["light", "target"] = "\033[96m"      # bright cyan
    THEMES["light", "argument"] = "\033[93m"    # bright yellow
    THEMES["light", "value"] = "\033[93;4m"     # bright yellow + underline
    THEMES["light", "prologue"] = ""
    THEMES["light", "description"] = ""
    THEMES["light", "warning"] = "\033[1;93;7m"
    THEMES["light", "code"] = "\033[4m"         # underline for code in backticks
    THEMES["light", "code-reset"] = "\033[24m"
    THEMES["light", "bold"] = "\033[1m"
    THEMES["light", "bold-reset"] = "\033[22m"
    THEMES["light", "italic"] = "\033[3m"
    THEMES["light", "italic-reset"] = "\033[23m"
    THEMES["light", "underline"] = "\033[4m"
    THEMES["light", "underline-reset"] = "\033[24m"
    THEMES["light", "reset"] = "\033[0m"        # reset everything

    # none theme
    THEMES["none", "category"] = ""
    THEMES["none", "target"] = ""
    THEMES["none", "argument"] = ""
    THEMES["none", "value"] = ""
    THEMES["none", "prologue"] = ""
    THEMES["none", "description"] = ""
    THEMES["none", "warning"] = ""
    THEMES["none", "code"] = "`"
    THEMES["none", "code-reset"] = "`"
    THEMES["none", "bold"] = "++"    # Cannot be ** or will clash with italic
    THEMES["none", "bold-reset"] = "++"
    THEMES["none", "italic"] = "/"  # Need to avoid * to avoid clash with bold
    THEMES["none", "italic-reset"] = "/"
    THEMES["none", "underline"] = "_"
    THEMES["none", "underline-reset"] = "_"
    THEMES["none", "reset"] = ""

    # Set active theme
    if (!((theme SUBSEP "category") in THEMES))
        theme = "basic"

    # Load active theme
    F_CAT = THEMES[theme, "category"]
    F_TGT = THEMES[theme, "target"]
    F_ARG = THEMES[theme, "argument"]
    F_VAL = THEMES[theme, "value"]
    F_LOG = THEMES[theme, "prologue"]       # Prologue and epilogue
    F_DSC = THEMES[theme, "description"]    # Target and variable descriptions
    F_WARN = THEMES[theme, "warning"]
    F_CODE = THEMES[theme, "code"]          # Code in backticks
    R_CODE = THEMES[theme, "code-reset"]
    F_BOLD = THEMES[theme, "bold"]
    R_BOLD = THEMES[theme, "bold-reset"]
    F_ITAL = THEMES[theme, "italic"]
    R_ITAL = THEMES[theme, "italic-reset"]
    F_UNDL = THEMES[theme, "underline"]
    R_UNDL = THEMES[theme, "underline-reset"]
    R_ALL = THEMES[theme, "reset"]

    # Indents
    I_L_CAT = 0     # Left indent for category headings
    I_L_TGT = 4     # Left indent for targets / variables
    I_L_DSC = 8     # Left indent for descriptions
    I_R_DSC = 0     # Right indent for descriptions
    I_L_LOG = 4     # Left indent for prologue and epilogue
    I_R_LOG = 4     # Right indent for prologue and epilogue
    I_L_HR = 4      # Left indent for horizontal rule
    I_R_HR = 4      # Right indent for horizontal rule
}

# Try to determine TTY width. Returns 0 on failure.
# WARNING: Do not use tput -- not safe if not running on tty.
function tty_columns(    cmd, a, line) {
    if (ENVIRON["COLUMNS"] > 0)
        return ENVIRON["COLUMNS"] + 0

    if ((cmd = "stty size < /dev/tty 2>/dev/null") | getline line) {
        close(cmd)
        split(line, a)
        if (a[2] > 0) return a[2] + 0
    }
    return 0
}

function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }

function strip_ansi(s) { gsub(/\033\[[0-9;]*m/, "", s); return s }

function spaces(n) { return sprintf("%" n "s", "")}

# Unescape ANSI codes to reactivate them
function unescape(s,   i, j, c, o) {
    gsub(/\\033|\\x1b|\\e/, "\033", s)
    gsub(/\\a/, "\007", s)
    gsub(/\\b/, "\010", s)
    gsub(/\\f/, "\014", s)
    gsub(/\\n/, "\n", s)
    gsub(/\\r/, "\r", s)
    gsub(/\\t/, "\t", s)
    gsub(/\\v/, "\013", s)

    # octal \000 sequences (up to 3 digits)
    i = 1
    while (i <= length(s)) {
        if (substr(s, i, 1) == "\\" && match(substr(s, i + 1), "^[0-7]{1,3}")) {
            # extract matched octal digits
            o = substr(s, i + 1, RLENGTH)
            # convert octal manually
            c = 0
            for (j = 1; j <= length(o); j++) {
                c = c * 8 + int(substr(o, j, 1))
            }
            s = substr(s, 1, i - 1) sprintf("%c", c) substr(s, i + 1 + length(o))
            i += 0  # stay at this position in case multiple sequences
        } else {
            i++
        }
    }

    return s
}

# Expand Make style variable references $(VAR) and $x
function expand_vars(s,    pre, var, post, repl, r) {
    gsub(/\$\$/, "__DOLLAR__", s)
    while (match(s, /\$\([A-Za-z0-9_]+\)|\$[A-Za-z0-9_]/)) {
        pre = substr(s, 1, RSTART - 1)
        post = substr(s, RSTART + RLENGTH)
        r = substr(s, RSTART, RLENGTH)
        if (substr(r, 1, 2) == "$(")
            var = substr(r, 3, RLENGTH - 3)
        else
            var = substr(r, 2, 1)
        repl = (var in MakeVars) ? MakeVars[var] : ""
        s = pre repl post
    }
    gsub(/__DOLLAR__/, "$", s)
    return s
}

# Add a token to the specified array for the given target.
# The token is either `name` or `name=value`.
function parse_arg(token, arr,    name, value, eq_pos) {
    eq_pos = index(token, "=")
    if (eq_pos) {
        name = substr(token, 1, eq_pos - 1)
        value = expand_vars(substr(token, eq_pos + 1))
    } else {
        name = token
        value = ""
    }
    arr[name] = value
}

# Add some simple markdown-like inline styling for bold, italic. underline, backtick
function style_inline(s,    pre, mid, post, new_s) {
    # Phase 1: shield escaped characters
    gsub(/\\\\/, "__ESC_BSLASH__", s)
    gsub(/\\\*/, "__ESC_STAR__", s)
    gsub(/\\_/, "__ESC_UNDER__", s)
    gsub(/\\`/, "__ESC_TICK__", s)

    # Phase 2: apply inline styles

    # Backticks: `code`
    while (match(s, /`[^`]+`/)) {
        pre = substr(s, 1, RSTART - 1)
        mid = substr(s, RSTART + 1, RLENGTH - 2)
        post = substr(s, RSTART + RLENGTH)
        new_s = pre F_CODE mid R_CODE post
        if (new_s == s) break
        s = new_s
    }

    # Bold: **text**
    while (match(s, /\*\*[^*]+\*\*/)) {
        pre = substr(s, 1, RSTART - 1)
        mid = substr(s, RSTART + 2, RLENGTH - 4)
        post = substr(s, RSTART + RLENGTH)
        new_s = pre F_BOLD mid R_BOLD post
        if (new_s == s) break
        s = new_s
    }

    # Italic: *text*
    while (match(s, /\*[^*]+\*/)) {
        pre = substr(s, 1, RSTART - 1)
        mid = substr(s, RSTART + 1, RLENGTH - 2)
        post = substr(s, RSTART + RLENGTH)
        new_s = pre F_ITAL mid R_ITAL post
        if (new_s == s) break
        s = new_s
    }

    # Underline: _text_
    while (match(s, /_[^_]+_/)) {
        pre = substr(s, 1, RSTART - 1)
        mid = substr(s, RSTART + 1, RLENGTH - 2)
        post = substr(s, RSTART + RLENGTH)
        new_s = pre F_UNDL mid R_UNDL post
        if (new_s == s) break
        s = new_s
    }

    # Phase 3: restore escaped characters
    gsub(/__ESC_BSLASH__/, "\\", s)
    gsub(/__ESC_STAR__/, "*", s)
    gsub(/__ESC_UNDER__/, "_", s)
    gsub(/__ESC_TICK__/, "`", s)

    return s
}

# Wrap lines of text with optional indenting. First line indent on the left can
# be different from subsequent lines. Handles non-nested ANSI inline styles
# correctly across wraps.
function wrap(text, first_indent, left_indent, right_indent, \
            available_width, n, i, w, line, test, active_style, word, indent_s) {

    indent_s = spaces(first_indent)
    available_width = WIDTH - first_indent - right_indent

    n = split(text, w, /[[:space:]]+/)
    line = ""
    active_style = ""

    for (i = 1; i <= n; i++) {
        word = w[i]
        test = (line ? line " " word : word)

        # Wrap before mutating style state
        if (length(strip_ansi(test)) > available_width) {
            # Terminate any active style on the output line
            if (active_style)
                printf "%s%s%s\n", indent_s, line, R_ALL
            else
                printf "%s%s\n", indent_s, line
            indent_s = spaces(left_indent)
            available_width = WIDTH - left_indent - right_indent

            # Start continuation line: reapply any active style after indent
            line = active_style ? active_style word : word
        } else {
            line = test
        }

        # Update style state based on END STATE of this word
        if (index(word, R_ALL)) active_style = ""
        else if (index(word, R_BOLD)) active_style = ""
        else if (index(word, R_ITAL)) active_style = ""
        else if (index(word, R_UNDL)) active_style = ""
        else if (index(word, R_CODE)) active_style = ""
        else if (index(word, F_BOLD)) active_style = F_BOLD
        else if (index(word, F_ITAL)) active_style = F_ITAL
        else if (index(word, F_UNDL)) active_style = F_UNDL
        else if (index(word, F_CODE)) active_style = F_CODE

    }

    if (line) {
        if (active_style)
            printf "%s%s%s\n", indent_s, line, R_ALL
        else
            printf "%s%s\n", indent_s, line
    }
}


# Print paragraphs from array with proper joining, wrapping, and automatic styling
function print_paragraphs(arr, n, style, left_indent, right_indent,    i, raw, line, para) {

    para = ""
    for (i = 1; i <= n; i++) {
        raw = expand_vars(arr[i])
        if (raw ~ /^[[:space:]]*$/) {
            # Paragraph break: whitespace-only line
            if (para) {
                wrap(para, left_indent, left_indent, right_indent)
                para = ""
            }
            print ""
            continue
        }
        line = style style_inline(raw) R_ALL
        para = para ? para " " line : line
    }
    if (para)
        wrap(para, left_indent, left_indent, right_indent)
}

# Format either the required or optional args for a target into a string.
function format_args(arg_array, tgt, prefix, suffix, \
                    s, tmp_args, sorted_args, arg, val, arg_count, i) {

    afilter(arg_array, tgt, tmp_args)
    if (length(tmp_args) == 0) return

    arg_count = 0
    for (arg in tmp_args) sorted_args[++arg_count] = arg
    sort_array(sorted_args, arg_count)

    for (i = 1; i <= arg_count; i++) {
        arg = sorted_args[i]
        val = tmp_args[arg] != "" ? tmp_args[arg] : MakeVars[arg]
        s = s sprintf(" %s%s=%s%s", prefix, arg, val, suffix)
    }
    return s
}

# Bubble sort for arrays (No gawk isort in POSIX awk)
# Keys are consecutive integers starting with 1
# Beware!! This is locale based sorting. You will be surprised.
function sort_array(arr, n,    i, j, tmp) {
    for (i = 1; i < n; i++)
        for (j = i + 1; j <= n; j++)
            if (arr[i] > arr[j]) {
                tmp = arr[i]
                arr[i] = arr[j]
                arr[j] = tmp
            }
}

# Filter entries from a multidimensional array where the first subscript
# matches `first_key`. Populates dest[first_sub, second_sub...] = value
function afilter(array, first_key, dest,    key, parts, subkey) {
    split("", dest)
    for (key in array) {
        split(key, parts, SUBSEP)
        if (parts[1] == first_key) {
            subkey = parts[2]
            dest[subkey] = array[key]
        }
    }
}

# Recursive target argument resolver.
# Populates ResolvedReq[tgt, var] and ResolvedOpt[tgt, var]
function resolve_target(tgt, depth, visited, \
                        dep_list, n, i, dep, tmp_req, tmp_opt, var) {

    if (depth > DEPENDENCY_RECURSION_LIMIT || tgt in visited)
        return
    visited[tgt] = 1

    # First, resolve dependencies
    if (TargetDeps[tgt]) {
        n = split(TargetDeps[tgt], dep_list)
        for (i = 1; i <= n; i++) {
            dep = dep_list[i]
            if (dep == "") continue
            resolve_target(dep, depth + 1, visited)

            # Merge required args from dependency
            afilter(ResolvedReq, dep, tmp_req)
            for (var in tmp_req)
                ResolvedReq[tgt, var] = tmp_req[var]

            # Merge optional args from dependency
            afilter(ResolvedOpt, dep, tmp_opt)
            for (var in tmp_opt)
                ResolvedOpt[tgt, var] = tmp_opt[var]
        }
    }

    # Merge this target’s own required args
    afilter(TargetReq, tgt, tmp_req)
    for (var in tmp_req)
        ResolvedReq[tgt, var] = tmp_req[var]

    # Merge this target’s own optional args
    afilter(TargetOpt, tgt, tmp_opt)
    for (var in tmp_opt)
        ResolvedOpt[tgt, var] = tmp_opt[var]
}

# Print a string to stderr
function stderr(s) {
    print s | "cat 1>&2"
    close("cat 1>&2")
}

function warning(s) {
    stderr(F_WARN "WARNING: " s R_ALL)
}

# For debugging -- print array contents
#function aprint(heading, array,    k) {
#    print (heading ":")
#    for (k in array)
#        print "    " k "=" array[k]
#    print "-----------"
#}

# ------------------------------------------------------------------------------
# Directive handlers. Directives are injected via Makefile comments.
# ------------------------------------------------------------------------------

# Pre-resolved Make variables: #@var NAME=VALUE
# Most of these come from output of `make -pn`.
$1 == "#@var" {
    sub(/^[^[:space:]]+[[:space:]]*/, "")  # Remove $1
    split($0, a, "=")
    name = trim(a[1])
    value = trim(a[2])
    MakeVars[name] = unescape(value)
    next
}

$1 == "#@" {
    warning(FILENAME ": Line " FNR " has a bare #@ -- could be a directive typo")
    next
}

# Category for makefile target : #@cat Title
$1 == "#@cat" {
    sub(/^[^[:space:]]+[[:space:]]*/, "")  # Remove $1
    TargetCategory = trim($0)
    # Keep track of ordering of category list
    if (!(TargetCategory in TargetCategorySet))
        TargetCategorySet[TargetCategory] = length(TargetCategorySet) + 1
    next
}

# Category for makefile variable : #@vcat Title
$1 == "#@vcat" {
    sub(/^[^[:space:]]+[[:space:]]*/, "")  # Remove $1
    VarCategory = trim($0)
    # Keep track of ordering of category list
    if (!(VarCategory in VarCategorySet))
        VarCategorySet[VarCategory] = length(VarCategorySet) + 1
    next
}

# Required argument(s) : #@req
$1 == "#@req" {
    for (i = 2; i <= NF; i++)
        parse_arg(expand_vars($i), PendingReq)
    next
}

# Optional argument(s) : #@opt
$1 == "#@opt" {
    for (i = 2; i <= NF; i++)
        parse_arg(expand_vars($i), PendingOpt)
    next
}

# Target documentation.
$1 == "##" {
    line = trim(substr($0, 3))
    doc_lines[++doc_count] = line
    next
}

# Prologue line
$1 == "#+" {
    line = trim(substr($0, 3))
    prologue_text[++PrologueCount] = line
    next
}

# Epilogue line
$1 == "#-" {
    line = trim(substr($0, 3))
    epilogue_text[++EpilogueCount] = line
    next
}

# ------------------------------------------------------------------------------
# Target detection.
# ------------------------------------------------------------------------------

/^[A-Za-z0-9_.\/%-]+:/ {
    if ($0 ~ /[:?+!]*=/) {
        ;         # Pass variable assignments to next pattern
    } else {
        tgt = $1
        sub(/:$/, "", tgt)

        # The "help" target is handled specially because user can't add #@cat for it.
        if (tgt == "help") {
            if (tolower(HELP_CATEGORY) == "none")
                next
            cat = HELP_CATEGORY
        } else
            cat = (TargetCategory) ? TargetCategory : DEFAULT_CATEGORY

        # Keep track of ordering of category list
        if (!(cat in TargetCategorySet))
            TargetCategorySet[cat] = length(TargetCategorySet) + 1

        target_list[cat, ++target_count[cat]] = tgt
        desc_count[cat, tgt] = doc_count
        for (i = 1; i <= doc_count; i++)
            desc_lines[cat, tgt, i] = doc_lines[i]

        # Parse and store dependencies if resolution is enabled
        if (DEPENDENCY_RESOLUTION == "yes") {
            deps_part = substr($0, index($0, ":") + 1)
            sub(/[#;].*$/, "", deps_part) # Remove trailing comment / recipe
            TargetDeps[tgt] = trim(expand_vars(deps_part))
        }

        # Attach pending args to this target
        for (v in PendingReq) TargetReq[tgt, v] = PendingReq[v]
        for (v in PendingOpt) TargetOpt[tgt, v] = PendingOpt[v]

        # reset for next target
        doc_count = 0; RequiredArgs = ""; OptionalArgs = ""
        split("", PendingReq) ; split("", PendingOpt)
    }
}

# ------------------------------------------------------------------------------
# Variable description detection
#   Lines immediately before assignment are ## comments
#   $0 = NAME=VALUE
#   Note that we need to handle the various forms of make assignment.
# ------------------------------------------------------------------------------

/^[A-Za-z0-9_]+[[:space:]]*[:+!?]*=/ {
    if (doc_count == 0) { doc_count = 0; next }

    split($0, a, /[:+!?]*=/)
    name = trim(a[1])
    MakeVars[name] = (name in MakeVars) ? MakeVars[name] : trim(a[2])

    # Keep track of ordering of category list
    if (!(VarCategory in VarCategorySet))
        VarCategorySet[VarCategory] = length(VarCategorySet) + 1

    vars_list[VarCategory, ++var_count[VarCategory]] = name
    var_desc_count[VarCategory, name] = doc_count
    for (i = 1; i <= doc_count; i++)
        var_desc_lines[VarCategory, name, i] = doc_lines[i]

    # Reset for next var
    doc_count = 0
    next
}

# ------------------------------------------------------------------------------
# END block: output everything
# ------------------------------------------------------------------------------

END {
    # Step 1: Resolve and consolidate args for each target ---
    for (cat in target_count) {
        n = target_count[cat]
        for (i = 1; i <= n; i++) {
            tgt = target_list[cat, i]

            split("", visited)
            resolve_target(tgt, 0, visited)

            # Delete optionals overridden by required
            for (var in ResolvedOpt) {
                # Check only entries for this target
                split(var, parts, SUBSEP)
                if (parts[1] == tgt && (tgt SUBSEP parts[2]) in ResolvedReq)
                    delete ResolvedOpt[var]
            }
        }
    }

    # Step 2: Print the prologue.
    print ""
    if (PrologueCount) {
        print_paragraphs(prologue_text, PrologueCount, F_LOG, I_L_LOG, I_R_LOG)
        print HR
        if (HR) print ""
    }

    # Step 3: Sort category list.
    if (sort_mode == "alpha") {
        cat_count = 0
        for (cat in target_count) cat_list[++cat_count] = cat
        sort_array(cat_list, cat_count)
    } else {
        cat_count = length(TargetCategorySet)
        for (cat in TargetCategorySet) cat_list[TargetCategorySet[cat]] = cat
    }

    # Step 4: Print target categories and targets.
    cat_indent_s = spaces(I_L_CAT)

    for (ci = 1; ci <= length(cat_list); ci++) {
        cat = cat_list[ci]
        n = target_count[cat]
        if (n == 0) continue
        printf "%s%s%s%s\n", cat_indent_s, F_CAT, cat, R_ALL

        for (i = 1; i <= n; i++) tlist[i] = target_list[cat, i]
        sort_array(tlist, n)

        for (i = 1; i <= n; i++) {
            tgt = tlist[i]
            if (desc_count[cat, tgt] == 0) continue
            line = sprintf("%s%s%s", F_TGT, tgt, R_ALL) \
                format_args(ResolvedReq, tgt, F_ARG, R_ALL) \
                format_args(ResolvedOpt, tgt, F_ARG "[", "]" R_ALL)
            wrap(line, I_L_TGT, I_L_TGT + length(tgt) + 1, 0)
            if (desc_count[cat, tgt]) {
                for (j = 1; j <= desc_count[cat, tgt]; j++)
                    para_lines[j] = desc_lines[cat, tgt, j]
                print_paragraphs(para_lines, desc_count[cat, tgt], F_DSC, I_L_DSC, I_R_DSC)
            }
        }
        print ""
    }

    # Step 5: Sort the var category list.
    if (sort_mode == "alpha") {
        vcat_count = 0
        for (vcat in var_count) vcat_list[++vcat_count] = vcat
        sort_array(vcat_list, vcat_count)
    } else {
        vcat_count = length(VarCategorySet)
        for (vcat in VarCategorySet) vcat_list[VarCategorySet[vcat]] = vcat
    }

    # Step 6: Print var categories and vars.
    for (ci = 1; ci <= length(vcat_list); ci++) {
        vcat = vcat_list[ci]
        n = var_count[vcat]
        if (n == 0) continue
        printf "%s%s%s%s\n", cat_indent_s, F_CAT, vcat, R_ALL

        for (i = 1; i <= n; i++) vlist[i] = vars_list[vcat, i]
        sort_array(vlist, n)

        var_indent_s = spaces(I_L_TGT)
        for (i = 1; i <= n; i++) {
            v = vlist[i]
            val = (v in MakeVars) ? MakeVars[v] : DEFAULT_VALUE
            printf "%s%s%s%s=%s%s%s\n", var_indent_s, F_ARG, v, R_ALL, F_VAL, val, R_ALL

            delete para_lines
            if (var_desc_count[vcat, v]) {
                for (j = 1; j <= var_desc_count[vcat, v]; j++)
                    para_lines[j] = var_desc_lines[vcat, v, j]
                print_paragraphs(para_lines, var_desc_count[vcat, v], F_DSC, I_L_DSC, I_R_DSC)
            }
        }
        print ""
    }

    # Step 7: Print the epilogue.
    if (EpilogueCount > 0 && HR) print HR
    print_paragraphs(epilogue_text, EpilogueCount, F_LOG, I_L_LOG, I_R_LOG)
    print ""
}

