{% macro create_index(schema, table, column) %}
  {% set index = 'idx_' ~ column %}
  {% do log('Create index if does not exist: ' ~ index, info=True) %}

  {% set exists_index %}
    SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE table_schema = "{{ schema }}" AND table_name = "{{ table }}" AND index_name = "{{ index }}"
  {% endset %}

  {% set result = run_query(exists_index) %}
  {% set exists = 0 %}

  {% if execute %}
    {% set exists = result.columns[0].values()[0]|int %}
    {% if exists != 0 %}
      {% do log('Index ' ~ index ~ ' already exists', info=True) %}
    {% else %}
      {% set ddl %}ALTER TABLE {{ schema }}.{{ table }} ADD INDEX {{ index }} ({{ column }}){% endset %}
      {% do run_query(ddl) %}
      {% do log('Index ' ~ index ~ ' created', info=True) %}
    {% endif %}
  {% endif %}
{% endmacro %}
