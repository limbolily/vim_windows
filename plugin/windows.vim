" Vim global plugin for managing windows.
" Maintainer: Limbo <limbonavel@gmail.com>
" License: This file is placed in the public domain.

if exists("g:loaded_windows")
  finish
endif
let g:loaded_windows = 1

" save compatible-options
let s:save_cpo = &cpo
" set vim default compatible-options
set cpo&vim

"This plugin manage windows.It dividds vim to 2 kind of windows:
"1.Edition Windows:The main windows,contain text to edit with fixed width
"(default to 80).
"2.Navigation Windows:navigation windows is at the left of the vim window.If
"contain more than one navigation window,they will be split horizontally with
"same height.

"edition window width
let g:edition_window_width = 80

"monitor window height ratio
let g:monitor_window_height_ratio = 0.3

"windows counter,identifies window uniquely
let s:windows_counter = 0

"EditionSubWindow class
let s:EditionSubWindow = {
  \'window_id_' : 0}
"Create EditionSubWindow object
function! s:EditionSubWindow.New()
  let new_edition_sub_window = copy(self)
  return new_edition_sub_window
endfunction

"EditionWindow class
let s:EditionWindow = {
  \'sub_windows_' : []}
"Create EditionWindow object
function! s:EditionWindow.New()
  let new_edition_window = deepcopy(self)
  return new_edition_window
endfunction
"EditionWindow container
let s:edition_windows = []

"NavigationWindow class
"Create NavigationWindow object
let s:NavigationWindow = {
  \'window_id_' : 0}
function! s:NavigationWindow.New()
  let new_navigation_window = copy(self)
  return new_navigation_window
endfunction
"NavigationWindow container
let s:navigation_windows = []

"Put the buffer to navigation window.
"If navigation_id is given,put the buffer to the specific navigation window.
"The navigation_id ordered from top to bottom.
"If navigation_id is not given or  the navigation window specified by
"navigation_id doesn't exist,Create a new navigation window to show the buffer.
function! ShowInNavigationWindows(buffer_name, ...)
  let l:number_of_navigations = len(s:navigation_windows)
  if (a:0 != 0)
    let l:navigation_id = a:1
  else
    let l:navigation_id = -1
  endif
  if (l:number_of_navigations <= 0)
    call s:MoveToWindowByWindowID(
      \s:edition_windows[0].sub_windows_[0].window_id_)
    split
    let l:new_window_id = s:windows_counter
    call s:MoveToWindowByWindowID(l:new_window_id)
    wincmd H
    execute "buffer! " a:buffer_name
    let l:navigation_window = s:NavigationWindow.New()
    let l:navigation_window.window_id_ = l:new_window_id
    call add(s:navigation_windows, l:navigation_window)
  elseif (l:navigation_id < 0 || l:navigation_id >= l:number_of_navigations)
    call s:MoveToWindowByWindowID(s:navigation_windows[-1].window_id_)
    belowright split
    let l:new_window_id = s:windows_counter
    call s:MoveToWindowByWindowID(l:new_window_id)
    execute "buffer! " . a:buffer_name
    let l:navigation_window = s:NavigationWindow.New()
    let l:navigation_window.window_id_ = l:new_window_id
    call add(s:navigation_windows, l:navigation_window)
  else
    call s:MoveToWindowByWindowID(
      \s:navigation_windows[l:navigation_id].window_id_)
    execute "buffer! " . a:buffer_name
  endif

  call NormalizeWindowsSize()
endfunction

function! TestShowInNavigationWindows()
  NERDTree
  quit
  call ShowInNavigationWindows("NERD_tree_1")
  TlistToggle
  wincmd h
  wincmd h
  setlocal bufhidden=hide
  quit
  call ShowInNavigationWindows("__Tag_List__")
  silent vsplit __TEST__
  setlocal buftype=nofile
  quit
  call ShowInNavigationWindows("__TEST__")
endfunction

