<script lang="ts">
	import { setContext, type Snippet } from "svelte";
	import { clickOutside } from "svelte-outside";

	export type ElementClicked  = MouseEvent & {
		elementName: string;
	}
	export type ElementClickedHandler = (event: ElementClicked) => void;

	interface DropdownProps {
		children: Snippet<[]>;
		elementClicked?: ElementClickedHandler;
	}

	let { children, elementClicked = () => {} }: DropdownProps = $props();

	let visible = $state(false);
	let parent = $state<HTMLElement | undefined>(undefined);

	export function show(event: MouseEvent) {
		visible = true;
		parent = event.currentTarget as HTMLElement;
		if (!parent) return;
		parent.setAttribute("aria-expanded", "true");
	}

	export function hide(event: Event) {
		if (!visible) return;
		if (!parent) return;
		if (event.target !== parent && !parent?.contains(event.target as Node)) {
			parent?.setAttribute("aria-expanded", "false");
			visible = false;
		}
	}

	function elementClickedHandler(event: ElementClicked) {
		hide(event);
		elementClicked(event);
	}

	setContext("dropdown-click", elementClickedHandler)
</script>

<svelte:window on:keydown={(event) => {
	if (event.key === "Escape" && visible) {
		hide(event);
	}
}} />

<nav 
	class="dropdown" 
	aria-label="Dropdown menu" 
	use:clickOutside={hide} 
	class:visible
	aria-hidden="{!visible}"
	>
	<ul class="dropdown__list">
		{@render children()}
	</ul>
</nav>

<style lang="scss">
	// style inspired by https://github.com/svar-widgets/menu/tree/main?tab=readme-ov-file
	.dropdown {
		border-radius: 4px;
		background-color: white;
		box-shadow: 0px 3px 10px 0px rgba(44, 47, 60, .12);
		padding: .2rem 0;
		position: absolute;
		margin-top: -0.2rem;

		display: none;
		&.visible {
			display: block;
		}
		
		&__list {
			padding: 0;
			margin: 0;
			list-style: none;
		}
	}
</style>