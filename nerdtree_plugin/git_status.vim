" ============================================================================
" File:        git_status.vim
" Description: plugin for NERD Tree that provides git status support
" Maintainer:  Xuyuan Pang <xuyuanp at gmail dot com>
" Last Change: 4 Apr 2014
" License:     This program is free software. It comes without any warranty,
"              to the extent permitted by applicable law. You can redistribute
"              it and/or modify it under the terms of the Do What The Fuck You
"              Want To Public License, Version 2, as published by Sam Hocevar.
"              See http://sam.zoy.org/wtfpl/COPYING for more details.
" ============================================================================
if exists('g:loaded_nerdtree_git_status')
    finish
endif
let g:loaded_nerdtree_git_status = 1

if !exists('g:NERDTreeShowGitStatus')
    let g:NERDTreeShowGitStatus = 1
endif

if g:NERDTreeShowGitStatus == 0
    finish
endif

if !exists('g:NERDTreeGitStatusNodeColorization')
    let g:NERDTreeGitStatusNodeColorization = 0
endif

if !exists('g:NERDTreeMapNextHunk')
    let g:NERDTreeMapNextHunk = ']c'
endif

if !exists('g:NERDTreeMapPrevHunk')
    let g:NERDTreeMapPrevHunk = '[c'
endif

if !exists('g:NERDTreeUpdateOnWrite')
    let g:NERDTreeUpdateOnWrite = 1
endif

if !exists('g:NERDTreeUpdateOnCursorHold')
    let g:NERDTreeUpdateOnCursorHold = 1
endif

if !exists('g:NERDTreeShowIgnoredStatus')
    let g:NERDTreeShowIgnoredStatus = 0
endif

if !exists('g:NERDTreeGitStatusIndicatorMap')
    if g:NERDTreeGitStatusWithFlags == 1
        let s:NERDTreeIndicatorMap = {
                \ 'Modified'  : '✹',
                \ 'Staged'    : '✚',
                \ 'Untracked' : '✭',
                \ 'Renamed'   : '➜',
                \ 'Unmerged'  : '═',
                \ 'Deleted'   : '✖',
                \ 'Dirty'     : '✗',
                \ 'Clean'     : '✔︎',
                \ 'Ignored'   : '☒',
                \ 'Unknown'   : '?'
                \ }
    else
        let s:NERDTreeIndicatorMap = {
                \ 'Modified'  : nr2char(8201),
                \ 'Staged'    : nr2char(8239),
                \ 'Untracked' : nr2char(8199),
                \ 'Renamed'   : nr2char(8200),
                \ 'Unmerged'  : nr2char(8287),
                \ 'Deleted'   : nr2char(8195),
                \ 'Dirty'     : nr2char(8202),
                \ 'Clean'     : nr2char(8196),
                \ 'Ignored'   : nr2char(8197),
                \ 'Unknown'   : nr2char(8198)
                \ }
       " Hide the backets
        augroup webdevicons_conceal_nerdtree_brackets
          au!
          autocmd FileType nerdtree syntax match hideBracketsInNerdTree "\]" contained conceal containedin=ALL
          autocmd FileType nerdtree syntax match hideBracketsInNerdTree ".\[" contained conceal containedin=ALL
          autocmd FileType nerdtree setlocal conceallevel=3
          autocmd FileType nerdtree setlocal concealcursor=nvic
        augroup END
    endif
endif

if !exists('g:NERDTreeGitStatusWithFlags')
    let g:NERDTreeGitStatusWithFlags = 1
endif

if !exists('g:NERDTreeColorMapCustom')
    let g:NERDTreeColorMapCustom = {
        \ "Modified"  : "#528AB3",
        \ "Staged"    : "#538B54",
        \ "Untracked" : "#BE5849",
        \ "Dirty"     : "#299999",
        \ "Clean"     : "#87939A",
        \ "Ignored"   : "#808080"
        \ }
endif

