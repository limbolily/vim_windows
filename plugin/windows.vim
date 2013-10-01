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

"This plugin manage windows.It dividds vim to 3 kind of windows:
"1.Edition Windows:The main windows,contain text to edit with fixed width
"(default to 80).
"2.Navigation Windows:navigation windows is at the left of the vim window.If
"contain more than one navigation window,they will be split horizontally with
"same height.
"3.Monitor Windows:monitor windows is at the bottom of the vim window,if
"contain more than one navigation window,they will be split vertically with
"same width.
"There are two mode:
"1.small screen mode:it contain only one edition window;
"2.full screen mode:it contain two edition window.

"edition window width
let g:edition_window_width = 80

"monitor window height ratio
let g:monitor_window_height_ratio = 0.3

"windows counter,identifies window uniquely
let s:windows_counter = 0

"EditionWindow class
let s:EditionWindow = {
  \'window_id_' : 0,
  \'window_nr_' : 0}
"Create EditionWindow object
function! s:EditionWindow.New()
  let new_edition_window = copy(self)
  return new_edition_window
endfunction
"EditionWindow container
let s:edition_windows = []

"NavigationWindow class
"Create NavigationWindow object
let s:NavigationWindow = {
  \'window_id_' : 0,
  \'window_nr_' : 0}
function! s:NavigationWindow.New()
  let new_navigation_window = copy(self)
  return new_navigation_window
endfunction
"NavigationWindow container
let s:navigation_windows = []

"MonitorWindow class
"Create MonitorWindow object
let s:MonitorWindow = {
  \'window_id_' : 0,
  \'window_nr_' : 0}
function! s:MonitorWindow.New()
  let new_monitor_window = copy(self)
  return new_monitor_window
endfunction
"MonitorWindow container
let s:monitor_windows = []

"for testing
let s:number_of_sp = 0
function! SplitWindow()
  new "sp" . s:number_of_sp
  execute "normal isp" . s:number_of_sp
  let s:number_of_sp = s:number_of_sp + 1
endfunction
let s:number_of_vsp = 0
function! VSplitWindow()
  vnew "vsp" . s:number_of_vsp
  execute "normal isp" . s:number_of_vsp
  let s:number_of_vsp = s:number_of_vsp + 1
endfunction

"put the window(assume only one) produced by a command to navigation windows
function! ShowInNavigationWindows(command)
  call s:CheckNavigationWindows()
  let windows_counter_before = s:windows_counter
  if (len(s:navigation_windows) <= 0)
    call s:MoveToWindowByWindowID(1)
    vertical topleft vsplit
    let vsplit_window_id = s:windows_counter
    call s:MoveToWindowByWindowID(vsplit_window_id)
    execute a:command
    call s:MoveToWindowByWindowID(s:windows_counter)
    set winwidth=1
    set winheight=1
    call s:MoveToWindowByWindowID(vsplit_window_id)
    quit
  else
    call s:MoveToWindowByWindowID(s:navigation_windows[0].window_id_)
    belowright split
    let split_window_id = s:windows_counter
    call s:MoveToWindowByWindowID(split_window_id)
    execute a:command
    call s:MoveToWindowByWindowID(split_window_id)
    quit
  endif

  let windows_counter_after = s:windows_counter
  for i in range(windows_counter_before + 1, windows_counter_after)
    let [tabnr, winnr] = s:FindWindowID(i)
    if (winnr != 0)
      let navigation_window = s:NavigationWindow.New()
      let navigation_window.window_id_ = i
      let navigation_window.window_nr_ = winnr
      call add(s:navigation_windows, navigation_window)
    endif
  endfor

  call s:MoveToWindowByWindowID(1)
  if (&number)
    let line_number_length = strlen(line('$'))
    let width = line_number_length + g:edition_window_width + 1
  else
    let width = g:edition_window_width + 1
  endif
  execute "vertical resize " . width

endfunction
function! TestShowInNavigationWindows()
  call ShowInNavigationWindows("call SplitWindow()")
endfunction

