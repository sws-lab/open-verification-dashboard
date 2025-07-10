<script>
	let { children } = $props();
</script>

<span>
	{@render children()}
</span>

<style>
	span {
		color: var(--accent-color);
		font-weight: 600;
	}
</style>