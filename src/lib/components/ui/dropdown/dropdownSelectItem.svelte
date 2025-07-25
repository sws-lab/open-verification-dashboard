<script lang="ts">
	import { getContext } from 'svelte';
	import type { ElementClickedHandler } from './dropdown.svelte';
	import DropdownLiItem from './dropdownLiItem.svelte';

	let { name, label, hideMenu = false, value = $bindable(false) } = $props();

	const elementClicked: ElementClickedHandler = getContext('dropdown-click');
	const menuType: 'menu' | 'combobox' = getContext('dropdown-type');
	let role = menuType === 'menu' ? 'menuitemcheckbox' : 'option';

	let uid = $props.id();
</script>

<DropdownLiItem>
	{#snippet content(onkeydown: (event: KeyboardEvent) => void)}
		<!-- svelte-ignore a11y_no_noninteractive_tabindex -->
		<div
			{role}
			onkeydown={(event) => {
				if (event.key === 'Enter' || event.key === ' ') {
					event.stopPropagation();
					event.preventDefault();
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
			tabindex="0"
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
		font-size: 1rem;

		label {
			cursor: pointer;
			user-select: none;
			font-size: 1rem;
		}

		&:hover {
			background-color: var(--primary-color-pale);
		}
	}
</style>