function! NERDTreeGitStatusRefreshListener(event)
    if !exists('b:NOT_A_GIT_REPOSITORY')
        call g:NERDTreeGitStatusRefresh()
    endif
    let l:path = a:event.subject
    let l:flag = g:NERDTreeGetGitStatusPrefix(l:path)
    call l:path.flagSet.clearFlags('git')
    if l:flag !=# ''
        call l:path.flagSet.addFlag('git', l:flag)
    endif
endfunction

" FUNCTION: g:NERDTreeGitStatusRefresh() {{{2
" refresh cached git status
function! g:NERDTreeGitStatusRefresh()
    let b:NERDTreeCachedGitFileStatus = {}
    let b:NERDTreeCachedGitDirtyDir   = {}
    let b:NOT_A_GIT_REPOSITORY        = 1

    let l:root = fnamemodify(b:NERDTree.root.path.str(), ":p:S")
    let l:gitcmd = 'git -c color.status=false status --untracked-files=all -s'
    if g:NERDTreeShowIgnoredStatus
        let l:gitcmd = l:gitcmd . ' --ignored'
    endif
    if exists('g:NERDTreeGitStatusIgnoreSubmodules')
        let l:gitcmd = l:gitcmd . ' --ignore-submodules'
        if g:NERDTreeGitStatusIgnoreSubmodules ==# 'all' || g:NERDTreeGitStatusIgnoreSubmodules ==# 'dirty' || g:NERDTreeGitStatusIgnoreSubmodules ==# 'untracked'
            let l:gitcmd = l:gitcmd . '=' . g:NERDTreeGitStatusIgnoreSubmodules
        endif
    endif
    let l:statusesStr = system(l:gitcmd . ' ' . l:root)
    let l:statusesSplit = split(l:statusesStr, '\n')
    if l:statusesSplit != [] && l:statusesSplit[0] =~# 'fatal:.*'
        let l:statusesSplit = []
        return
    endif
    let b:NOT_A_GIT_REPOSITORY = 0

    for l:statusLine in l:statusesSplit
        " cache git status of files
        let l:pathStr = substitute(l:statusLine, '...', '', '')
        let l:pathSplit = split(l:pathStr, ' -> ')
        if len(l:pathSplit) == 2
            call s:NERDTreeCacheDirtyDir(l:pathSplit[0])
            let l:pathStr = l:pathSplit[1]
        else
            let l:pathStr = l:pathSplit[0]
        endif
        let l:pathStr = s:NERDTreeTrimDoubleQuotes(l:pathStr)
        if l:pathStr =~# '\.\./.*'
            continue
        endif
        let l:statusKey = s:NERDTreeGetFileGitStatusKey(l:statusLine[0], l:statusLine[1])
        let b:NERDTreeCachedGitFileStatus[fnameescape(l:pathStr)] = l:statusKey

        if l:statusKey == 'Ignored'
            if isdirectory(l:pathStr)
                let b:NERDTreeCachedGitDirtyDir[fnameescape(l:pathStr)] = l:statusKey
            endif
        else
            call s:NERDTreeCacheDirtyDir(l:pathStr)
        endif
    endfor
endfunction

function! s:NERDTreeCacheDirtyDir(pathStr)
    " cache dirty dir
    let l:dirtyPath = s:NERDTreeTrimDoubleQuotes(a:pathStr)
    if l:dirtyPath =~# '\.\./.*'
        return
    endif
    let l:dirtyPath = substitute(l:dirtyPath, '/[^/]*$', '/', '')
    while l:dirtyPath =~# '.\+/.*' && has_key(b:NERDTreeCachedGitDirtyDir, fnameescape(l:dirtyPath)) == 0
        let b:NERDTreeCachedGitDirtyDir[fnameescape(l:dirtyPath)] = 'Dirty'
        let l:dirtyPath = substitute(l:dirtyPath, '/[^/]*/$', '/', '')
    endwhile
endfunction

function! s:NERDTreeTrimDoubleQuotes(pathStr)
    let l:toReturn = substitute(a:pathStr, '^"', '', '')
    let l:toReturn = substitute(l:toReturn, '"$', '', '')
    return l:toReturn
endfunction

