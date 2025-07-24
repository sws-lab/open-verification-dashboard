<script lang="ts">
	import { getContext, type Snippet } from 'svelte';
	import type { ElementClickedHandler } from './dropdown.svelte';
	import DropdownLiItem from './dropdownLiItem.svelte';

	interface DropdownItemProps {
		children: Snippet<[]>;
		href?: string;
		type?: 'default' | 'risky';
		name: string;
	}
	let { children, name, href, type = 'default' }: DropdownItemProps = $props();

	const elementClicked: ElementClickedHandler = getContext('dropdown-click');
	const menuType: 'menu' | 'combobox' = getContext('dropdown-type');

	let role = $derived(menuType === 'combobox' ? 'option' : 'menuitem');

	function onclick(event: MouseEvent) {
		if (href) return;
		event.preventDefault();
		event.stopPropagation();
		elementClicked(
			{
				...event,
				elementName: name
			},
			true
		);
	}
</script>

<DropdownLiItem>
	{#snippet content(onkeydown: (event: KeyboardEvent) => void)}
		{#if href}
			<a {href} {role} class={type} {onkeydown} aria-label={name}>
				{@render children()}
			</a>
		{:else}
			<button {onclick} {role} class={type} {onkeydown} aria-label={name}>
				{@render children()}
			</button>
		{/if}
	{/snippet}
</DropdownLiItem>

<style lang="scss">
	button,
	a {
		font-size: 1rem;
		text-decoration: none;
		padding: 0.5rem;
		cursor: pointer;
		background: none;
		border: none;
		width: 100%;
		height: 100%;
		text-align: left;
		color: inherit;
		display: flex;
		align-items: center;
		gap: 0.5rem;

		box-sizing: border-box;

		&:hover {
			background-color: var(--primary-color-pale);
		}

		&.risky {
			color: var(--error-color);
		}
	}
</style>
