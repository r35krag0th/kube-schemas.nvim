-- Test suite for auto-detection functionality
-- Run with: nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

local curl = require("plenary.curl")

-- Fetch the live catalog once
local catalog_url = "https://schemas.r35.io/api/json/catalog.json"
local response = curl.get(catalog_url, {
	accept = "application/json",
})

assert(response.status == 200, "Failed to fetch schema catalog")

local data = vim.json.decode(response.body)
local schema_list = data.schemas or {}

assert(#schema_list > 0, "Schema catalog is empty")

describe("Auto-detect schema matching", function()
	-- Helper function to simulate the find_matching_schema logic
	local function find_matching_schema(api_version, kind)
		local kind_lower = kind:lower()
		local group = ""
		local version = api_version

		if api_version:match("/") then
			group, version = api_version:match("^(.+)/(.+)$")
		end

		local url_patterns = {}

		local function escape_pattern(str)
			return str:gsub("[%.%-]", "%%%1")
		end

		if group ~= "" then
			local group_escaped = escape_pattern(group:lower())
			local kind_escaped = escape_pattern(kind_lower)
			local version_escaped = escape_pattern(version)

			-- Pattern 1: /crds/{group}/{kind}_{version}.json
			table.insert(
				url_patterns,
				"/crds/" .. group_escaped .. "/" .. kind_escaped .. "_" .. version_escaped .. "%.json$"
			)

			-- Pattern 2: /crds/master-standalone/{group}-stable-{kind}_{version}.json
			table.insert(
				url_patterns,
				"/crds/master%-standalone/"
					.. group_escaped
					.. "%-stable%-"
					.. kind_escaped
					.. "_"
					.. version_escaped
					.. "%.json$"
			)

			-- Pattern 3: {kind}-{group}-{version}.json
			local group_short = group:gsub("%..*", "")
			local group_short_escaped = escape_pattern(group_short:lower())
			table.insert(
				url_patterns,
				kind_escaped .. "%-" .. group_short_escaped .. "%-" .. version_escaped .. "%.json$"
			)
		else
			local kind_escaped = escape_pattern(kind_lower)
			local version_escaped = escape_pattern(version)
			table.insert(url_patterns, kind_escaped .. "%-" .. version_escaped .. "%.json$")
		end

		for _, pattern in ipairs(url_patterns) do
			for _, schema in ipairs(schema_list) do
				if schema.url:lower():match(pattern) then
					return schema
				end
			end
		end

		return nil
	end

	describe("Core Kubernetes resources (v1)", function()
		it("should match Service", function()
			local schema = find_matching_schema("v1", "Service")
			assert.is_not_nil(schema)
			assert.truthy(schema.url:lower():match("service%-v1%.json$"))
		end)

		it("should match ServiceAccount", function()
			local schema = find_matching_schema("v1", "ServiceAccount")
			assert.is_not_nil(schema)
			assert.truthy(schema.url:lower():match("serviceaccount%-v1%.json$"))
		end)

		it("should match ConfigMap", function()
			local schema = find_matching_schema("v1", "ConfigMap")
			assert.is_not_nil(schema)
			assert.truthy(schema.url:lower():match("configmap%-v1%.json$"))
		end)

		it("should match Secret", function()
			local schema = find_matching_schema("v1", "Secret")
			assert.is_not_nil(schema)
			assert.truthy(schema.url:lower():match("secret%-v1%.json$"))
		end)

		it("should match Namespace", function()
			local schema = find_matching_schema("v1", "Namespace")
			assert.is_not_nil(schema)
			assert.truthy(schema.url:lower():match("namespace%-v1%.json$"))
		end)
	end)

	describe("Core Kubernetes grouped resources", function()
		it("should match Deployment (apps/v1)", function()
			local schema = find_matching_schema("apps/v1", "Deployment")
			assert.is_not_nil(schema)
			assert.truthy(schema.url:lower():match("deployment%-apps%-v1%.json$"))
		end)

		it("should match StatefulSet (apps/v1)", function()
			local schema = find_matching_schema("apps/v1", "StatefulSet")
			assert.is_not_nil(schema)
			assert.truthy(schema.url:lower():match("statefulset%-apps%-v1%.json$"))
		end)

		it("should match DaemonSet (apps/v1)", function()
			local schema = find_matching_schema("apps/v1", "DaemonSet")
			assert.is_not_nil(schema)
			assert.truthy(schema.url:lower():match("daemonset%-apps%-v1%.json$"))
		end)

		it("should match Ingress (networking.k8s.io/v1)", function()
			local schema = find_matching_schema("networking.k8s.io/v1", "Ingress")
			assert.is_not_nil(schema)
			assert.truthy(schema.url:lower():match("ingress%-networking%-v1%.json$"))
		end)

		it("should match Job (batch/v1)", function()
			local schema = find_matching_schema("batch/v1", "Job")
			assert.is_not_nil(schema)
			assert.truthy(schema.url:lower():match("job%-batch%-v1%.json$"))
		end)

		it("should match CronJob (batch/v1)", function()
			local schema = find_matching_schema("batch/v1", "CronJob")
			assert.is_not_nil(schema)
			assert.truthy(schema.url:lower():match("cronjob%-batch%-v1%.json$"))
		end)
	end)

	describe("Custom Resource Definitions (CRDs)", function()
		it("should match Certificate (cert-manager.io/v1)", function()
			local schema = find_matching_schema("cert-manager.io/v1", "Certificate")
			assert.is_not_nil(schema)
			assert.truthy(
				schema.url:lower():match("/crds/cert%-manager%.io/certificate_v1%.json$")
					or schema.url
						:lower()
						:match("/crds/master%-standalone/cert%-manager%.io%-stable%-certificate_v1%.json$")
			)
		end)

		it("should match HelmRelease (helm.toolkit.fluxcd.io/v2)", function()
			local schema = find_matching_schema("helm.toolkit.fluxcd.io/v2", "HelmRelease")
			assert.is_not_nil(schema)
			assert.truthy(
				schema.url:lower():match("/crds/helm%.toolkit%.fluxcd%.io/helmrelease_v2%.json$")
					or schema.url
						:lower()
						:match("/crds/master%-standalone/helm%.toolkit%.fluxcd%.io%-stable%-helmrelease_v2%.json$")
			)
		end)

		it("should match Kustomization (kustomize.toolkit.fluxcd.io/v1)", function()
			local schema = find_matching_schema("kustomize.toolkit.fluxcd.io/v1", "Kustomization")
			assert.is_not_nil(schema)
			assert.truthy(
				schema.url:lower():match("/crds/kustomize%.toolkit%.fluxcd%.io/kustomization_v1%.json$")
					or schema.url:lower():match(
						"/crds/master%-standalone/kustomize%.toolkit%.fluxcd%.io%-stable%-kustomization_v1%.json$"
					)
			)
		end)

		it("should match VirtualService (networking.istio.io/v1)", function()
			local schema = find_matching_schema("networking.istio.io/v1", "VirtualService")
			assert.is_not_nil(schema)
			assert.truthy(
				schema.url:lower():match("/crds/networking%.istio%.io/virtualservice_v1%.json$")
					or schema.url
						:lower()
						:match("/crds/master%-standalone/networking%.istio%.io%-stable%-virtualservice_v1%.json$")
			)
		end)

		it("should match ClusterIssuer (cert-manager.io/v1)", function()
			local schema = find_matching_schema("cert-manager.io/v1", "ClusterIssuer")
			assert.is_not_nil(schema)
			assert.truthy(
				schema.url:lower():match("/crds/cert%-manager%.io/clusterissuer_v1%.json$")
					or schema.url
						:lower()
						:match("/crds/master%-standalone/cert%-manager%.io%-stable%-clusterissuer_v1%.json$")
			)
		end)
	end)

	describe("Edge cases", function()
		it("should not match non-existent resources", function()
			local schema = find_matching_schema("v1", "NonExistentKind")
			assert.is_nil(schema)
		end)

		it("should not match incorrect apiVersion", function()
			local schema = find_matching_schema("v99", "Service")
			assert.is_nil(schema)
		end)

		it("should handle beta versions", function()
			local schema = find_matching_schema("v1beta1", "Ingress")
			-- May or may not exist depending on catalog
			if schema then
				assert.truthy(schema.url:lower():match("ingress.*v1beta1%.json$"))
			end
		end)
	end)
end)
