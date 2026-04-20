<script lang="ts">
	import { setContext, type Snippet } from 'svelte';
	import { clickOutside } from 'svelte-outside';

	export type ElementClicked = {
		target: EventTarget;
		elementName: string;
	};
	export type ElementClickedHandler = (event: ElementClicked, hideDropdown: boolean) => void;

	interface DropdownProps {
		children: Snippet<[]>;
		elementClicked?: (event: ElementClicked) => void;
		id?: string;
		type: 'menu' | 'combobox';
	}

	let { children, elementClicked = () => {}, id, type }: DropdownProps = $props();

	let visible = $state(false);
	let parent = $state<HTMLElement | undefined>(undefined);
	let container: HTMLElement | null = $state(null);

	let x: number = $state(0);
	let y: number = $state(0);
	let top: number = $state(0);

	function parentKeydownListener(event: KeyboardEvent) {
		if (event.key === 'ArrowDown') {
			event.stopPropagation();
			event.preventDefault();
			(
				container?.children[0].children[0].children[0] as HTMLElement & { focus: () => void }
			)?.focus();
		}
		if (event.key === 'Escape') {
			event.stopPropagation();
			event.preventDefault();
			_hide(false);
		}
	}

	function parentBlurListener(event: FocusEvent) {
		if (event.relatedTarget !== null && container?.contains(event.relatedTarget as Node)) return;
		_hide(false);
	}

	export function show(event: MouseEvent) {
		if (visible) hide(event);
		visible = true;
		parent = event.currentTarget as HTMLElement;
		if (!parent) return;
		parent.setAttribute('aria-expanded', 'true');
		parent.addEventListener('keydown', parentKeydownListener);
		parent.addEventListener('blur', parentBlurListener);
		x = parent.offsetLeft;
		y = parent.offsetTop + parent.offsetHeight;
		top = parent.getBoundingClientRect().bottom - window.scrollY;
	}

	function _hide(focus: boolean) {
		parent?.setAttribute('aria-expanded', 'false');
		parent?.removeEventListener('keydown', parentKeydownListener);
		parent?.removeEventListener('blur', parentBlurListener);
		if (focus) {
			parent?.focus();
		}
		visible = false;
	}

	export function hide(event?: { target: EventTarget | null }) {
		if (!visible) return;
		if (!parent) return;
		if (event) {
			if (event.target !== parent && !parent?.contains(event.target as Node)) {
				_hide(false);
			}
		} else {
			_hide(true);
		}
	}

	function elementClickedHandler(event: ElementClicked, hideDropdown: boolean) {
		if (hideDropdown) {
			hide(event);
		}
		elementClicked(event);
	}

	setContext('dropdown-click', elementClickedHandler);
	setContext('dropdown-type', type);
	setContext('dropdown-parent', () => parent);
</script>

<svelte:window />

<nav
	class="dropdown"
	role={type === 'menu' ? 'menu' : 'listbox'}
	aria-orientation="vertical"
	aria-label="Dropdown menu"
	use:clickOutside={hide}
	class:visible
	aria-hidden={!visible}
	{id}
	bind:this={container}
	onkeydown={(event) => {
		if (event.key === 'Escape' && visible) {
			hide(event);
		}
	}}
	style:--x="{x}px"
	style:--y="{y}px"
	style:--top="{top}px"
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
		box-shadow: 0px 3px 10px 0px rgba(44, 47, 60, 0.12);
		padding: 0.2rem 0;
		position: absolute;
		top: var(--y);
		left: var(--x);
		margin-top: -0.2rem;
		z-index: 1000;
		overflow-y: scroll;
		max-height: calc(100vh - var(--top) - 1rem);

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
