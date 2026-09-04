-- json-to-types.nvim is a productivity tool that converts JSON data into 
-- TypeScript interfaces or other language types. It simplifies the process 
-- of working with JSON APIs and ensures type safety. Key features include 
-- quick conversion and buffer-wide transformation.
return {
	"Redoxahmii/json-to-types.nvim",
	build = "sh install.sh npm", -- Replace `npm` with your preferred package manager (e.g., yarn, pnpm).
	ft = "json",
	keys = {
		{
			"<leader>cU",
			"<CMD>ConvertJSONtoLang typescript<CR>",
			desc = "Convert JSON to TS",
		},
		{
			"<leader>ct",
			"<CMD>ConvertJSONtoLangBuffer typescript<CR>",
			desc = "Convert JSON to TS Buffer",
		},
	},
}
