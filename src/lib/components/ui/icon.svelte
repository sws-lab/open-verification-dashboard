<script lang="ts">
	let { icon, size = '1em', color = 'inherit' } = $props();
</script>

<span class="icon" style:--data-size={size} style:--data-color={color}>
	{icon}
</span>

<style lang="scss">
	.icon {
		font-size: var(--data-size);
		line-height: var(--data-size);
		height: var(--data-size);
		color: var(--data-color);
		font-family: "Material Symbols Rounded Variable";
		user-select: none;
	}
</style>