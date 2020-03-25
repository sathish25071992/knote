let s:KnoteNotebookArrowClose = '▸'
let s:KnoteNotebookArrowOpen = '▾'
let s:KnoteNotebookArrow = [s:KnoteNotebookArrowClose, s:KnoteNotebookArrowOpen]
let s:rootpath = "~/utils/knote/"
let s:KnoteTree = {}

let s:banner = [
\	"Welcome to the KNote - A simple note taking Plugin",
\   " ",
\   "Version: v0.0.1",
\   "by Sathish V (sathish25071992@gmail.com)",
\	"Please select one of note from the left status bar",
\	" ",
\	"Available shortcuts:",
\	"    \\n - Create new note            ",
\	"    \\N - Create new notebook        ",
\	"    \\r - Rename the existing note   ",
\	"    \\d - Delete the existing note   ",
\	"    \\t - To terminal the application" 
\]

function! KnoteCreateNew()
    call inputsave()
    let notebooks = keys(s:KnoteTree)
    let notebookselect = inputlist(notebooks)
    let notebookselect = notebooks[notebookselect]
    let s:KnoteTree[notebookselect].open = 1
    if notebookselect == "General"
        let notebookselect = ""
    endif
    let notename = input('Enter the Note Name: ')
    call inputrestore()
    let newnote = s:rootpath . notebookselect . "/" . notename
    silent execute "cd " . s:rootpath . "/" . notebookselect

    call KnoteMainRender(newnote)
    silent execute "write " . newnote
    call UpdateList()
    call KnoteListRender()
endfunction    

function! KnoteCreateNotebook()
    call inputsave()
    let notebook = input('Enter the notebook name to create: ')
    call inputrestore()
    call mkdir(fnamemodify(s:rootpath.'/'.notebook, ':p'))
    call UpdateList()
    call KnoteListRender()
endfunction

function! KnoteDeleteNote(filename)
    if win_getid() != s:statuswin
        silent execute win_id2win(s:mainwin).'q'
    endif
    call delete(filename)
    echo "Deleted the note ".filename
    call UpdateList()
    call KnoteListRender()
endfunction

function! KnoteRenameNote()
    let bufnm = bufname(bufnr('%'))

    silent call inputsave()
    let name = input('Rename note to: ')
    silent call inputrestore()
   
    call rename(expand('%:p'), name)
    
    silent execute 'edit '.expand('%:p:h') .'/'.name
    silent execute 'bwipeout '.bufnm
    autocmd QuitPre <buffer> :let s:closeflag = 1
    autocmd BufWinLeave <buffer> :call BufferWindowLeave()
    call UpdateList()
    call KnoteListRender()
endfunction

function! UpdateList()
    let l:KnoteTree = {
                \ "General": {
                \   "notes": systemlist("ls -p " . s:rootpath . "|grep -v /$"),
                \   "open": exists("s:KnoteTree['General']")? s:KnoteTree['General'].open: 1}}
    for x in systemlist("ls -p " . s:rootpath . " | grep /$")
        let x = x[:-2]
        let l:KnoteTree[x] = {
                    \ "notes": systemlist("ls -p ".s:rootpath.x."|grep -v /$"),
                    \ "open": exists("s:KnoteTree[x]")? s:KnoteTree[x].open: 0}
    endfor
    unlet s:KnoteTree
    let s:KnoteTree = l:KnoteTree
endfunction

function! KnoteListRender()
    let content = []
    let notetree = deepcopy(s:KnoteTree)
    let save_cursor = getcurpos()

    let curwinbkp = win_getid()
    call win_gotoid(s:statuswin)
    for notebook in keys(notetree)
        let content += [s:KnoteNotebookArrow[notetree[notebook].open].' '.notebook]
        if notetree[notebook].open
            let content += map(notetree[notebook].notes, {_, x -> '  '.x})
        endif
    endfor

    let s:statusbuf = KnoteSetdefaultBuf()

    setlocal noreadonly modifiable
    call setline(1, content)
    setlocal readonly nomodifiable
    call setpos('.', save_cursor)
    let &l:statusline = "Knote v0.0.1"
    call win_gotoid(curwinbkp)
endfunction

function! KnoteSetdefaultBuf()
    setlocal noreadonly modifiable
    setlocal bufhidden=hide
    setlocal buftype=nofile
    setlocal noswapfile
    setlocal foldcolumn=0
    setlocal foldmethod=manual
    setlocal nobuflisted
    setlocal nofoldenable
    setlocal nolist
    setlocal nospell
    setlocal nowrap
    setlocal nonumber
    setlocal norelativenumber
    setlocal hidden

    silent 1,$delete _
    ""normal! zt
    setlocal readonly nomodifiable
    return bufnr('%')
endfunction

function! PrintableList(i, x, width, list, rowoff)
    if a:i >= a:rowoff && a:i - a:rowoff < len(a:list)
        let coloff = a:width / 2 - len(a:list[a:i - a:rowoff]) / 2
        return repeat(" ", coloff - 1).a:list[a:i - a:rowoff]
    else
        return " "
    endif
endfunction

