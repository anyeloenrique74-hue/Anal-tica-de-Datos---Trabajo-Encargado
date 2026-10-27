// Formato según el Manual de normas de redacción y presentación de documentos
// científicos de la UNAS (Resolución N.° 067-2021-CU-R-UNAS).

// Art. 05 y 06: papel A4; márgenes de 3 cm (superior e izquierdo) y 2 cm
// (derecho e inferior).
// Art. 07: se pagina desde la Introducción (página 1); el número va arriba a la
// derecha y no se imprime en la primera página de cada capítulo.
#set page(
  paper: "a4",
  margin: (top: 3cm, left: 3cm, right: 2cm, bottom: 2cm),
  numbering: none,
  header-ascent: 30%,
  header: context {
    let inicio = query(<inicio-cuerpo>)
    if inicio.len() > 0 and inicio.first().location().page() <= here().page() {
      let inicia_capitulo = query(heading.where(level: 1)).any(h => h.location().page() == here().page())
      if not inicia_capitulo {
        align(right, text(size: 12pt, counter(page).display("1")))
      }
    }
  },
)

// Art. 04 y 15: Times New Roman 12, interlineado 1,5, sangría de 1,27 cm.
#set text(font: "Times New Roman", size: 12pt, lang: "es")
#set par(
  justify: true,
  leading: 1.05em,
  spacing: 1.05em,
  first-line-indent: (amount: 1.27cm, all: true),
)
#set list(indent: 0.6cm)
#set enum(indent: 0.6cm)

// Art. 06 y 41: capítulos en página nueva, centrados y en negrita;
// subcapítulos al margen izquierdo, en negrita.
#show heading: set text(size: 12pt, weight: "bold")
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  align(center, block(above: 0pt, below: 1.6em, it.body))
}
#show heading.where(level: 2): it => block(above: 1.6em, below: 1em, sticky: true, it.body)
#show heading.where(level: 3): it => block(above: 1.4em, below: 1em, sticky: true, it.body)

// Art. 13 y 14: «Tabla» y «Figura» en negrita al citarlas en el texto.
#show ref: it => strong(it)

// Títulos de tablas (arriba) y figuras (abajo): la segunda línea se alinea con
// la primera letra después del punto (Anexo B, posdata).
#show figure.caption: it => {
  set par(first-line-indent: 0pt, leading: 0.65em, justify: true)
  set align(left)
  block(width: 100%, grid(
    columns: (auto, 1fr),
    column-gutter: 0.35em,
    strong[#it.supplement #context it.counter.display(it.numbering).],
    it.body,
  ))
}
// Las tablas y figuras no se parten entre páginas, salvo la tabla larga del Anexo B
#show figure: set block(breakable: false)

// Tablas: filete superior, línea bajo el encabezado y filete inferior;
// encabezados en negrita (Art. 13).
#set table(stroke: (x, y) => if y == 0 { (top: 0.8pt) }, inset: (x: 5pt, y: 3.5pt))
#show table: set par(leading: 0.55em, first-line-indent: 0pt, justify: false)
#show table: set text(size: 10.5pt)
#show table.cell.where(y: 0): strong
#show table: it => block(stroke: (bottom: 0.8pt), it)

// Notas y fuentes al pie de tablas y figuras: Times New Roman 8, sencillo.
// Una tabla o figura queda en la misma página que sus notas y su fuente.
#show figure: set block(sticky: true)
#show <tbl-anexo-universidades>: set block(breakable: true, sticky: false)
#let nota(pegada: false, body) = block(above: 0.5em, below: 1.4em, width: 100%, sticky: pegada, {
  set text(size: 8pt)
  set par(leading: 0.45em, spacing: 0.45em, first-line-indent: 0pt, justify: true)
  body
})

// Referencias (APA 7): sangría francesa de 1,27 cm.
#show <refs>: set par(first-line-indent: 0pt, hanging-indent: 1.27cm)
