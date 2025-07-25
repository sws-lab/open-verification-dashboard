<script lang="ts">
	import { getContext } from 'svelte';
	import type { ElementClickedHandler } from './dropdown.svelte';
	import DropdownLiItem from './dropdownLiItem.svelte';

	let { name, label, hideMenu = false } = $props();
	let value = $state(false);

	const elementClicked: ElementClickedHandler = getContext('dropdown-click');
	const menuType: 'menu' | 'combobox' = getContext('dropdown-type');
	let role = menuType === 'menu' ? 'menuitemcheckbox' : 'option';

	let uid = $props.id();
</script>

<DropdownLiItem>
	{#snippet content(onkeydown: (event: KeyboardEvent) => void)}
		<div
			{role}
			onkeydown={(event) => {
				event.stopPropagation();
				event.preventDefault();
				if (event.key === 'Enter' || event.key === ' ') {
					value = !value;
				}
				onkeydown(event);
			}}
			onclick={(event) => {
				if (event.target !== event.currentTarget) {
					event.currentTarget.focus();
				} else {
					value = !value;
				}
			}}
			tabindex="-1"
		>
			<input
				type="checkbox"
				id={uid}
				bind:checked={value}
				oninput={(event) => {
					if (!event.target) return;
					elementClicked({ elementName: name, target: event.target }, hideMenu);
				}}
			/>
			<label for={uid}>{label}</label>
		</div>
	{/snippet}
</DropdownLiItem>

<style lang="scss">
	div {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		cursor: pointer;
		padding: 0.35rem 0.75rem;

		label {
			cursor: pointer;
		}
	}
</style>
