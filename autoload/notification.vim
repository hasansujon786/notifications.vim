let s:FLOATING = SpaceVim#api#import('neovim#floating')
let s:BUFFER = SpaceVim#api#import('vim#buffer')

if !exists('g:notification_sound_cmd')
    let g:notification_sound_cmd = ''
endif

let s:messages = []

let s:shown = []

let s:buffer_id = nvim_create_buf(v:false, v:false)
let s:timer_id = -1

let s:win_is_open = v:false

function! notification#messages()
    return s:messages
endfunction

function! notification#open(msg)
    try
        call s:notification_create(a:msg)
    catch
        let s:shown = []
        let s:win_is_open = v:false
        call s:notification_create(a:msg)
    endtry
endfunction

function! s:notification_create(msg)
    if !s:win_is_open && g:notification_sound_cmd != ''
        let timer_id = timer_start(2, function('s:sound_play'), {'repeat' : 1})
    endif

    call s:notification(a:msg, 'Notification')
endfunction

function! s:sound_play(...) abort
    call system(g:notification_sound_cmd)
endfunction

function! s:close(...) abort
    if len(s:shown) == 1
        try
            noautocmd call nvim_win_close(s:notification_winid, v:true)
            let s:win_is_open = v:false
        catch /^Vim\%((\a\+)\)\=:E5555/
            let s:win_is_open = v:false
        endtry
    endif
    if !empty(s:shown)
        call add(s:messages, join(remove(s:shown, 0)[1:], ' '))
    endif
endfunction

" Code from bairui@#vim.freenode
" https://gist.github.com/3322468
function! s:Flatten(list)
  let val = []
  for elem in a:list
    if type(elem) == type([])
      call extend(val, s:Flatten(elem))
    else
      call add(val, elem)
    endif
    unlet elem
  endfor
  return val
endfunction

function! s:notification(msg, color) abort
    call add(s:shown, [''] + a:msg)
    let lines = s:Flatten(s:shown)
    let max_width = max(map(deepcopy(lines), 'strwidth(v:val)'))

    if s:win_is_open
        call s:FLOATING.win_config(s:notification_winid,
                    \ {
                    \ 'relative': 'editor',
                    \ 'focusable': 0,
                    \ 'width'   : max_width + 4,
                    \ 'height'  : 1 + len(lines),
                    \ 'row': 2,
                    \ 'col': &columns - max_width - 6
                    \ })
    else
        let s:notification_winid =  s:FLOATING.open_win(s:buffer_id, v:false,
                    \ {
                    \ 'relative': 'editor',
                    \ 'focusable': 0,
                    \ 'width'   : max_width + 4,
                    \ 'height'  : 1 + len(lines),
                    \ 'row': 2,
                    \ 'col': &columns - max_width - 6
                    \ })
        let s:win_is_open = v:true
    endif
    call s:BUFFER.buf_set_lines(s:buffer_id, 0 , -1, 0, lines)
    call setbufvar(s:buffer_id, '&winhighlight', 'Normal:' . a:color)
    call setbufvar(s:buffer_id, '&number', 0)
    call setbufvar(s:buffer_id, '&relativenumber', 0)
    call setbufvar(s:buffer_id, '&cursorline', 0)
    call setbufvar(s:buffer_id, '&buftype', 'nofile')
    call setbufvar(s:buffer_id, '&filetype', 'popup_notification')
    let s:timer_id = timer_start(3000, function('s:close'), {'repeat' : 1})
endfunction


