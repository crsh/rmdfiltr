local lang_tag = nil

local and_dictionary = {
  en = "and",
  es = "y",
  fr = "et",
  de = "und",
  nl = "en"
}

function get_lang_tag (meta)
  if meta.lang then
    lang_tag = meta.lang[1].c:gsub("-%a+", "")
  else
    -- Default to English if not otherwise specified
    lang_tag = "en"
  end

  -- Default to English if translation is unavailable
  if not and_dictionary[lang_tag] then
    print("\nWarning in replace_ampersands.lua:\n  Translation unavailable, defaulting to English. Request additional languages at <https://github.com/crsh/rmdfiltr>. \n\n")
    and_dictionary[lang_tag] = "and"
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
