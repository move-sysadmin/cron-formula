# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import cron with context %}

{%- for task, task_options in cron.get('tasks', {}).items() %}
{%-   set cron_type = task_options.type|d('present') %}

cron.{{ task }}:
  cron.{{ cron_type }}:
    - name: {{ task_options.name }}
    - user: {{ task_options.user|d('root') }}
    - identifier: '{{ task }}'
    {%- if cron_type == 'present' %}
    - commented: {{ task_options.commented|d(False) }}
    {%-   for section in ['minute', 'hour', 'daymonth', 'month', 'dayweek', 'comment', 'special'] %}
    {%-     if section in task_options %}
    - {{ section }}: '{{ task_options[section] }}'
    {%-     endif %}
    {%-   endfor %}
    {%- endif %}

{%- endfor %}

{%- for env, env_options in cron.get('env', {}). items() %}
{%-   set env_type = env_options.type|d('present') %}

cron.{{ env }}:
  cron.env_{{ env_type }}:
    - name: {{ env_options.name }}
    {%- if env_type == 'present' %}
    - value: {{ env_options.value }}
    {%- endif %}
    - user: {{ env_options.user|d('root') }}

{%- endfor %}

{%- for interval in ['hourly', 'daily', 'weekly', 'monthly'] %}
{%- if salt['file.directory_exists']('/etc/cron.' + interval) %}
cron_{{ interval }}_permissions:
  file.directory:
    - name: /etc/cron.{{ interval }}
    - user: root
    - group: root
    - mode: 0700
{%- endif %}
{%- endfor %}

crontab_permission:
  file.managed:
    - name: /etc/crontab
    - user: root
    - group: root
    - mode: 0600
    - create: False

{%- if salt['file.directory_exists']('/etc/cron.d') %}
cron.d_permissions:
  file.directory:
    - name: /etc/cron.d
    - user: root
    - group: root
    - mode: 0700
{%- endif %}

cron_remove_cron.deny:
  file.absent:
    - name: /etc/cron.deny

cron_add_cron.allow:
  file.managed:
    - name: /etc/cron.allow
    - user: root
    - group: root
    - mode: 600

at_remove_at.deny:
  file.absent:
    - name: /etc/at.deny

at_add_at.allow:
  file.managed:
    - name: /etc/at.allow
    - user: root
    - group: root
    - mode: 600
