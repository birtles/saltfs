{% from tpldir ~ '/map.jinja' import homu %}

include:
  - python

homu-debugging-packages:
  pkg.installed:
    - pkgs:
      - sqlite3

homu:
  virtualenv.managed:
    - name: /home/servo/homu/_venv
    - venv_bin: virtualenv-3.5
    - python: python3
    - system_site_packages: False
    - require:
      - pkg: python3
      - pip: virtualenv
  pip.installed:
    - pkgs:
      - git+https://github.com/servo/homu@{{ homu.rev }}
      - toml == 0.9.1  # Please ensure this is in sync with requirements.txt
    - upgrade: True
    - bin_env: /home/servo/homu/_venv
    - require:
      - virtualenv: homu
  {% if grains.get('virtual_subtype', '') != 'Docker' %}
  service.running:
    - enable: True
    - require:
      - pip: homu
    - watch:
      - file: /home/servo/homu/cfg.toml
      - file: /etc/init/homu.conf
  {% endif %}

{{ salt['file.dirname'](homu.db) }}:
  file.directory:
    - user: servo
    - group: servo
    - dir_mode: 700
    - require_in:
      - file: /home/servo/homu/cfg.toml

/home/servo/homu/cfg.toml:
  file.managed:
    - source: salt://{{ tpldir }}/files/cfg.toml
    - user: servo
    - group: servo
    - mode: 644
    - template: jinja
    - context:
        db: {{ homu.db }}

/etc/init/homu.conf:
  file.managed:
    - source: salt://{{ tpldir }}/files/homu.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pip: homu
      - file: /home/servo/homu/cfg.toml
