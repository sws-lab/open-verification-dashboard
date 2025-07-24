<script lang="ts">
	import { getContext } from 'svelte';

	let { content } = $props();
	let item: HTMLLIElement | null = $state(null);

	const parentElement: () => HTMLElement | null = getContext('dropdown-parent');

	function onkeydown(event: KeyboardEvent) {
		if (event.key === 'ArrowDown') {
			event.stopPropagation();
			event.preventDefault();
			if (item?.nextElementSibling) {
				(item.nextElementSibling.children[0] as HTMLElement & { focus: () => void }).focus();
			}
		} else if (event.key === 'ArrowUp') {
			event.stopPropagation();
			event.preventDefault();
			if (item?.previousElementSibling) {
				(item.previousElementSibling.children[0] as HTMLElement & { focus: () => void }).focus();
			} else if (parentElement) {
				parentElement()?.focus();
			}
		}
	}
</script>

<li class="dropdown-item" bind:this={item}>
	{@render content(onkeydown)}
</li>

<style lang="scss">
	.dropdown-item {
		list-style: none;
	}
</style>