"Put the buffer to edition windows.
"If edition_id and edition_sub_id are given,put the buffer to the specific
"edition window.The edition_id orderd from left to right in vim windows, and
"the edition_sub_id ordered from top to bottom in particular edition window
"specified by edition_id.
"If edition_id not given or the navigation window specified by navigation_id
"doesn't exist,create a new navigation window;if edition_sub_id is not given
"or the sub edition window specified by edition_sub_id is not exist,Create a
"new sub edition navigation window to show the buffer.
function! ShowInEditionWindows(buffer_name, ...)
  let l:edition_id = -1
  let l:edition_sub_id = -1
  if (a:0 >= 1)
    let l:edition_id = a:1
  endif
  if (a:0 >= 2)
    let l:edition_sub_id = a:2
  endif

  if (l:edition_id >= 0 && l:edition_id < len(s:edition_windows))
    let l:edition_window = s:edition_windows[l:edition_id]
    if (l:edition_sub_id >= 0 &&
       \l:edition_sub_id < len(l:edition_window.sub_windows_))
      "Just show the buffer
      let l:sub_window = l:edition_window.sub_windows_[l:edition_sub_id]
      call s:MoveToWindowByWindowID(l:sub_window.window_id_)
      execute "buffer! " a:buffer_name
    else
      "Create new edition sub window
      let l:last_sub_window = l:edition_window.sub_windows_[-1]
      call s:MoveToWindowByWindowID(l:last_sub_window.window_id_)
      belowright split
      let l:new_window_id = s:windows_counter
      call s:MoveToWindowByWindowID(l:new_window_id)
      execute "buffer! " . a:buffer_name
      let l:edition_sub_window = s:EditionSubWindow.New()
      let l:edition_sub_window.window_id_ = l:new_window_id
      call add(l:edition_window.sub_windows_, l:edition_sub_window)
    endif
  else
    "create new edition window
    let l:edition_total_width = s:GetEditionWindowsTotalWidth()
    execute "belowright vsplit " . a:buffer_name
    let l:new_window_id = s:windows_counter
    call s:MoveToWindowByWindowID(l:new_window_id)
    wincmd L
    let l:line_number_length = 0
    if (&number)
      let l:line_number_length = strlen(line('$'))
    endif
    let l:new_window_width = g:edition_window_width + l:line_number_length + 1
    if (l:edition_total_width + l:new_window_width + 1 >= &columns - 2)
      "Has no enough window width,quit the new window
      quit
    else
      let l:new_edition_window = s:EditionWindow.New()
      let l:new_edition_sub_window = s:EditionSubWindow.New()
      let l:new_edition_sub_window.window_id_ = l:new_window_id
      call add(l:new_edition_window.sub_windows_, l:new_edition_sub_window)
      call add(s:edition_windows, l:new_edition_window)
    endif
  endif

  call NormalizeWindowsSize()

endfunction

function! TestShowInEditionWindows()
  silent vsplit _TEST_EDITION_1_
  setlocal buftype=nofile
  setlocal bufhidden=hide
  execute "normal iedition1"
  quit
  call ShowInEditionWindows("_TEST_EDITION_1_")
  silent vsplit _TEST_EDITION_2_
  setlocal buftype=nofile
  setlocal bufhidden=hide
  execute "normal iedition2"
  quit
  call ShowInEditionWindows("_TEST_EDITION_2_")
  silent vsplit _TEST_EDITION_3_
  setlocal buftype=nofile
  setlocal bufhidden=hide
  execute "normal iedition3"
  quit
  call ShowInEditionWindows("_TEST_EDITION_3_", 0)
  silent vsplit _TEST_EDITION_4_
  setlocal buftype=nofile
  setlocal bufhidden=hide
  execute "normal iedition4"
  quit
  call ShowInEditionWindows("_TEST_EDITION_4_", 1, 1)
  silent vsplit _TEST_EDITION_5_
  setlocal buftype=nofile
  setlocal bufhidden=hide
  execute "normal iedition5"
  quit
  call ShowInEditionWindows("_TEST_EDITION_5_", 1, 1)
endfunction

"Normalize all edition navigation monitor windows.
function! NormalizeWindowsSize()
  let l:number_of_navigations = len(s:navigation_windows)
  "Normalize edition windows
  let l:number_of_editions = len(s:edition_windows)
  let l:edition_total_width = &columns
  if (l:number_of_navigations <= 0)
    let l:edition_window_width = (&columns - l:number_of_editions) /
                                 \l:number_of_editions
    for l:edition_window in s:edition_windows
      let l:sub_window = l:edition_window.sub_windows_[0]
      call s:MoveToWindowByWindowID(l:sub_window.window_id_)
      execute "vertical resize " . l:edition_window_width
    endfor
  else
    let l:edition_total_width = s:GetEditionWindowsTotalWidth()

    if (l:edition_total_width < &columns - 2)
      "Has enough window width,normalize all edition windows
      for i in range(len(s:edition_windows) - 1, 0, -1)
        let l:edition_window = s:edition_windows[i]
        let l:max_line_length = 0
        for l:edition_sub_window in l:edition_window.sub_windows_
          call s:MoveToWindowByWindowID(l:edition_sub_window.window_id_)
          let l:line_number_length = 0
          if (&number)
            let l:line_number_length = strlen(line('$'))
          endif
          if l:line_number_length > l:max_line_length
            let l:max_line_length = l:line_number_length
          endif
        endfor

        "extra width for seperator
        let l:edition_window_width = l:max_line_length +
                                    \g:edition_window_width + 1
        for l:edition_sub_window in l:edition_window.sub_windows_
          call s:MoveToWindowByWindowID(l:edition_sub_window.window_id_)
          execute "vertical resize " . l:edition_window_width
          set winfixwidth
        endfor
      endfor

      "Normalize navigation windows
      let l:navigation_width = &columns - l:edition_total_width - 1
      let l:navigation_height = (&lines - l:number_of_navigations) /
                                \l:number_of_navigations
      for l:navigation_window in s:navigation_windows
        call s:MoveToWindowByWindowID(l:navigation_window.window_id_)
        set winwidth=1
        execute "resize " . l:navigation_height
        execute "vertical resize " . l:navigation_width
      endfor
    endif
  endif

