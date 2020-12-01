" Insert or delete brackets, parens, quotes in pairs.
" Maintainer:	yujinyuz <yujinyuz@pm.me>
" Last Change:  2020-11-30
" Version: 2.0.0
" Homepage: https://github.com/yujinyuz/vim-dyad
" Repository: https://github.com/yujinyuz/vim-dyad
" License: MIT

if exists('g:AutoPairsLoaded') || &cp
  finish
end
let g:AutoPairsLoaded = 1

if !exists('g:AutoPairs')
  let g:AutoPairs = {'(':')', '[':']', '{':'}',"'":"'",'"':'"', '`':'`'}
end

if !exists('g:AutoPairsNewline')
  let g:AutoPairsNewline = extend(deepcopy(g:AutoPairs), { '>':'</' })
end

if !exists('g:AutoPairsNewlineIndentCommand')
  let g:AutoPairsNewlineIndentCommand = {}
end

if !exists('g:AutoPairsParens')
  let g:AutoPairsParens = {'(':')', '[':']', '{':'}'}
end

if !exists('g:AutoPairsMapBS')
  let g:AutoPairsMapBS = 1
end

" Map <C-h> as the same BS
if !exists('g:AutoPairsMapCh')
  let g:AutoPairsMapCh = 1
end

if !exists('g:AutoPairsMapCR')
  let g:AutoPairsMapCR = 1
end

if !exists('g:AutoPairsMapSpace')
  let g:AutoPairsMapSpace = 1
end

if !exists('g:AutoPairsCenterLine')
  let g:AutoPairsCenterLine = 1
end

if !exists('g:AutoPairsShortcutToggle')
  let g:AutoPairsShortcutToggle = '<M-p>'
end

if !exists('g:AutoPairsShortcutFastWrap')
  let g:AutoPairsShortcutFastWrap = '<M-e>'
end

if !exists('g:AutoPairsMoveCharacter')
  let g:AutoPairsMoveCharacter = "()[]{}\"'"
end

if !exists('g:AutoPairsShortcutJump')
  let g:AutoPairsShortcutJump = '<M-n>'
endif

if !exists('g:AutoPairsDoNotSkip')
  let g:AutoPairsDoNotSkip = []
endif

if !exists('g:AutoPairsDisableSkip')
  let g:AutoPairsDisableSkip = 0
endif

" Fly mode will for closed pair to jump to closed pair instead of insert.
" also support AutoPairsBackInsert to insert pairs where jumped.
if !exists('g:AutoPairsFlyMode')
  let g:AutoPairsFlyMode = 0
endif

" When skipping the closed pair, look at the current and
" next line as well.
if !exists('g:AutoPairsMultilineClose')
  let g:AutoPairsMultilineClose = 1
endif

" Work with Fly Mode, insert pair where jumped
if !exists('g:AutoPairsShortcutBackInsert')
  let g:AutoPairsShortcutBackInsert = '<M-b>'
endif

if !exists('g:AutoPairsSmartQuotes')
  let g:AutoPairsSmartQuotes = 1
endif

if !exists('g:AutoPairsJumpCharacters')
  let g:AutoPairsJumpCharacters = values(g:AutoPairs)
endif

if !exists('g:AutoPairsJump_SkipString')
  let g:AutoPairsJump_SkipString = 0
endif

let s:Go = "\<C-G>U"
let s:Left = s:Go."\<LEFT>"
let s:Right = s:Go."\<RIGHT>"


" Will auto generated {']' => '[', ..., '}' => '{'}in initialize.
let g:AutoPairsClosedPairs = {}

function! s:IsCharSkippable(char)
  if g:AutoPairsDisableSkip
    return 1
  endif
  for char in g:AutoPairsDoNotSkip
    if char == a:char
      return 1
    endif
  endfor
endfunction

