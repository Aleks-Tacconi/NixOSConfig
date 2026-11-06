.PHONY: help test build run api

help: ## Show help menu
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

init: ## Init project
	@npm install @mui/material @emotion/react @emotion/styled
	@npm create vite@latest frontend -y -- --template react-ts --no-interactive
