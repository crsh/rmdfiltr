--[[
MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Initial version copied verbatim from:
https://github.com/mloubout/critic-markup/blob/main/_extensions/critic-markup/critic-markup.lua
]]

-- Critic Markup filter for Quarto and R Markdown
-- Allows rendering markup, original or edited versions.

local critic_mode = 'markup'
local add, adde, rm, rme, rmeadd, mark, marke, comm, comme, rules
local st_b, st_e = '{', '}'
local en_dash = utf8.char(0x2013)

local scriptcode = [[
<div id="criticnav">
<ul>
<li id="markup-button">Markup</li>
<li id="original-button">Original</li>
<li id="edited-button">Edited</li>
</ul>
</div>

<script type="text/javascript">
  function critic() {
      $('.content').addClass('markup');
      $('#markup-button').addClass('active');
      $('ins.break').unwrap();
      $('span.critic.comment').wrap('<span class="popoverc" /></span>');
      $('span.critic.comment').before('&#8225;');
  }

  function original() {
      $('#original-button').addClass('active');
      $('#edited-button').removeClass('active');
      $('#markup-button').removeClass('active');

      $('.content').addClass('original');
      $('.content').removeClass('edited');
      $('.content').removeClass('markup');
  }

  function edited() {
      $('#original-button').removeClass('active');
      $('#edited-button').addClass('active');
      $('#markup-button').removeClass('active');

      $('.content').removeClass('original');
      $('.content').addClass('edited');
      $('.content').removeClass('markup');
  }

  function markup() {
      $('#original-button').removeClass('active');
      $('#edited-button').removeClass('active');
      $('#markup-button').addClass('active');

      $('.content').removeClass('original');
      $('.content').removeClass('edited');
      $('.content').addClass('markup');
  }

  var o = document.getElementById("original-button");
  var e = document.getElementById("edited-button");
  var m = document.getElementById("markup-button");

  window.onload = critic();
  o.onclick = original;
  e.onclick = edited;
  m.onclick = markup;
</script>
]]

local latexcode = nil