endfunction

function! s:GetEditionWindowsTotalWidth()
  let l:edition_total_width = 0
  for l:edition_window in s:edition_windows
    let l:max_line_length = 0
    for l:edition_sub_window in l:edition_window.sub_windows_
      call s:MoveToWindowByWindowID(l:edition_sub_window.window_id_)
      let l:line_number_length = 0
      if (&number)
        let l:line_number_length = strlen(line('$'))
      endif
      if l:line_number_length > l:max_line_length
        let l:max_line_length = l:line_number_length
      endif
    endfor

    "extra width for line number space and seperator
    let l:edition_total_width += l:max_line_length +
                                \g:edition_window_width + 2
  endfor
  let l:edition_total_width -= 1
  return l:edition_total_width
endfunction

function s:CheckNavigationWindows()
  let number_of_removed = 0
  for i in range(len(s:navigation_windows))
    let id = i - number_of_removed
    let [tabnr, winnr] = s:FindWindowID(s:navigation_windows[id].window_id_)
    if (winnr == 0)
      call remove(s:navigation_windows, id)
      let number_of_removed += 1
    endif
  endfor
endfunction

function s:CheckEditionWindows()
  let number_of_edition_removed = 0
  for i in range(len(s:edition_windows))
    let edition_id = i - number_of_edition_removed
    let edition_window = s:edition_windows[edition_id]
    let number_of_sub_removed = 0
    for j in range(len(edition_window.sub_windows_))
      let sub_id = j - number_of_sub_removed
      let sub_window = edition_window.sub_windows_[sub_id]
      let [tabnr, winnr] = s:FindWindowID(sub_window.window_id_)
      if (winnr == 0)
        call remove(edition_window.sub_windows_, sub_id)
        let number_of_sub_removed += 1
      endif
    endfor
    if (len(edition_window.sub_windows_) <= 0)
      call remove(s:edition_windows, edition_id)
      let number_of_edition_removed += 1
    endif
  endfor
endfunction

function! s:FindWindowID(window_id)
  for tabnr in range(1, tabpagenr('$'))
    for winnr in range(1, tabpagewinnr(tabnr, '$'))
      let window_id = gettabwinvar(tabnr, winnr, 'window_id')
      if window_id is a:window_id
        return [tabnr, winnr]
      endif
    endfor
  endfor
  return [0, 0]
endfunction

function! s:MoveToWindowByWindowID(window_id)
  let [tabnr, winnr] = s:FindWindowID(a:window_id)
  if (winnr == 0)
    return -1
  endif
  execute "tabnext" tabnr
  execute winnr."wincmd w"
  return 0
endfunction

function! s:EchoEditionWindows()
  for l:edition_window in s:edition_windows
    echo "edition_window:"
    for l:edition_sub_window in l:edition_window.sub_windows_
      echo "  edition_subwindow-window_id:" . l:edition_sub_window.window_id_
    endfor
  endfor
endfunction

function! s:Initialize()
  "Assume no other windows before this script invoking.
  let edition_window = s:EditionWindow.New()
  let edition_sub_window = s:EditionSubWindow.New()
  let edition_sub_window.window_id_ = s:windows_counter + 1
  call add(edition_window.sub_windows_, edition_sub_window)
  call add(s:edition_windows, edition_window)
endfunction

call s:Initialize()

autocmd VimEnter,WinEnter *
  \ if !exists('w:window_id')
  \|  let s:windows_counter += 1
  \|  let w:window_id = s:windows_counter
  \|endif

autocmd WinLeave *
  \ call s:CheckNavigationWindows()
  \|call s:CheckEditionWindows()

" restore compatible-options
let &cpo = s:save_cpo
