nerdtree-git-plugin
===================

A plugin of NERDTree showing git status flags and/or highlights the file names according to the git status. Works with the **LATEST** version of NERDTree.

The original project [git-nerdtree](https://github.com/Xuyuanp/git-nerdtree) will not be maintained any longer.
Also credits to: [@robinfehr](https://github.com/robinfehr/nerdtree-git-plugin) 


![Imgur](http://i.imgur.com/jSCwGjU.gif?1)

## Installation

For Pathogen

`git clone https://github.com/tsony-tsonev/nerdtree-git-plugin.git ~/.vim/bundle/nerdtree-git-plugin`

Now reload the `vim`

For Vundle

`Plugin 'scrooloose/nerdtree'`

`Plugin 'tsony-tsonev/nerdtree-git-plugin'`

For NeoBundle

`NeoBundle 'scrooloose/nerdtree'`

`NeoBundle 'tsony-tsonev/nerdtree-git-plugin'`

For Plug

`Plug 'scrooloose/nerdtree'`

`Plug 'tsony-tsonev/nerdtree-git-plugin'`

## FAQ

> Got error message like `Error detected while processing function
177[2]..178[22]..181[7]..144[9]..142[36]..238[4]..NERDTreeGitStatusRefreshListener[2]..NERDTreeGitStatusRefresh:
line 6:
E484: Can't open file /tmp/vZEZ6gM/1` while nerdtree opening in fish, how to resolve this problem?

This was because that vim couldn't execute `system` function in `fish`. Add `set shell=sh` in your vimrc.

This issue has been fixed.

> How to config custom symbols?

Use this variable to change symbols.

`let g:NERDTreeGitStatusWithFlags = 1`

	```vimscript
	let g:NERDTreeIndicatorMapCustom = {
	    \ "Modified"  : "✹",
	    \ "Staged"    : "✚",
	    \ "Untracked" : "✭",
	    \ "Renamed"   : "➜",
	    \ "Unmerged"  : "═",
	    \ "Deleted"   : "✖",
	    \ "Dirty"     : "✗",
	    \ "Clean"     : "✔︎",
        \ 'Ignored'   : '☒',
	    \ "Unknown"   : "?"
	    \ }
	 ```
> How to enable and customize file colors?

Use this variable to change colors.

`let g:WebDevIconsUnicodeDecorateFolderNodes = 1`

`let g:NERDTreeGitStatusNodeColorization = 1`

```vimscript
let g:NERDTreeColorMapCustom = {
    \ "Modified"  : "#528AB3",  
    \ "Staged"    : "#538B54",  
    \ "Untracked" : "#BE5849",  
    \ "Dirty"     : "#299999",  
    \ "Clean"     : "#87939A"   
    \ }                         
```
> Want to disable the flags or the colors? Just set:

`let g:NERDTreeGitStatusNodeColorization = 0`
OR
`let g:NERDTreeGitStatusWithFlags = 1`

> How to show `ignored` status?

`let g:NERDTreeShowIgnoredStatus = 1` (a heavy feature may cost much more time)

## Credits

*  [scrooloose](https://github.com/scrooloose): Open API for me.
*  [git_nerd](https://github.com/swerner/git_nerd): Where my idea comes from.
*  [PickRelated](https://github.com/PickRelated): Add custom indicators & Review code.
*  [@robinfehr](https://github.com/robinfehr/nerdtree-git-plugin): Where the idea for the colors came from.
