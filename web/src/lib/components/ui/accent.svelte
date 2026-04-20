<script>
	let { children } = $props();
</script>

<span>
	{@render children()}
</span>

<style>
	span {
		color: var(--primary-color);
		font-weight: 600;
	}
</style>