function! AutoPairsInsert(key)
  if !b:autopairs_enabled
    return a:key
  end

  let line = getline('.')
  let pos = col('.') - 1
  let before = strpart(line, 0, pos)
  let after = strpart(line, pos)
  let next_chars = split(after, '\zs')
  let current_char = get(next_chars, 0, '')
  let next_char = get(next_chars, 1, '')
  let prev_chars = split(before, '\zs')
  let prev_char = get(prev_chars, -1, '')

  let eol = 0
  if col('$') -  col('.') <= 1
    let eol = 1
  end

  " Ignore auto close if prev character is \
  if prev_char == '\'
    return a:key
  end

  " The key is difference open-pair, then it means only for ) ] } by default
  if !has_key(b:AutoPairs, a:key)
    let b:autopairs_saved_pair = [a:key, getpos('.')]

    " Skip the character if current character is the same as input
    if current_char == a:key && !s:IsCharSkippable(a:key)
      return s:Right
    end

    if !g:AutoPairsFlyMode
      " Skip the character if next character is space
      if current_char == ' ' && next_char == a:key
        return s:Right.s:Right
      end

      " Skip the character if closed pair is next character
      if current_char == ''
        if g:AutoPairsMultilineClose
          let next_lineno = line('.')+1
          let next_line = getline(nextnonblank(next_lineno))
          let next_char = matchstr(next_line, '\s*\zs.')
        else
          let next_char = matchstr(line, '\s*\zs.')
        end
        if next_char == a:key && !s:IsCharSkippable(a:key)
          return "\<ESC>e^a"
        endif
      endif
    endif

    " Fly Mode, and the key is closed-pairs, search closed-pair and jump
    if g:AutoPairsFlyMode && has_key(b:AutoPairsClosedPairs, a:key)
      let n = stridx(after, a:key)
      if n != -1
        return repeat(s:Right, n+1)
      end
      if search(a:key, 'W')
        " force break the '.' when jump to different line
        return "\<Right>"
      endif
    endif

    " Insert directly if the key is not an open key
    return a:key
  end

  let open = a:key
  let close = b:AutoPairs[open]

  if current_char == close && open == close && !s:IsCharSkippable(current_char)
    return s:Right
  end

  " Ignore auto close ' if follows a word
  " MUST after closed check. 'hello|'
  if a:key == "'" && prev_char =~ '\v\w'
    return a:key
  end

  " Ignore auto close {([ if next character is a word
  if ((a:key == "{" || a:key== "(" || a:key == "{") && next_char =~ '\v\w')
    return a:key
  end

  " support for ''' ``` and """
  if open == close
    " The key must be ' " `
    let pprev_char = line[col('.')-3]
    if pprev_char == open && prev_char == open
      " Double pair found
      return repeat(a:key, 4) . repeat(s:Left, 3)
    end
  end

  let quotes_num = 0
  " Ignore comment line for vim file
  if &filetype == 'vim' && a:key == '"'
    if before =~ '^\s*$'
      return a:key
    end
    if before =~ '^\s*"'
      let quotes_num = -1
    end
  end

  " Keep quote number is odd.
  " Because quotes should be matched in the same line in most of situation
  if g:AutoPairsSmartQuotes && open == close
    " Remove \\ \" \'
    let cleaned_line = substitute(line, '\v(\\.)', '', 'g')
    let n = quotes_num
    let pos = 0
    while 1
      let pos = stridx(cleaned_line, open, pos)
      if pos == -1
        break
      end
      let n = n + 1
      let pos = pos + 1
    endwhile
    if n % 2 == 1
      return a:key
    endif
  endif

  return open.close.s:Left
endfunction

function! AutoPairsDelete()
  if !b:autopairs_enabled
    return "\<BS>"
  end

  let line = getline('.')
  let pos = col('.') - 1
  let current_char = get(split(strpart(line, pos), '\zs'), 0, '')
  let prev_chars = split(strpart(line, 0, pos), '\zs')
  let prev_char = get(prev_chars, -1, '')
  let pprev_char = get(prev_chars, -2, '')

  if pprev_char == '\'
    return "\<BS>"
  end

  " Delete last two spaces in parens, work with MapSpace
  if has_key(b:AutoPairs, pprev_char) && prev_char == ' ' && current_char == ' '
    return "\<BS>\<DEL>"
  endif

  " Delete Repeated Pair eg: '''|''' [[|]] {{|}}
  if has_key(b:AutoPairs, prev_char)
    let times = 0
    let p = -1
    while get(prev_chars, p, '') == prev_char
      let p = p - 1
      let times = times + 1
    endwhile

    let close = b:AutoPairs[prev_char]
    let left = repeat(prev_char, times)
    let right = repeat(close, times)

    let before = strpart(line, pos-times, times)
    let after  = strpart(line, pos, times)
    if left == before && right == after
      return repeat("\<BS>\<DEL>", times)
    end
  end


  if has_key(b:AutoPairs, prev_char)
    let close = b:AutoPairs[prev_char]
    if match(line,'^\s*'.close, col('.')-1) != -1
      " Delete (|___)
      let space = matchstr(line, '^\s*', col('.')-1)
      return "\<BS>". repeat("\<DEL>", len(space)+1)
    elseif match(line, '^\s*$', col('.')-1) != -1
      " Delete (|__\n___)
      let nline = getline(line('.')+1)
      if nline =~ '^\s*'.close
        if &filetype == 'vim' && prev_char == '"'
          " Keep next line's comment
          return "\<BS>"
        end

        let space = matchstr(nline, '^\s*')
        return "\<BS>\<DEL>". repeat("\<DEL>", len(space)+1)
      end
    end
  end

  return "\<BS>"
endfunction

function! AutoPairsJump()
  let jump_search_expr = join(g:AutoPairsJumpCharacters, '\|')
  let was_inside_string = !empty(filter(map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")'), 'v:val =~? "string\\|character\\|singlequote\\|escape"'))
  let pos = searchpos('\(' . jump_search_expr . '\)','ceW')
  if !was_inside_string && g:AutoPairsJump_SkipString
    let inside_string_forward = 0
    let inside_string_backwards = 0
    let two_quotes = 0

    " Skip if the character is inside a string but isn't a string delimiter
    " itself.
    while pos != [0,0]
      let cur_line = getline('.')
      let cur_char = strpart(cur_line, pos[1], 1)

      let can_look_forward = pos[1] < len(cur_line)
      if can_look_forward
        let inside_string_forward = !empty(filter(map(synstack(pos[0], pos[1]), 'synIDattr(v:val, "name")'), 'v:val =~? "string\\|character"')) && !empty(filter(map(synstack(pos[0], pos[1] + 1), 'synIDattr(v:val, "name")'), 'v:val =~? "string\\|character"'))
      endif

      let can_look_backwards = pos[1] > 1
      if can_look_backwards
        let inside_string_backwards = !empty(filter(map(synstack(pos[0], pos[1]), 'synIDattr(v:val, "name")'), 'v:val =~? "string\\|character"')) && !empty(filter(map(synstack(pos[0], pos[1] - 1), 'synIDattr(v:val, "name")'), 'v:val =~? "string\\|character"'))
      endif

      if !can_look_forward || (!inside_string_forward && !inside_string_backwards)
        break
      endif

      let pos = searchpos('\(' . jump_search_expr . '\)','W')
    endwhile
  endif
  if pos != [0,0]
    call cursor(pos[0], pos[1] + 1)
  endif
  return ''
endfunction
" string_chunk cannot use standalone
let s:string_chunk = '\v%(\\\_.|[^\1]|[\r\n]){-}'
let s:ss_pattern = '\v''' . s:string_chunk . ''''
let s:ds_pattern = '\v"'  . s:string_chunk . '"'

func! s:RegexpQuote(str)
  return substitute(a:str, '\v[\[\{\(\<\>\)\}\]]', '\\&', 'g')
endf

func! s:RegexpQuoteInSquare(str)
  return substitute(a:str, '\v[\[\]]', '\\&', 'g')
endf

" Search next open or close pair
func! s:FormatChunk(open, close)
  let open = s:RegexpQuote(a:open)
  let close = s:RegexpQuote(a:close)
  let open2 = s:RegexpQuoteInSquare(a:open)
  let close2 = s:RegexpQuoteInSquare(a:close)
  if open == close
    return '\v'.open.s:string_chunk.close
  else
    return '\v%(' . s:ss_pattern . '|' . s:ds_pattern . '|' . '[^'.open2.close2.']|[\r\n]' . '){-}(['.open2.close2.'])'
  end
endf

" Fast wrap the word in brackets
function! AutoPairsFastWrap()
  let line = getline('.')
  let current_char = line[col('.')-1]
  let next_char = line[col('.')]
  let open_pair_pattern = '\v[({\[''"]'
  let at_end = col('.') >= col('$') - 1
  normal! x
  " Skip blank
  if next_char =~ '\v\s' || at_end
    call search('\v\S', 'W')
    let line = getline('.')
    let next_char = line[col('.')-1]
  end

  if has_key(b:AutoPairs, next_char)
    let followed_open_pair = next_char
    let inputed_close_pair = current_char
    let followed_close_pair = b:AutoPairs[next_char]
    if followed_close_pair != followed_open_pair
      " TODO replace system searchpair to skip string and nested pair.
      " eg: (|){"hello}world"} will transform to ({"hello})world"}
      call searchpair('\V'.followed_open_pair, '', '\V'.followed_close_pair, 'W')
    else
      call search(s:FormatChunk(followed_open_pair, followed_close_pair), 'We')
    end
    return s:Right.inputed_close_pair.s:Left
  else
    normal! he
    return s:Right.current_char.s:Left
  end
endfunction

function! AutoPairsMap(key)
  " | is special key which separate map command from text
  let key = a:key
  if key == '|'
    let key = '<BAR>'
  end
  let escaped_key = substitute(key, "'", "''", 'g')
  " use expr will cause search() doesn't work
  execute 'inoremap <buffer> <silent> '.key." <C-R>=AutoPairsInsert('".escaped_key."')<CR>"
endfunction

function! AutoPairsToggle()
  if b:autopairs_enabled
    let b:autopairs_enabled = 0
    echo 'AutoPairs Disabled.'
  else
    let b:autopairs_enabled = 1
    echo 'AutoPairs Enabled.'
  end
  return ''
endfunction

function! AutoPairsMoveCharacter(key)
  let c = getline(".")[col(".")-1]
  let escaped_key = substitute(a:key, "'", "''", 'g')
  return "\<DEL>\<ESC>:call search("."'".escaped_key."'".")\<CR>a".c."\<LEFT>"
endfunction

function! AutoPairsReturn()
  if b:autopairs_enabled == 0
    return ''
  end
  let cmd = ''
  let line_n = line('.')
  let prev_line = getline(line_n - 1)
  let prev_char = prev_line[len(prev_line) - 1]
  let remaining_line = getline(line_n)

  if has_key(b:AutoPairsNewline, prev_char) && remaining_line =~? '^\s*' . b:AutoPairsNewline[prev_char]
    execute 'norm! ' . get(b:AutoPairsNewlineIndentCommand, prev_char, '==')
    call append(line_n - 1, '')
    norm! k
    if &expandtab
      let cmd = repeat(" ", max([0, matchend(prev_line, '^\s*')]) + &shiftwidth)
    else
      let cmd = repeat("\<Tab>", max([0, matchend(prev_line, '^\t*')]) + 1)
    endif
  end
  return cmd
endfunction

function! AutoPairsSpace()
  let line = getline('.')
  let prev_char = line[col('.')-2]
  let cmd = ''
  let cur_char =line[col('.')-1]
  if has_key(g:AutoPairsParens, prev_char) && g:AutoPairsParens[prev_char] == cur_char
    let cmd = "\<SPACE>".s:Left
  endif
  return "\<SPACE>".cmd
endfunction

function! AutoPairsBackInsert()
  if exists('b:autopairs_saved_pair')
    let pair = b:autopairs_saved_pair[0]
    let pos  = b:autopairs_saved_pair[1]
    call setpos('.', pos)
    return pair
  endif
  return ''
endfunction

function! AutoPairsInit()
  let b:autopairs_loaded  = 1
  if !exists('b:autopairs_enabled')
    let b:autopairs_enabled = 1
  end
  let b:AutoPairsClosedPairs = {}

  if !exists('b:AutoPairs')
    let b:AutoPairs = g:AutoPairs
  end

  if !exists('b:AutoPairsNewline')
    let b:AutoPairsNewline = g:AutoPairsNewline
  end

  if !exists('b:AutoPairsNewlineIndentCommand')
    let b:AutoPairsNewlineIndentCommand = g:AutoPairsNewlineIndentCommand
  end

  if !exists('b:AutoPairsMoveCharacter')
    let b:AutoPairsMoveCharacter = g:AutoPairsMoveCharacter
  end

  " buffer level map pairs keys
  for [open, close] in items(b:AutoPairs)
    call AutoPairsMap(open)
    if open != close
      call AutoPairsMap(close)
    end
    let b:AutoPairsClosedPairs[close] = open
  endfor

  for key in split(b:AutoPairsMoveCharacter, '\s*')
    let escaped_key = substitute(key, "'", "''", 'g')
    execute 'inoremap <silent> <buffer> <M-'.key."> <C-R>=AutoPairsMoveCharacter('".escaped_key."')<CR>"
  endfor

  " Still use <buffer> level mapping for <BS> <SPACE>
  if g:AutoPairsMapBS
    " Use <C-R> instead of <expr> for issue #14 sometimes press BS output strange words
    execute 'inoremap <buffer> <silent> <BS> <C-R>=AutoPairsDelete()<CR>'
  end

  if g:AutoPairsMapCh
    execute 'inoremap <buffer> <silent> <C-h> <C-R>=AutoPairsDelete()<CR>'
  endif

  if g:AutoPairsMapSpace
    " Try to respect abbreviations on a <SPACE>
    let do_abbrev = ""
    let do_abbrev = "<C-]>"
    execute 'inoremap <buffer> <silent> <SPACE> '.do_abbrev.'<C-R>=AutoPairsSpace()<CR>'
  end

  if g:AutoPairsShortcutFastWrap != ''
    execute 'inoremap <buffer> <silent> '.g:AutoPairsShortcutFastWrap.' <C-R>=AutoPairsFastWrap()<CR>'
  end

  if g:AutoPairsShortcutBackInsert != ''
    execute 'inoremap <buffer> <silent> '.g:AutoPairsShortcutBackInsert.' <C-R>=AutoPairsBackInsert()<CR>'
  end

  if g:AutoPairsShortcutToggle != ''
    " use <expr> to ensure showing the status when toggle
    execute 'inoremap <buffer> <silent> <expr> '.g:AutoPairsShortcutToggle.' AutoPairsToggle()'
    execute 'noremap <buffer> <silent> '.g:AutoPairsShortcutToggle.' :call AutoPairsToggle()<CR>'
  end

  if g:AutoPairsShortcutJump != ''
    execute 'inoremap <buffer> <silent> ' . g:AutoPairsShortcutJump. ' <C-R>=AutoPairsJump()<CR>'
    execute 'noremap <buffer> <silent> ' . g:AutoPairsShortcutJump. ' :call AutoPairsJump()<CR>'
  end

endfunction

function! s:ExpandMap(map)
  let map = a:map
  let map = substitute(map, '\(<Plug>\w\+\)', '\=maparg(submatch(1), "i")', 'g')
  let map = substitute(map, '\(<Plug>([^)]*)\)', '\=maparg(submatch(1), "i")', 'g')
  return map
endfunction

function! AutoPairsTryInit()
  if exists('b:autopairs_loaded')
    return
  end

  " for auto-pairs starts with 'a', so the priority is higher than supertab and vim-endwise
  "
  " vim-endwise doesn't support <Plug>AutoPairsReturn
  " when use <Plug>AutoPairsReturn will cause <Plug> isn't expanded
  "
  " supertab doesn't support <SID>AutoPairsReturn
  " when use <SID>AutoPairsReturn  will cause Duplicated <CR>
  "
  " and when load after vim-endwise will cause unexpected endwise inserted.
  " so always load AutoPairs at last

  " Buffer level keys mapping
  " comptible with other plugin
  if g:AutoPairsMapCR
    let info = maparg('<CR>', 'i', 0, 1)
    if empty(info)
      let old_cr = '<CR>'
      let is_expr = 0
    else
      let old_cr = info['rhs']
      let old_cr = s:ExpandMap(old_cr)
      let old_cr = substitute(old_cr, '<SID>', '<SNR>' . info['sid'] . '_', 'g')
      let is_expr = info['expr']
      let wrapper_name = '<SID>AutoPairsOldCRWrapper73'
    endif

    if old_cr !~ 'AutoPairsReturn'
      if is_expr
        " remap <expr> to `name` to avoid mix expr and non-expr mode
        execute 'inoremap <buffer> <expr> <script> '. wrapper_name . ' ' . old_cr
        let old_cr = wrapper_name
      end
      " Always silent mapping
      execute 'inoremap <script> <buffer> <silent> <CR> '.old_cr.'<SID>AutoPairsReturn'
    end
  endif
  call AutoPairsInit()
endfunction

" Always silent the command
inoremap <silent> <SID>AutoPairsReturn <C-R>=AutoPairsReturn()<CR>
imap <script> <Plug>AutoPairsReturn <SID>AutoPairsReturn


au BufEnter * :call AutoPairsTryInit()
