<script lang="ts">
	import type { Snippet } from "svelte";

	type ButtonType = 'main' | 'secondary' | 'submit';
	interface ButtonProps {
		children: Snippet<[]>;
		onclick?: (event?: MouseEvent) => void;
		type?: ButtonType;
		href?: string;
		center?: boolean;
	}

	let { children, onclick, type = 'main', href = '', center = false }: ButtonProps = $props();
</script>

{#if href == ''}
	<button type={type === 'submit' ? 'submit' : 'button'} class="button-{type}" class:center {onclick}>
		{@render children()}
	</button>
{:else}
	<a class="button-{type}" href={href} {onclick} class:center>
		{@render children()}
	</a>
{/if}


<style lang="scss">
	@mixin base-button {
		padding: 0.6rem 1rem;
		border-radius: 4px;
		text-decoration: none;
		display: inline-block;
		cursor: pointer;
		transition: background-color 0.2s ease-in-out;
		font-size: 1rem;
	}

	.center {
		text-align: center;
	}

	.button-main, .button-submit {
		background-color: var(--accent-color);
		color: white;
		border: none;
		@include base-button;

		&:hover {
			background-color: var(--accent-color-hover);
		}
	}

	.button-submit {
		width: 100%;
	}

	.button-secondary {
		background-color: white;
		color: var(--accent-color);
		border: 1px solid var(--accent-color);
		@include base-button;

		&:hover {
			background-color: var(--accent-color-hover);
			color: white;
		}
	}

</style>