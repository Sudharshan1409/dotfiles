-- Float LocalSend and fzf file picker
hl.window_rule({
	match = {
		class = "^(Share|org\\.localsend\\.localsend_app)$",
	},
	float = true,
	size = { "monitor_w * 0.6", "monitor_h * 0.6" },
	center = true,
})
