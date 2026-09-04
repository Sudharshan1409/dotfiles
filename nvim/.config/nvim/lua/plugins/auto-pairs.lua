-- nvim-autopairs is a simple but essential plugin that automatically closes 
-- brackets, quotes, and other pairs as you type. It improves coding speed and 
-- reduces syntax errors. It features Treesitter integration for smarter 
-- pairing and works seamlessly with nvim-cmp.
return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	config = function()
		require("nvim-autopairs").setup({
			check_ts = true, -- enable treesitter integration
			ts_config = {
				lua = { "string", "source" }, -- it will not add a pair on that treesitter node
				javascript = { "template_string" },
				java = false, -- don't check treesitter on java
			},
		})

		-- Integrate with nvim-cmp
		local cmp_autopairs = require("nvim-autopairs.completion.cmp")
		local cmp = require("cmp")
		cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
	end,
}
