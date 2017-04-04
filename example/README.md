```bash
bundle install
padrino rake db:migrate
thin start --ssl --ssl-disable-verify
```
