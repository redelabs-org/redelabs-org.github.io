---
layout: page
title: Blog
permalink: /blog/
---

## Blog Posts

{% for post in site.posts %}
  <article class="post-item">
    <h3><a href="{{ post.url | relative_url }}">{{ post.title }}</a></h3>
    <p class="post-meta">{{ post.date | date: "%b %-d, %Y" }}</p>
    {% if post.excerpt %}
      {{ post.excerpt }}
    {% else %}
      {{ post.content | strip_html | truncatewords: 50 }}
    {% endif %}
    <p><a href="{{ post.url | relative_url }}">Leia mais...</a></p>
  </article>
{% endfor %}

<!-- Pagination (optional, many themes handle this if configured) -->
{% if paginator.total_pages > 1 %}
<div class="pagination">
  {% if paginator.previous_page %}
    <a href="{{ paginator.previous_page_path | relative_url }}" class="previous">Anterior</a>
  {% else %}
    <span class="previous">Anterior</span>
  {% endif %}
  <span class="page_number ">Página: {{ paginator.page }} de {{ paginator.total_pages }}</span>
  {% if paginator.next_page %}
    <a href="{{ paginator.next_page_path | relative_url }}" class="next">Próxima</a>
  {% else %}
    <span class="next">Próxima</span>
  {% endif %}
</div>
{% endif %}