function! KnotePopulateBanner(win, list)
    silent let s:bannerwin = a:win
    silent let s:mainwin = a:win
    silent call win_gotoid(a:win)
    silent let s:bannerbuf = KnoteSetdefaultBuf()
    silent setlocal noreadonly modifiable
    silent silent 1,$delete _
 
    silent let lines = len(a:list)
    silent let height = winheight(0)
    silent let width = winwidth(0)
    silent let rowoff = height / 2 - lines / 2
    silent let filler = repeat("\n", height - 1)

    silent let printable_list = map(split(filler, '\zs'), {i, x -> PrintableList(i, x, width, a:list, rowoff)})
    silent call setline(1, printable_list)
    silent setlocal readonly nomodifiable
    silent let &l:statusline = " "
    silent autocmd BufEnter <buffer> :call win_gotoid(s:statuswin)
    let m = matchadd("Function", '\\[a-zA-Z] ')
    silent call win_gotoid(s:statuswin)
endfunction

let s:closeflag = 0

function! BufferWindowLeave()
    if s:closeflag && win_getid() != s:statuswin
        silent execute 'sbuffer' . s:bannerbuf
        let m = matchadd("Function", '\\[a-zA-Z] ')
        silent let s:closeflag = 0
        silent let s:mainwin = win_getid()
    endif
endfunction

function! KnoteMainRender(line)
    if win_getid() != s:statuswin
        call win_gotoid(s:statuswin)
    endif
    silent execute win_id2win(s:mainwin).'q'
    silent execute 'vertical belowright split ' . a:line
    silent let s:mainwin = win_getid()
    silent execute s:appwinlayout
    silent autocmd QuitPre <buffer> :let s:closeflag = 1
    silent autocmd BufWinLeave <buffer> :call BufferWindowLeave()
endfunction

function! KnoteFindFilePath()
    let lineno = line('.')
    let cnt = 0
    let line = getline(lineno)
    for [notebook, entry] in items(s:KnoteTree)
        let cnt += entry.open? len(entry.notes) + 1: 1
        if line == s:KnoteNotebookArrow[entry.open]." ".notebook
            let path = (notebook == "General")? "/" : notebook."/"
            return {"type": "nb", "path": s:rootpath.path, "notebook": notebook}
        elseif entry.open && count(entry.notes, trim(line)) && lineno <= cnt
            let notebook = (notebook == "General")? "/" : notebook."/"
            return {"type": "n", "path": s:rootpath.notebook, "file": trim(line)}
        endif
    endfor
endfunction

function! KnoteOpen()
    let lineno = line('.')
    let cnt = 0
    silent let line = getline(lineno)

    let res = KnoteFindFilePath()
    if res["type"] == "nb"
        let s:KnoteTree[res["notebook"]].open = !s:KnoteTree[res["notebook"]].open
        call KnoteListRender()
    else
        silent execute "cd ".res["path"]
        call KnoteMainRender(res["path"].res["file"])
    endif
endfunction

function KnoteDelete()
    let line = getline(line('.'))
    let res = KnoteFindFilePath()
    let ret = 0
    if res["type"] == "nb"
        if res["notebook"] == "General"
            echo "Can't delete the default notebook"
            return
        endif
        if delete(fnamemodify(res["path"], ":p"), "d") < 0
            call inputsave()
            let confirm = input("Directory is not empty. Please Type 'yes' to confirm to delete? ")
            if confirm != "yes"
                return
            endif
            call inputrestore()
            let ret = delete(fnamemodify(res["path"], ":p"), "rf")
        endif
        echo " | Removed ".res["path"]
    else
        let ret = delete(fnamemodify(res["path"].res["file"], ":p"))
    endif
    if ret < 0
        echo "Unable to delete note/notebook ".line
        return
    endif
    call UpdateList()
    call KnoteListRender()
endfunction

vertical new
vertical resize 30
execute 'syntax match knoteKeyword "\v' . s:KnoteNotebookArrowClose . '.*$"'
execute 'syntax match knoteKeyword "\v' . s:KnoteNotebookArrowOpen . '.*$"'
highlight link knoteKeyword Directory

setlocal cursorline
command -bang QA :qa
cnoreabbrev <buffer> q QA
nnoremap <buffer> Z :QA<cr>
nnoremap <buffer> ZZ :QA<cr>
nnoremap <buffer> <silent> <CR> :call KnoteOpen()<cr>
nnoremap <buffer> <silent> d :call KnoteDelete()<cr>

let s:statuswin = win_getid()
let s:mainwin = win_getid(winnr('$'))

call UpdateList()
call KnoteListRender()
call KnotePopulateBanner(s:mainwin, s:banner)
let s:appwinlayout = winrestcmd()

silent execute 'cd ' . s:rootpath

nnoremap <silent> <Leader>n :call KnoteCreateNew()<cr>
nnoremap <silent> <Leader>N :call KnoteCreateNotebook()<cr>
nnoremap <silent> <Leader>t :qa<cr>
nnoremap <silent> <Leader>d :call KnoteDeleteNote(expand('%:p'))<cr>
nnoremap <silent> <Leader>r :call KnoteRenameNote()<cr>
