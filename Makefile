.PHONY: status


status:
	echo TBD


source-db-run:
	@podman pull docker.io/lilearningproject/big-star-postgres-multi
	@podman run --name big-star-container -d -p 5432:5432 docker.io/lilearningproject/big-star-postgres-multi -c "wal_level=logical"