"put the window(assume only one) produced by a command to monitor windows
function! ShowInMonitorWindows(command)
  call s:CheckMonitorWindows()
  let windows_counter_before = s:windows_counter
  if (len(s:monitor_windows) <= 0)
    call s:MoveToWindowByWindowID(1)
    belowright split
    let split_window_id = s:windows_counter
    call s:MoveToWindowByWindowID(split_window_id)
    execute a:command
    call s:MoveToWindowByWindowID(s:windows_counter)
    set winwidth=1
    set winheight=1
    call s:MoveToWindowByWindowID(split_window_id)
    quit
  else
    call s:MoveToWindowByWindowID(s:monitor_windows[0].window_id_)
    vertical belowright vsplit
    let vsplit_window_id = s:windows_counter
    call s:MoveToWindowByWindowID(vsplit_window_id)
    execute a:command
    call s:MoveToWindowByWindowID(vsplit_window_id)
    quit
  endif

  let windows_counter_after = s:windows_counter
  for i in range(windows_counter_before + 1, windows_counter_after)
    let [tabnr, winnr] = s:FindWindowID(i)
    if (winnr != 0)
      let monitor_window = s:MonitorWindow.New()
      let monitor_window.window_id_ = i
      let monitor_window.window_nr_ = winnr
      call add(s:monitor_windows, monitor_window)
    endif
  endfor

  call s:MoveToWindowByWindowID(1)
  call s:CheckNavigationWindows()
  if (len(s:navigation_windows) > 0)
    if (&number)
      let line_number_length = strlen(line('$'))
      let width = line_number_length + g:edition_window_width + 1
    else
      let width = g:edition_window_width + 1
    endif
    execute "vertical resize " . width
  endif
  let height_ratio = 1.0 - g:monitor_window_height_ratio
  let height = str2float(&lines) * height_ratio
  execute "resize " . float2nr(height)

  call s:CheckMonitorWindows()
  call s:MoveToWindowByWindowID(1)
  let number_of_monitors = len(s:monitor_windows)
  let monitor_width = (winwidth(0) - number_of_monitors) / number_of_monitors
  for monitor_window in s:monitor_windows
    execute monitor_window.window_nr_ . "wincmd w"
    execute "vertical resize " . monitor_width
  endfor

endfunction
function! TestShowInMonitorWindows()
  call ShowInMonitorWindows("call VSplitWindow()")
endfunction

function! s:Initialize()
  let edition_window = s:EditionWindow.New()
  let edition_window.window_id_ = s:windows_counter + 1
  "TODO:how to identify edition window,now just assume no other windows before
  "this script invoking
  let edition_window.window_nr_ = 1
  call add(s:edition_windows, edition_window)
endfunction

function s:CheckEditionWindows()
  let number_of_removed = 0
  for i in range(len(s:edition_windows))
    let id = i - number_of_removed
    let [tabnr, winnr] = s:FindWindowID(s:edition_windows[id].window_id_)
    if (winnr == 0)
      call remove(s:edition_windows, id)
      let number_of_removed = number_of_removed + 1
    else
      let s:edition_windows[id].window_nr_ = winnr
    endif
  endfor
endfunction

function s:CheckNavigationWindows()
  let number_of_removed = 0
  for i in range(len(s:navigation_windows))
    let id = i - number_of_removed
    let [tabnr, winnr] = s:FindWindowID(s:navigation_windows[id].window_id_)
    if (winnr == 0)
      call remove(s:navigation_windows, id)
      let number_of_removed = number_of_removed + 1
    else
      let s:navigation_windows[id].window_nr_ = winnr
    endif
  endfor
endfunction

function s:CheckMonitorWindows()
  let number_of_removed = 0
  for i in range(len(s:monitor_windows))
    let id = i - number_of_removed
    let [tabnr, winnr] = s:FindWindowID(s:monitor_windows[id].window_id_)
    if (winnr == 0)
      call remove(s:monitor_windows, id)
      let number_of_removed = number_of_removed + 1
    else
      let s:monitor_windows[id].window_nr_ = winnr
    endif
  endfor
endfunction

function s:FindWindowID(window_id)
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

function s:MoveToWindowByWindowID(window_id)
  let [tabnr, winnr] = s:FindWindowID(a:window_id)
  if (winnr == 0)
    return -1
  endif
  execute "tabnext" tabnr
  execute winnr."wincmd w"
  return 0
endfunction

call s:Initialize()

autocmd VimEnter,WinEnter *
  \ if !exists('w:window_id')
  \|  let s:windows_counter = s:windows_counter + 1
  \|  let w:window_id = s:windows_counter
  \|endif

" restore compatible-options
let &cpo = s:save_cpo
