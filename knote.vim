let s:KnoteNotebookArrowClose = '▸'
let s:KnoteNotebookArrowOpen = '▾'
let s:KnoteNotebookArrow = [s:KnoteNotebookArrowClose, s:KnoteNotebookArrowOpen]
let s:rootpath = "~/utils/knote/"

let s:banner = [
\	"Welcome to the KNote - A simple note taking Plugin",
\   " ",
\   "Version: v0.0.1",
\   "by Sathish V (sathish25071992@gmail.com)",
\	"Please select one of note from the left status bar",
\	" ",
\	"Available shortcuts:",
\	"    \\n - Create new note            ",
\	"    \\r - Rename the existing note   ",
\	"    \\d - Delete the existing note   ",
\	"    \\t - To terminal the application" 
\]

let s:KnoteTree = {}

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

function! KnoteDeleteNote()
    if win_getid() != s:statuswin
        let currentfilename = expand('%:p')
        silent execute win_id2win(s:mainwin).'q'
        call delete(currentfilename)
        echo "Deleted the note ".currentfilename
        call UpdateList()
        call KnoteListRender()
    endif
endfunction

function! KnoteRenameNote()
    silent call inputsave()
    let name = input('Rename note to: ')
    silent call inputrestore()
    let bufnm = bufname(bufnr('%'))
   
    call rename(expand('%:p'), name)
    
    silent execute 'edit '.expand('%:p:h') .'/'.name
    silent execute 'bwipeout '.bufnm
    silent autocmd QuitPre <buffer> :let s:closeflag = 1
    silent autocmd BufWinLeave <buffer> :call BufferWindowLeave()

    call UpdateList()
    call KnoteListRender()
endfunction

function! UpdateList()
    let notebooks = systemlist("ls -p " . s:rootpath . " | grep /$")
    call map(notebooks, {_, x -> x[:-2]})
    let notes = systemlist("ls -p " . s:rootpath . " | grep -v /$")
    if empty(s:KnoteTree)
        let firsttime = 1
    else
        let firsttime = 0
    endif
    for x in notebooks
        if firsttime
            let s:KnoteTree[x] = {"notes": systemlist("ls -p ".s:rootpath.x." | grep -v /$"), "open": 0}
        else
            let s:KnoteTree[x].notes = systemlist("ls -p ".s:rootpath.x." | grep -v /$")
        endif
    endfor
    if firsttime
        let s:KnoteTree["General"] = {"notes": notes, "open": 1}
    else
        let s:KnoteTree["General"].notes = notes
    endif
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
    silent call win_gotoid(s:statuswin)
endfunction

let s:closeflag = 0

function! BufferWindowLeave()
    if s:closeflag && win_getid() != s:statuswin
        silent execute 'sbuffer' . s:bannerbuf
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


function! KnoteOpen()
    let lineno = line('.')
    let cnt = 0
    silent let line = getline(lineno)
    silent let notedirectory = s:rootpath

    for [notebook, entry] in items(s:KnoteTree)
        let cnt += 1
        if entry.open
            let cnt += len(entry.notes)
        endif
        if line == s:KnoteNotebookArrow[entry.open]." ".notebook
            let s:KnoteTree[notebook].open = !s:KnoteTree[notebook].open
            let line = "u"
            break
        elseif entry.open && count(entry.notes, trim(line)) && lineno <= cnt
            if notebook == "General"
                let line = s:rootpath . trim(line)
            else
                let line = s:rootpath . notebook . "/" . trim(line)
                silent execute "cd " . notedirectory . "/" . notebook
            endif
            break
        endif
    endfor
    if line == "u"
        call KnoteListRender()
        return
    endif
    call KnoteMainRender(line)
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

let s:statuswin = win_getid()
let s:mainwin = win_getid(winnr('$'))

call UpdateList()
call KnoteListRender()
call KnotePopulateBanner(s:mainwin, s:banner)
let s:appwinlayout = winrestcmd()

silent execute 'cd ' . s:rootpath

nnoremap <silent> <Leader>n :call KnoteCreateNew()<cr>
nnoremap <silent> <Leader>t :qa<cr>
nnoremap <silent> <Leader>d :call KnoteDeleteNote()<cr>
nnoremap <silent> <Leader>r :call KnoteRenameNote()<cr>
