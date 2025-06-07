---
layout: page
title: Publicações
permalink: /livro/
---

## Publicações

Aqui você encontra os livros e documentos produzidos.

<ul>
  {% for item in site.livro %}
    <li>
      <a href="{{ item.url | relative_url }}">{{ item.title }}</a>
      {% if item.date %}<small> ({{ item.date | date: "%Y-%m-%d" }})</small>{% endif %}
    </li>
  {% endfor %}
</ul>
