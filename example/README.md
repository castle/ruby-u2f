```bash
bundle install
padrino rake db:migrate
thin start --ssl-disable-verify
```
