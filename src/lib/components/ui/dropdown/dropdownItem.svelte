<script lang="ts">
	import { getContext, type Snippet } from 'svelte';
	import type { ElementClickedHandler } from './dropdown.svelte';

	interface DropdownItemProps {
		children: Snippet<[]>;
		href?: string;
		type?: 'default' | 'risky';
		name: string;
	}
	let { children, name, href, type = 'default' }: DropdownItemProps = $props();

	const elementClicked: ElementClickedHandler = getContext('dropdown-click');

	function onclick(event: MouseEvent) {
		if (href) return;
		event.preventDefault();
		event.stopPropagation();
		elementClicked({
			...event,
			elementName: name
		});
	}
</script>

<li class="dropdown_item">
	{#if href}
		<a {href} role="menuitem" class={type}>
			{@render children()}
		</a>
	{:else}
		<button {onclick} role="menuitem" class={type}>
			{@render children()}
		</button>
	{/if}
</li>

<style lang="scss">
	.dropdown_item {
		list-style: none;
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
				background-color: var(--accent-color-pale);
			}

			&.risky {
				color: var(--error-color);
			}
		}
	}
</style>
