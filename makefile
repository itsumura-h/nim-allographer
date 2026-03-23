exec:
	docker compose up -d
	docker compose exec app bash

stop:
	docker compose stop

diff:
	git diff --cached > .diff
