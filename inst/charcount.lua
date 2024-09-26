--[[
  Counts characters in a document

  Images and tables are ignored; words in text body do not include referece section

  This filter is an adapted mixture of
  https://github.com/pandoc/lua-filters/blob/master/wordcount/wordcount.lua
  and
  https://github.com/pandoc/lua-filters/blob/master/section-refs/section-refs.lua
  ]]

local body_chars = 0
local ref_chars = 0

function is_table (blk)
   return (blk.t == "Table")
end

function is_image (blk)
   return (blk.t == "Image")
end

function remove_all_tables_images (blks)
   local out = {}
   for _, b in pairs(blks) do
      if not (is_table(b) or is_image(b)) then
	      table.insert(out, b)
      end
   end
   return out
end

function is_ref_div (blk)
   return (blk.t == "Div" and blk.identifier == "refs")
end

function is_ref_header (blk)
  local metadata_title = refs_title
  if refs_title then
    metadata_title = metadata_title[1].c:lower():gsub(" ", "-")
  end
  return (blk.t == "Header" and (blk.identifier == "references" or blk.identifier == metadata_title))
end

-- function get_all_refs (blks)
--   local out = {}
--    for _, b in pairs(blks) do
--       if is_ref_div(b) then
-- 	      table.insert(out, b)
--       end
--    end
--    return out
-- end

function remove_all_refs (blks)
   local out = {}
   for _, b in pairs(blks) do
      if not (is_ref_div(b) or is_ref_header(b)) then
	      table.insert(out, b)
      end
   end
   return out
end

body_count = {
  Str = function(el)
    body_chars = body_chars + #el.text
  end,

  Code = function(el)
    local word = el.text:gsub("%s+","")
    body_chars = body_chars + #word
  end,

  CodeBlock = function(el)
    local word = el.text:gsub("%s+","")
    body_chars = body_chars + #word
  end
}

-- ref_count = {
--   Str = function(el)
--     -- we don't count a word if it's entirely punctuation:
--     if el.text:match("%P") then
--       local word = el.text:gsub("%s","")
--       ref_chars = ref_chars + #word
--     end
--   end
-- }

function Pandoc(el)
  if PANDOC_VERSION == nil then -- if pandoc_version < 2.1
    io.stderr:write("WARNING: pandoc >= 2.1 required for wordcount filter\n")
    return el
  end

  local untabled = remove_all_tables_images(el.blocks)

  refs_title = el.meta["reference-section-title"]
  local unreffed = remove_all_refs(untabled)
  pandoc.walk_block(pandoc.Div(unreffed), body_count)
  print(body_chars .. " characters in text body")

  -- local refs = get_all_refs(untabled)
  -- pandoc.walk_block(pandoc.Div(refs), ref_count)
  -- print(ref_chars .. " characters in reference section")

  return el
end