local function setup_markup()
  if FORMAT:match 'html' then
    add = pandoc.RawInline('html', '<ins>')
    adde = pandoc.RawInline('html', '</ins>')
    rm = pandoc.RawInline('html', '<del>')
    rme = pandoc.RawInline('html', '</del>')
    rmeadd = pandoc.RawInline('html', '</del><ins>')
    mark = pandoc.RawInline('html', '<mark>')
    marke = pandoc.RawInline('html', '</mark>')
    comm = pandoc.RawInline('html', '<span class="critic comment">')
    comme = pandoc.RawInline('html', '</span>')
  elseif FORMAT:match 'docx' then
    -- For docx, we cannot use raw tags. The markup representation is
    -- handled in a dedicated pass; here, rules are left unset.
    add, adde, rm, rme, rmeadd, mark, marke, comm, comme = nil, nil, nil, nil, nil, nil, nil, nil, nil
  elseif FORMAT:match 'latex' then
    add = pandoc.RawInline('latex', '\\criticmarkupadd{')
    adde = pandoc.RawInline('latex', '}')
    rm = pandoc.RawInline('latex', '\\criticmarkuprm{')
    rme = pandoc.RawInline('latex', '}')
    rmeadd = pandoc.RawInline('latex', '}\\criticmarkupadd{')
    mark = pandoc.RawInline('latex', '\\criticmarkupmark{')
    marke = pandoc.RawInline('latex', '}')
    comm = pandoc.RawInline('latex', '\\criticmarkupcomm{')
    comme = pandoc.RawInline('latex', '}')
    if critic_mode == 'markup' then
      latexcode = [[
\usepackage{pdfcomment}
\makeatletter
\newcommand{\criticmarkupadd}[1]{\pdfmarkupcomment[markup=Highlight,color={0.838431 0.913725 0.734902}]{#1}{}}
\newcommand{\criticmarkuprm}[1]{\pdfmarkupcomment[markup=Highlight,color={0.887059 0.673725 0.673725}]{#1}{}}
\newcommand{\criticmarkupmark}[1]{\pdfmarkupcomment[markup=Highlight,color={1 0.99216 0.21961}]{#1}{}}
\newcommand{\criticmarkupcomm}[1]{\pdfcomment[icon=Comment, color={0.89804 0.69020 0}]{#1}}
\makeatother
]]
    elseif critic_mode == 'original' then
      latexcode = [[
\makeatletter
\newcommand{\criticmarkupadd}[1]{}
\newcommand{\criticmarkuprm}[1]{#1}
\newcommand{\criticmarkupmark}[1]{#1}
\newcommand{\criticmarkupcomm}[1]{}
\makeatother
]]
    else -- edited
      latexcode = [[
\makeatletter
\newcommand{\criticmarkupadd}[1]{#1}
\newcommand{\criticmarkuprm}[1]{}
\newcommand{\criticmarkupmark}[1]{#1}
\newcommand{\criticmarkupcomm}[1]{}
\makeatother
]]
    end
  end

  -- Only define HTML/LaTeX replacement rules. For docx we handle
  -- markup via a dedicated inlines processor (no raw tags).
  if FORMAT:match('html') or FORMAT:match('latex') then
    rules = {
      ['{++'] = add,
      ['{--'] = rm,
      ['{' .. en_dash] = rm,
      ['{=='] = mark,
      ['{>>'] = comm,
      ['{~~'] = rm,
      ['++}'] = adde,
      ['--}'] = rme,
      [en_dash .. '}'] = rme,
      ['==}'] = marke,
      ['<<}'] = comme,
      ['~~}'] = rme,
      ['~>'] = rmeadd,
    }
  else
    rules = {}
  end
end

-- determine whether we should include content based on current critic state
local function include_for_mode(state)
  if state == 'normal' or state == 'mark' then
    return true
  elseif state == 'add' then
    return critic_mode == 'edited'
  elseif state == 'del' then
    return critic_mode ~= 'edited'
  elseif state == 'sub_orig' then
    return critic_mode ~= 'edited'
  elseif state == 'sub_new' then
    return critic_mode == 'edited'
  elseif state == 'comm' then
    return false
  end
  return true
end

-- process a string segment, handling critic markers that may appear within it
local function process_text_segment(text, state)
  local out = {}
  local i = 1
  while i <= #text do
    -- drop any stray closing brace in non-markup modes
    if text:sub(i, i) == '}' then
      i = i + 1
      goto continue
    end
    -- opening markers (only meaningful outside a region)
    if state == 'normal' then
      if text:sub(i, i + 2) == '{++' then
        state = 'add'
        i = i + 3
        goto continue
      elseif text:sub(i, i + 2) == '{--' then
        state = 'del'
        i = i + 3
        goto continue
      elseif text:sub(i, i + #('{' .. en_dash) - 1) == '{' .. en_dash then
        -- en dash variant for deletions: {–
        state = 'del'
        i = i + #('{' .. en_dash)
        goto continue
      elseif text:sub(i, i + 2) == '{==' then
        state = 'mark'
        i = i + 3
        goto continue
      elseif text:sub(i, i + 2) == '{>>' then
        state = 'comm'
        i = i + 3
        goto continue
      elseif text:sub(i, i + 2) == '{~~' then
        state = 'sub_orig'
        i = i + 3
        goto continue
      elseif text:sub(i, i) == '{' then
        -- Fallback handling: brace-wrapped substitution without tildes
        -- (e.g., after Strikeout has been flattened): {orig ~> new}
        local rest = text:sub(i + 1)
        local close_pos = rest:find('}', 1, true)
        if close_pos then
          local inner = rest:sub(1, close_pos - 1)
          local orig, new = inner:match('^(.-)%s*~>%s*(.*)$')
          if orig and new then
            if critic_mode == 'edited' then
              if new ~= '' and include_for_mode('sub_new') then out[#out + 1] = new end
            else
              if orig ~= '' and include_for_mode('sub_orig') then out[#out + 1] = orig end
            end
            i = i + close_pos + 1
            goto continue
          end
        end
      end
    end
    -- mid substitution marker
    if state == 'sub_orig' and text:sub(i, i + 1) == '~>' then
      state = 'sub_new'
      i = i + 2
      goto continue
    end

    -- closing markers
    if state ~= 'normal' then
      if text:sub(i, i + 2) == '++}' then
        state = 'normal'
        i = i + 3
        goto continue
      elseif text:sub(i, i + 2) == '--}' then
        state = 'normal'
        i = i + 3
        goto continue
      elseif text:sub(i, i + #en_dash) == en_dash .. '}' then
        state = 'normal'
        i = i + #en_dash + 1
        goto continue
      elseif text:sub(i, i + 2) == '==}' then
        state = 'normal'
        i = i + 3
        goto continue
      elseif text:sub(i, i + 2) == '<<}' then
        state = 'normal'
        i = i + 3
        goto continue
      elseif text:sub(i, i + 2) == '~~}' then
        state = 'normal'
        i = i + 3
        goto continue
      end
    end

    -- regular character
    local ch = text:sub(i, i)
    if include_for_mode(state) and ch ~= '' then
      out[#out + 1] = ch
    end
    i = i + 1
    ::continue::
  end
  return table.concat(out), state
end

-- Process a list of inline elements to remove/keep critic content for PDF original/edited
-- Merge adjacent Str tokens so critic markers aren't split across tokens
local function merge_adjacent_str(inlines)
  local merged = pandoc.List()
  local buffer = nil
  for _, t in ipairs(inlines) do
    if t.t == 'Str' then
      if buffer == nil then
        buffer = t.text
      else
        buffer = buffer .. t.text
      end
    else
      if buffer ~= nil and buffer ~= '' then
        merged:insert(pandoc.Str(buffer))
        buffer = nil
      end
      merged:insert(t)
    end
  end
  if buffer ~= nil and buffer ~= '' then
    merged:insert(pandoc.Str(buffer))
  end
  return merged
end

local function process_inlines_for_pdf(inlines)
  local result = pandoc.List()
  local state = 'normal'
  local i = 1
  local function is_textlike(t)
    return t.t == 'Str' or t.t == 'Space' or t.t == 'SoftBreak' or t.t == 'LineBreak'
  end
  local function seg_to_string(seg)
    local buf = {}
    for _, t in ipairs(seg) do
      if t.t == 'Str' then buf[#buf+1] = t.text
      elseif t.t == 'Space' then buf[#buf+1] = ' '
      elseif t.t == 'SoftBreak' or t.t == 'LineBreak' then buf[#buf+1] = ' '
      end
    end
    return table.concat(buf)
  end
  while i <= #inlines do
    local inline = inlines[i]

    -- Handle substitution enclosed in braces: {~~orig~>new~~}
    if inline.t == 'Str' and inline.text == '{' and i + 2 <= #inlines then
      local mid = inlines[i + 1]
      local last = inlines[i + 2]
      if mid and mid.t == 'Strikeout' and last and last.t == 'Str' and last.text == '}' then
        local content = pandoc.utils.stringify(mid.content)
        local orig, new = content:match('^(.-)%s*~>%s*(.*)$')
        if orig and new then
          if critic_mode == 'edited' then
            if new ~= '' and include_for_mode('sub_new') then
              result:insert(pandoc.Str(new))
            end
          else
            if orig ~= '' and include_for_mode('sub_orig') then
              result:insert(pandoc.Str(orig))
            end
          end
          i = i + 3
          goto continue
        end
        -- Not a proper substitution; drop braces and pass content per mode
        if include_for_mode(state) then
          result:insert(mid)
        end
        i = i + 3
        goto continue
      end
    end

    if is_textlike(inline) then
      local seg = {}
      while i <= #inlines and is_textlike(inlines[i]) do
        seg[#seg + 1] = inlines[i]
        i = i + 1
      end
      -- step back one since outer loop will increment
      i = i - 1
      local text = seg_to_string(seg)
      local processed, new_state = process_text_segment(text, state)
      state = new_state
      if processed ~= '' then result:insert(pandoc.Str(processed)) end
    elseif inline.t == 'Strikeout' then
      -- Handle substitution triplet that may be split across tokens:
      -- Str("{") + Strikeout("orig ~> new") + Str("}")
      local nexttok = inlines[i + 1]
      local prevtok = result[#result]
      if nexttok and nexttok.t == 'Str' and nexttok.text == '}' and prevtok and prevtok.t == 'Str' then
        local prevtext = prevtok.text
        if prevtext:sub(-1) == '{' then
          -- trim the previously emitted '{'
          if #prevtext == 1 then
            table.remove(result, #result)
          else
            result[#result] = pandoc.Str(prevtext:sub(1, -2))
          end
          local content = pandoc.utils.stringify(inline.content)
          local orig, new = content:match('^(.-)%s*~>%s*(.*)$')
          if orig and new then
            if critic_mode == 'edited' then
              if new ~= '' and include_for_mode('sub_new') then result:insert(pandoc.Str(new)) end
            else
              if orig ~= '' and include_for_mode('sub_orig') then result:insert(pandoc.Str(orig)) end
            end
            i = i + 1 -- skip the trailing '}' token
            goto continue
          else
            -- not a substitution; re-insert '{' and fall back
            result:insert(pandoc.Str('{'))
          end
        end
      end
      if include_for_mode(state) then result:insert(inline) end
    else
      if include_for_mode(state) then result:insert(inline) end
    end
    i = i + 1
    ::continue::
  end
  return result
end

local function cirtiblock(blocks, k, v)
  local newblock = {}
  for _, t in pairs(blocks) do
    if t.text then
      local i, j = t.text:find(k, 1, true)
      if i then
        newblock[#newblock + 1] = pandoc.Str(t.text:sub(1, i - 1))
        newblock[#newblock + 1] = v
        newblock[#newblock + 1] = pandoc.Str(t.text:sub(j + 1, #t.text))
      else
        newblock[#newblock + 1] = t
      end
    else
      newblock[#newblock + 1] = t
    end
  end
  return newblock
end

function Str(el)
  if (critic_mode == 'markup') or FORMAT:match('latex') then
    local replaced = { el }
    for k, v in pairs(rules) do
      replaced = cirtiblock(replaced, k, v)
    end
    return replaced
  end
  -- for non-markup modes, Str is handled in Inlines processor
  return el
end

function Strikeout(strk)
  return strk.content
end

-- Convert critic markup to native Pandoc inlines for non-HTML, non-LaTeX
-- formats (e.g., docx) when showing markup. Uses Strikeout for deletions,
-- Emph for insertions and Strong for marks. Comments are appended in
-- brackets as Emph, e.g. [comment: ...]. Substitutions render as
-- Strikeout(orig) + " -> " + Emph(new).
local function process_inlines_for_markup_native(inlines)
  local function str_node(s)
    if s == '' then return nil end
    return pandoc.Str(s)
  end
  local out = pandoc.List()
  local buf = ''
  local state = 'normal'
  local sub_orig = ''

  local function flush_text()
    if buf ~= '' then
      out:insert(pandoc.Str(buf))
      buf = ''
    end
  end

  local function emit_wrapped(kind, text)
    if text == '' then return end
    if kind == 'add' then
      out:insert(pandoc.Emph({ pandoc.Str(text) }))
    elseif kind == 'del' then
      out:insert(pandoc.Strikeout({ pandoc.Str(text) }))
    elseif kind == 'mark' then
      out:insert(pandoc.Strong({ pandoc.Str(text) }))
    elseif kind == 'comm' then
      out:insert(pandoc.Space())
      out:insert(pandoc.Emph({ pandoc.Str('[comment: ' .. text .. ']') }))
    end
  end

  -- flatten text-like inlines into a single string for parsing
  local text = ''
  for _, t in ipairs(inlines) do
    if t.t == 'Str' then text = text .. t.text
    elseif t.t == 'Space' then text = text .. ' '
    elseif t.t == 'SoftBreak' or t.t == 'LineBreak' then text = text .. ' '
    else
      -- non-text inline: flush buffered text first, then keep the token
      if text ~= '' then
        -- process text chunk recursively
        local subin = { pandoc.Str(text) }
        local processed = process_inlines_for_markup_native(subin)
        for _, x in ipairs(processed) do out:insert(x) end
        text = ''
      end
      out:insert(t)
    end
  end
  if text ~= '' then
    -- parse the text buffer for critic markers
    local i = 1
    while i <= #text do
      -- open markers
      if state == 'normal' then
        if text:sub(i, i + 2) == '{++' then
          flush_text(); state = 'add'; i = i + 3; goto continue
        elseif text:sub(i, i + 2) == '{--' then
          flush_text(); state = 'del'; i = i + 3; goto continue
        elseif text:sub(i, i + #('{' .. en_dash) - 1) == '{' .. en_dash then
          flush_text(); state = 'del'; i = i + #('{' .. en_dash); goto continue
        elseif text:sub(i, i + 2) == '{==' then
          flush_text(); state = 'mark'; i = i + 3; goto continue
        elseif text:sub(i, i + 2) == '{>>' then
          flush_text(); state = 'comm'; i = i + 3; goto continue
        elseif text:sub(i, i + 2) == '{~~' then
          flush_text(); state = 'sub_orig'; sub_orig = ''; i = i + 3; goto continue
        end
      end

      -- mid substitution marker
      if state == 'sub_orig' and text:sub(i, i + 1) == '~>' then
        -- emit original as strikeout now, then switch to collecting new
        if sub_orig ~= '' then out:insert(pandoc.Strikeout({ pandoc.Str(sub_orig) })) end
        out:insert(pandoc.Str(' -> '))
        state = 'sub_new'
        i = i + 2
        goto continue
      end

      -- close markers
      if state ~= 'normal' then
        if text:sub(i, i + 2) == '++}' then
          emit_wrapped('add', buf); buf = ''; state = 'normal'; i = i + 3; goto continue
        elseif text:sub(i, i + 2) == '--}' then
          emit_wrapped('del', buf); buf = ''; state = 'normal'; i = i + 3; goto continue
        elseif text:sub(i, i + #en_dash) == en_dash .. '}' then
          emit_wrapped('del', buf); buf = ''; state = 'normal'; i = i + #en_dash + 1; goto continue
        elseif text:sub(i, i + 2) == '==}' then
          emit_wrapped('mark', buf); buf = ''; state = 'normal'; i = i + 3; goto continue
        elseif text:sub(i, i + 2) == '<<}' then
          emit_wrapped('comm', buf); buf = ''; state = 'normal'; i = i + 3; goto continue
        elseif text:sub(i, i + 2) == '~~}' then
          if state == 'sub_new' then
            emit_wrapped('add', buf)
          else
            -- no new part; show only original
            if sub_orig ~= '' then out:insert(pandoc.Strikeout({ pandoc.Str(sub_orig) })) end
          end
          buf = ''
          state = 'normal'
          i = i + 3
          goto continue
        end
      end

      -- accumulate text for current state
      local ch = text:sub(i, i)
      if state == 'sub_orig' then
        sub_orig = sub_orig .. ch
      else
        buf = buf .. ch
      end
      i = i + 1
      ::continue::
    end
    -- flush any remaining buffered content if markers were unbalanced
    if buf ~= '' then
      if state == 'add' then emit_wrapped('add', buf)
      elseif state == 'del' then emit_wrapped('del', buf)
      elseif state == 'mark' then emit_wrapped('mark', buf)
      elseif state == 'comm' then emit_wrapped('comm', buf)
      else out:insert(pandoc.Str(buf)) end
      buf = ''
    end
  end

  return out
end

function Inlines(inlines)
  -- For non-markup modes (original/edited) on non-LaTeX formats, strip/keep
  -- critic regions across tokens. This covers HTML original/edited and docx.
  if critic_mode ~= 'markup' and not FORMAT:match('latex') then
    return process_inlines_for_pdf(inlines)
  end

  -- For docx markup, convert to native inlines with basic styling
  if critic_mode == 'markup' and FORMAT:match('docx') then
    return process_inlines_for_markup_native(inlines)
  end

  -- HTML/LaTeX markup: rely on raw tag replacement rules
  for i = #inlines - 1, 2, -1 do
    if inlines[i] and inlines[i].t == 'Strikeout' and inlines[i + 1] then
      if inlines[i + 1].t == 'Str' and inlines[i + 1].text == st_e then
        inlines[i + 1] = adde
      end
    end
    if inlines[i] and inlines[i].t == 'Strikeout' and inlines[i - 1] then
      if inlines[i - 1].t == 'Str' and inlines[i - 1].text == st_b then
        inlines[i - 1] = rm
      end
    end
  end
  return inlines
end

local function criticheader(meta)
  if meta['critic-mode'] then
    critic_mode = pandoc.utils.stringify(meta['critic-mode'])
  end

  -- Set up macros and rules for current format/mode
  setup_markup()

  -- Handle Quarto vs R Markdown differently
  if quarto then
    -- Quarto: use quarto.doc API
    if FORMAT:match 'html' then
      -- For HTML, support all modes. Only include the interactive UI when
      -- rendering markup mode; in original/edited, emit static HTML.
      if critic_mode == 'markup' then
        quarto.doc.add_html_dependency({
          name = 'critic',
          scripts = { 'critic.min.js' },
          stylesheets = { 'critic.css' },
        })
        quarto.doc.include_text('after-body', scriptcode)
      end
    else
      -- latex header always includes mode-appropriate macro definitions
      if latexcode then
        quarto.doc.include_text('in-header', latexcode)
      end
    end
  else
    -- R Markdown: add headers to metadata
    if FORMAT:match 'latex' and latexcode then
      -- For LaTeX, add macro definitions to header-includes
      local header_includes = meta['header-includes']
      if not header_includes then
        header_includes = pandoc.MetaList{}
      elseif header_includes.t == 'MetaInlines' or header_includes.t == 'MetaBlocks' then
        header_includes = pandoc.MetaList{header_includes}
      end
      header_includes[#header_includes + 1] = pandoc.MetaBlocks{pandoc.RawBlock('latex', latexcode)}
      meta['header-includes'] = header_includes
    end
  end

  return meta
end

return {
  { Meta = criticheader },
  { Inlines = Inlines },
  { Strikeout = Strikeout },
  { Str = Str },
}
