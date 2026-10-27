-- Convierte los bloques ::: {.fuente} y ::: {.nota-tabla} en llamadas a la
-- función #nota de Typst (Times New Roman 8, interlineado sencillo, según el
-- Art. 15 del manual de redacción de la UNAS). El contenido sigue siendo
-- markdown, así que las citas se procesan con normalidad.
function Div(el)
  if not FORMAT:match("typst") then
    return nil
  end
  if el.classes:includes("fuente") or el.classes:includes("nota-tabla") then
    -- La nota se mantiene unida a la fuente que la sigue
    local apertura = el.classes:includes("nota-tabla") and "#nota(pegada: true)[" or "#nota["
    local bloques = { pandoc.RawBlock("typst", apertura) }
    for _, b in ipairs(el.content) do
      table.insert(bloques, b)
    end
    table.insert(bloques, pandoc.RawBlock("typst", "]"))
    return bloques
  end
end
