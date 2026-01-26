" Extended Makefile syntax for MakeHelp v!VERSION!.
" See: https://github.com/jin-gizmo/makehelp

syntax match makeHelpDescription "^#[#+-].*$"
syntax match makeHelpDescriptionLeader "^#[#+-]" contained containedin=makeHelpDescription
syntax match makeHelpDirective "^#:.*$"
syntax match makeHelpDirectiveLabel "^#:\w\+" contained containedin=makeHelpDirective

if &background == "dark"
    " This is a bluish theme
    " highlight makeHelpDescription guifg=#8899ff ctermfg=111 gui=italic cterm=italic
    " highlight makeHelpDescriptionLeader guifg=#8899ff ctermfg=111 gui=bold cterm=bold
    " highlight makeHelpDirective guifg=#8899ff ctermfg=111 gui=italic cterm=italic
    " highlight makeHelpDirectiveLabel guifg=#8899ff ctermfg=111 gui=italic cterm=bold

    " This one is amber.
    " highlight makeHelpDescription guifg=#ffaa66 ctermfg=215 gui=italic cterm=italic
    " highlight makeHelpDescriptionLeader guifg=#ffcc88 ctermfg=222 gui=bold cterm=bold
    " highlight makeHelpDirective guifg=#ffaa66 ctermfg=215 gui=italic cterm=italic
    " highlight makeHelpDirectiveLabel guifg=#ffcc88 ctermfg=222 gui=italic cterm=bold

    " This one is purple / magenta.
    highlight makeHelpDescription guifg=#cc88ff ctermfg=141 gui=italic cterm=italic
    highlight makeHelpDescriptionLeader guifg=#ddaaff ctermfg=183 gui=bold cterm=bold
    highlight makeHelpDirective guifg=#cc88ff ctermfg=141 gui=italic cterm=italic
    highlight makeHelpDirectiveLabel guifg=#ddaaff ctermfg=183 gui=bold cterm=bold
else
    " This is a bluish theme
    " highlight makeHelpDescription guifg=#0044cc ctermfg=26 gui=italic cterm=italic
    " highlight makeHelpDescriptionLeader guifg=#0044cc ctermfg=26 gui=bold cterm=bold
    " highlight makeHelpDirective guifg=#0044cc ctermfg=26 gui=italic cterm=italic
    " highlight makeHelpDirectiveLabel guifg=#0044cc ctermfg=26 gui=bold cterm=bold

    " This one is amber.
    " highlight makeHelpDescription guifg=#cc5500 ctermfg=166 gui=italic cterm=italic
    " highlight makeHelpDescriptionLeader guifg=#dd6600 ctermfg=172 gui=bold cterm=bold
    " highlight makeHelpDirective guifg=#cc5500 ctermfg=166 gui=italic cterm=italic
    " highlight makeHelpDirectiveLabel guifg=#dd6600 ctermfg=172 gui=bold cterm=bold

    " This one is purple / magenta.
    highlight makeHelpDescription guifg=#7700cc ctermfg=92 gui=italic cterm=italic
    highlight makeHelpDescriptionLeader guifg=#8800dd ctermfg=98 gui=bold cterm=bold
    highlight makeHelpDirective guifg=#7700cc ctermfg=92 gui=italic cterm=italic
    highlight makeHelpDirectiveLabel guifg=#8800dd ctermfg=98 gui=bold cterm=bold
endif
