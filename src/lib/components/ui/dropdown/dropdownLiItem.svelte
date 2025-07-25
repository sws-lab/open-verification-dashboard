<script lang="ts">
	import { getContext } from 'svelte';

	let { content } = $props();
	const uid = $props.id();
	let item: HTMLLIElement | null = $state(null);

	const parentElement: () => HTMLElement | null = getContext('dropdown-parent');

	function onkeydown(event: KeyboardEvent) {
		if (event.key === 'ArrowDown') {
			event.stopPropagation();
			event.preventDefault();
			if (item?.nextElementSibling) {
				const element = item.nextElementSibling.children[0] as HTMLElement & { focus: () => void };
				element.focus();
			}
		} else if (event.key === 'ArrowUp') {
			event.stopPropagation();
			event.preventDefault();
			if (item?.previousElementSibling) {
				const element = item.previousElementSibling.children[0] as HTMLElement & {
					focus: () => void;
				};
				element.focus();
			} else if (parentElement) {
				parentElement()?.focus();
			}
		}
	}
</script>

<li class="dropdown-item" bind:this={item} id={uid}>
	{@render content(onkeydown)}
</li>

<style lang="scss">
	.dropdown-item {
		list-style: none;
	}
</style>