" FUNCTION: g:NERDTreeGetGitStatusPrefix(path) {{{2
" return the indicator of the path
" Args: path
let s:GitStatusCacheTimeExpiry = 2
let s:GitStatusCacheTime = 0
function! g:NERDTreeGetGitStatusPrefix(path)
    if localtime() - s:GitStatusCacheTime > s:GitStatusCacheTimeExpiry
        let s:GitStatusCacheTime = localtime()
        call g:NERDTreeGitStatusRefresh()
    endif
    let l:pathStr = a:path.str()
    let l:pathSlash = '/'
    if nerdtree#runningWindows()
        if exists('+shellslash') && &shellslash
            let l:pathSlash = '/'
        endif
        let l:pathSlash = '\'
    endif
    let l:cwd = b:NERDTree.root.path.str() . l:pathSlash
    if nerdtree#runningWindows()
        let l:pathStr = a:path.WinToUnixPath(l:pathStr)
        let l:cwd = a:path.WinToUnixPath(l:cwd)
    endif
    let l:cwd = substitute(l:cwd, '\~', '\\~', 'g')
    let l:pathStr = substitute(l:pathStr, l:cwd, '', '')
    let l:statusKey = ''
    if a:path.isDirectory
        let l:statusKey = get(b:NERDTreeCachedGitDirtyDir, fnameescape(l:pathStr . '/'), '')
    else
        let l:statusKey = get(b:NERDTreeCachedGitFileStatus, fnameescape(l:pathStr), '')
    endif
    return s:NERDTreeGetIndicator(l:statusKey)
endfunction

" FUNCTION: s:NERDTreeGetCWDGitStatus() {{{2
" return the indicator of cwd
function! g:NERDTreeGetCWDGitStatus()
    if b:NOT_A_GIT_REPOSITORY
        return ''
    elseif b:NERDTreeCachedGitDirtyDir == {} && b:NERDTreeCachedGitFileStatus == {}
        return s:NERDTreeGetIndicator('Clean')
    endif
    return s:NERDTreeGetIndicator('Dirty')
endfunction

function! s:NERDTreeGetIndicator(statusKey)
    if exists('g:NERDTreeIndicatorMapCustom') && g:NERDTreeGitStatusWithFlags == 1
        let l:indicator = get(g:NERDTreeIndicatorMapCustom, a:statusKey, '')
        if l:indicator !=# ''
            return l:indicator
        endif
    endif
    let l:indicator = get(s:NERDTreeIndicatorMap, a:statusKey, '')
    if l:indicator !=# ''
        return l:indicator
    endif
    return ''
endfunction

function! s:NERDTreeGetFileGitStatusKey(us, them)
    if a:us ==# '?' && a:them ==# '?'
        return 'Untracked'
    elseif a:us ==# ' ' && a:them ==# 'M'
        return 'Modified'
    elseif a:us =~# '[MAC]'
        return 'Staged'
    elseif a:us ==# 'R'
        return 'Renamed'
    elseif a:us ==# 'U' || a:them ==# 'U' || a:us ==# 'A' && a:them ==# 'A' || a:us ==# 'D' && a:them ==# 'D'
        return 'Unmerged'
    elseif a:them ==# 'D'
        return 'Deleted'
    elseif a:us ==# '!'
        return 'Ignored'
    else
        return 'Unknown'
    endif
endfunction

" FUNCTION: s:jumpToNextHunk(node) {{{2
function! s:jumpToNextHunk(node)
    let l:position = search('\[[^{RO}].*\]', '')
    if l:position
        call nerdtree#echo('Jump to next hunk ')
    endif
endfunction

" FUNCTION: s:jumpToPrevHunk(node) {{{2
function! s:jumpToPrevHunk(node)
    let l:position = search('\[[^{RO}].*\]', 'b')
    if l:position
        call nerdtree#echo('Jump to prev hunk ')
    endif
endfunction

" Function: s:SID()   {{{2
function s:SID()
    if !exists('s:sid')
        let s:sid = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
    endif
    return s:sid
endfun

