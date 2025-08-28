{% macro create_index(schema, table, column) %}
    {% set index_name = "idx_" ~ column %}
    {% set index_full_name = schema ~ "." ~ table ~ "." ~ index_name %}
    {% do log("Create index if not exist: " ~ index_full_name) %}

    {% set query %}
        SELECT COUNT(*) FROM information_schema.STATISTICS
        WHERE table_schema = "{{ schema }}" AND table_name = "{{ table }}" AND index_name = "{{ index_name }}"
    {% endset %}

    {% set result = run_query(query) %}
    {% if result.columns[0].values()[0] > 0 %}
        {% do log("Index exists: " ~ index_full_name, info=True) %}
    {% else %}
        {% set ddl %}ALTER TABLE {{ schema }}.{{ table }} ADD INDEX {{ index_name }} ({{ column }}){% endset %}
        {% do run_query(ddl) %}
        {% do log("Index created: " ~ index_full_name, info=True) %}
    {% endif %}
{% endmacro %}
