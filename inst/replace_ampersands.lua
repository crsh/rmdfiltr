local lang_tag = nil

local and_dictionary = {
  de = "und",
  en = "and",
  nl = "en",
  es = "y"
}

function get_lang_tag (meta)
  if meta.lang then
    lang_tag = meta.lang[1].c:gsub("-%a+", "")
  else
    lang_tag = "en"
  end
end

function replace_ampersands (el)
  if el.c[1][1].mode == "AuthorInText" then
    for key,value in pairs(el.c[2]) do
      for key2,value2 in pairs(value) do
        if value2 == "&" then el.c[2][key][key2] = and_dictionary[lang_tag] end
      end
    end
  end
  return el
end

return {{Meta = get_lang_tag}, {Cite = replace_ampersands}}