" FUNCTION: s:NERDTreeGitStatusKeyMapping {{{2
function! s:NERDTreeGitStatusKeyMapping()
    let l:s = '<SNR>' . s:SID() . '_'

    call NERDTreeAddKeyMap({
        \ 'key': g:NERDTreeMapNextHunk,
        \ 'scope': 'Node',
        \ 'callback': l:s.'jumpToNextHunk',
        \ 'quickhelpText': 'Jump to next git hunk' })

    call NERDTreeAddKeyMap({
        \ 'key': g:NERDTreeMapPrevHunk,
        \ 'scope': 'Node',
        \ 'callback': l:s.'jumpToPrevHunk',
        \ 'quickhelpText': 'Jump to prev git hunk' })

endfunction

augroup nerdtreegitplugin
    autocmd CursorHold * silent! call s:CursorHoldUpdate()
augroup END
" FUNCTION: s:CursorHoldUpdate() {{{2
function! s:CursorHoldUpdate()
    if g:NERDTreeUpdateOnCursorHold != 1
        return
    endif

    if !g:NERDTree.IsOpen()
        return
    endif

    " Do not update when a special buffer is selected
    if !empty(&l:buftype)
        return
    endif

    let l:winnr = winnr()
    let l:altwinnr = winnr('#')

    call g:NERDTree.CursorToTreeWin()
    call b:NERDTree.root.refreshFlags()
    call NERDTreeRender()

    exec l:altwinnr . 'wincmd w'
    exec l:winnr . 'wincmd w'
endfunction

augroup nerdtreegitplugin
    autocmd BufWritePost * call s:FileUpdate(expand('%:p'))
augroup END
" FUNCTION: s:FileUpdate(fname) {{{2
function! s:FileUpdate(fname)
    if g:NERDTreeUpdateOnWrite != 1
        return
    endif

    if !g:NERDTree.IsOpen()
        return
    endif

    let l:winnr = winnr()
    let l:altwinnr = winnr('#')

    call g:NERDTree.CursorToTreeWin()
    let l:node = b:NERDTree.root.findNode(g:NERDTreePath.New(a:fname))
    if l:node == {}
        return
    endif
    call l:node.refreshFlags()
    let l:node = l:node.parent
    while !empty(l:node)
        call l:node.refreshDirFlags()
        let l:node = l:node.parent
    endwhile

    call NERDTreeRender()

    exec l:altwinnr . 'wincmd w'
    exec l:winnr . 'wincmd w'
endfunction

augroup AddHighlighting
    autocmd FileType nerdtree call s:AddHighlighting()
