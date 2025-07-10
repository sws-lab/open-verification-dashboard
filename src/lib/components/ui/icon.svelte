<script lang="ts">
	let { icon, size = '1em', color = 'var(--main-font-color)' } = $props();
</script>

<span class="icon" data-size={size} data-color={color}>
	{icon}
</span>

<style lang="scss">
	.icon {
		width: attr(data-size);
		height: attr(data-size);
		color: attr(data-color);
		font-family: "Material Symbols Rounded Variable";
	}
</style>