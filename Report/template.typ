// Report Template

#show raw.where(block: true): set block(
  fill: luma(250),
  inset: 6pt,
  radius: 3pt,
)

#show raw.where(block: true): set text(
  size: 9pt,
  font: ("Liberation Mono", "Noto Serif CJK SC"),
)

#show raw.where(block: true): set par(
  leading: 1.15em,
)

// 内联代码：等宽 + 衬线汉字
#show raw.where(block: false): set text(
  font: ("Liberation Mono", "Noto Serif CJK SC"),
)

#set page(
  paper: "a4",
  margin: (left: 2.6cm, right: 2.6cm, top: 2.4cm, bottom: 2.8cm),
  numbering: "1",
  number-align: bottom + center,
  header: context [
    #text(size: 12pt, fill: gray.darken(25%))[deep-learning-from-scratch]
    #h(1fr)
    #text(size: 12pt, fill: gray.darken(25%))[#datetime.today().display("[month repr:short] [day], [year]")]
  ],
  footer: context align(center)[
    #text(size: 11pt, fill: gray.darken(50%))[#counter(page).display()]
  ],
)

// Typography: classic academic style
#set text(
  font: ("Liberation Serif", "Noto Serif CJK SC"),
  size: 14pt,
  lang: "en",
)

// Figure caption: smaller, italic, muted gray — distinct from body text
#show figure.caption: set text(
  size: 11pt,
  font: ("Liberation Serif", "Noto Serif CJK SC"),
  style: "italic",
  fill: luma(90),
)

#show figure.caption: set par(
  leading: 1.0em,
)

// Paragraph style for English reports
#set par(
  justify: true,
  first-line-indent: 0em,
  leading: 0.75em,
  spacing: 1em,
)

// Heading hierarchy
#set heading(numbering: "1.")
#show heading.where(level: 1): it => [
  #v(0.9em)
  #text(size: 20pt, weight: "bold", it.body)
  #v(0.35em)
]
#show heading.where(level: 2): it => [
  #v(0.55em)
  #text(size: 15pt, weight: "semibold", it.body)
  #v(0.25em)
]
#show heading.where(level: 3): it => [
  #v(0.35em)
  #text(size: 13pt, weight: "semibold", it.body)
  #v(0.15em)
]

// Cover page
#align(center + horizon)[
  #v(0%)
  #text(size: 35pt, weight: "bold")[
    Lab 2
    \
  ]
  #v(0%)
  #text(size: 25pt, weight: "bold")[
    NumPy Fundamentals and Manual Neural Network Implementation
  ]
  #image("icon_ZJU.png", width: 40%)
  #v(2em)
  #text(size: 20pt)[Author: Chuanyu Wang]
  #v(0.5em)
  #text(size: 20pt)[Time: 2026-6-16]
  #v(0.5em)
]

#pagebreak()

// Main report starts here