augroup END
function! s:AddHighlighting()
    let l:synmap = {
                \ 'NERDTreeGitStatusModified'    : s:NERDTreeGetIndicator('Modified'),
                \ 'NERDTreeGitStatusStaged'      : s:NERDTreeGetIndicator('Staged'),
                \ 'NERDTreeGitStatusUntracked'   : s:NERDTreeGetIndicator('Untracked'),
                \ 'NERDTreeGitStatusRenamed'     : s:NERDTreeGetIndicator('Renamed'),
                \ 'NERDTreeGitStatusIgnored'     : s:NERDTreeGetIndicator('Ignored'),
                \ 'NERDTreeGitStatusDirDirty'    : s:NERDTreeGetIndicator('Dirty'),
                \ 'NERDTreeGitStatusDirClean'    : s:NERDTreeGetIndicator('Clean')
                \ }

    for l:name in keys(l:synmap)
   		if g:NERDTreeGitStatusNodeColorization == 1
          exec 'syn match '.l:name.' ".*'.l:synmap[l:name].'.*" containedin=NERDTreeDir'
          exec 'syn match '.l:name.' ".*'.l:synmap[l:name].'.*" containedin=NERDTreeFile'
          exec 'syn match '.l:name.' ".*'.l:synmap[l:name].'.*" containedin=NERDTreeExecFile'
        endif
      	if g:NERDTreeGitStatusWithFlags == 1
        	exec 'syn match ' . l:name . ' #' . escape(l:synmap[l:name], '~') . '# containedin=NERDTreeFlags'
        endif
    endfor

    " custom color mapping is of simple type (only one color) 
    if g:NERDTreeColorMapCustom["Modified"][0] == "#"
        execute('hi NERDTreeGitModified guifg=' . g:NERDTreeColorMapCustom["Modified"])
        execute('hi NERDTreeGitStaged guifg=' . g:NERDTreeColorMapCustom["Staged"])
        execute('hi NERDTreeGitUntracked guifg=' . g:NERDTreeColorMapCustom["Untracked"])
        execute('hi NERDTreeGitDirDirty guifg=' . g:NERDTreeColorMapCustom["Dirty"])
        execute('hi NERDTreeGitDirClean guifg=' . g:NERDTreeColorMapCustom["Clean"])
        execute('hi NERDTreeGitIgnored guifg=' . g:NERDTreeColorMapCustom["Ignored"])
    else " custom color mapping is of type array [guifg, ctermfg, guibg, ctermbg]
        execute('hi NERDTreeGitModified guifg=' . g:NERDTreeColorMapCustom["Modified"][0] . ' ctermfg=' . g:NERDTreeColorMapCustom["Modified"][1] . ' guibg=' . g:NERDTreeColorMapCustom["Modified"][2] . ' ctermbg=' . g:NERDTreeColorMapCustom["Modified"][3])
        execute('hi NERDTreeGitStaged guifg=' . g:NERDTreeColorMapCustom["Staged"][0] . ' ctermfg=' . g:NERDTreeColorMapCustom["Staged"][1] . ' guibg=' . g:NERDTreeColorMapCustom["Staged"][2] . ' ctermbg=' . g:NERDTreeColorMapCustom["Staged"][3])
        execute('hi NERDTreeGitUntracked guifg=' . g:NERDTreeColorMapCustom["Untracked"][0] . ' ctermfg=' . g:NERDTreeColorMapCustom["Untracked"][1] . ' guibg=' . g:NERDTreeColorMapCustom["Untracked"][2] . ' ctermbg=' . g:NERDTreeColorMapCustom["Untracked"][3])
        execute('hi NERDTreeGitDirDirty guifg=' . g:NERDTreeColorMapCustom["Dirty"][0] . ' ctermfg=' . g:NERDTreeColorMapCustom["Dirty"][1] . ' guibg=' . g:NERDTreeColorMapCustom["Dirty"][2] . ' ctermbg=' . g:NERDTreeColorMapCustom["Dirty"][3])
        execute('hi NERDTreeGitDirClean guifg=' . g:NERDTreeColorMapCustom["Clean"][0] . ' ctermfg=' . g:NERDTreeColorMapCustom["Clean"][1] . ' guibg=' . g:NERDTreeColorMapCustom["Clean"][2] . ' ctermbg=' . g:NERDTreeColorMapCustom["Clean"][3])
        execute('hi NERDTreeGitIgnored guifg=' . g:NERDTreeColorMapCustom["Ignored"][0] . ' ctermfg=' . g:NERDTreeColorMapCustom["Ignored"][1] . ' guibg=' . g:NERDTreeColorMapCustom["Ignored"][2] . ' ctermbg=' . g:NERDTreeColorMapCustom["Ignored"][3])
    endif
   
    hi def link NERDTreeGitStatusModified NERDTreeGitModified
    hi def link NERDTreeGitStatusStaged NERDTreeGitStaged
    hi def link NERDTreeGitStatusUntracked NERDTreeGitUntracked
    hi def link NERDTreeGitStatusDirDirty NERDTreeGitDirDirty
    hi def link NERDTreeGitStatusDirClean NERDTreeGitDirClean
    hi def link NERDTreeGitStatusIgnored NERDTreeGitIgnored

endfunction

function! s:SetupListeners()
    call g:NERDTreePathNotifier.AddListener('init', 'NERDTreeGitStatusRefreshListener')
    call g:NERDTreePathNotifier.AddListener('refresh', 'NERDTreeGitStatusRefreshListener')
    call g:NERDTreePathNotifier.AddListener('refreshFlags', 'NERDTreeGitStatusRefreshListener')
endfunction

if g:NERDTreeShowGitStatus && executable('git')
    call s:NERDTreeGitStatusKeyMapping()
    call s:SetupListeners()
endif
