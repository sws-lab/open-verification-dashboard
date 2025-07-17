<script lang="ts">
	import type { Snippet } from 'svelte';

	type ButtonType = 'main' | 'secondary' | 'submit' | 'error';
	interface ButtonProps {
		children: Snippet<[]>;
		onclick?: (event?: MouseEvent) => void;
		type?: ButtonType;
		href?: string;
		center?: boolean;
		autofocus?: boolean;
		block?: boolean;
		disabled?: boolean;
		slim?: boolean;
	}

	let {
		children,
		onclick,
		type = 'main',
		href = '',
		center = false,
		autofocus = false,
		block = false,
		disabled = false,
		slim = false
	}: ButtonProps = $props();
</script>

{#if href == ''}
	<button
		type={type === 'submit' ? 'submit' : 'button'}
		class="button-{type}"
		class:center
		class:block
		class:slim
		onclick={disabled ? undefined : onclick}
		{autofocus}
		{disabled}
	>
		{@render children()}
	</button>
{:else}
	<a
		class="button-{type}"
		href={disabled ? '' : href}
		onclick={disabled ? undefined : onclick}
		class:center
		class:block
		class:slim
		aria-disabled={disabled}
	>
		{@render children()}
	</a>
{/if}

<style lang="scss">
	$disabled: '&[disabled], &[aria-disabled="true"]';

	@mixin base-button {
		padding: 0.6rem 1rem;
		&.slim {
			padding: 0.2rem 0.5rem;
		}
		border-radius: 4px;
		text-decoration: none;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		gap: 0.5rem;
		cursor: pointer;
		transition: background-color 0.2s ease-in-out;
		font-size: 1rem;

		#{$disabled} {
			cursor: not-allowed;
		}
	}

	.center {
		text-align: center;
	}

	.button-main,
	.button-submit {
		background-color: var(--accent-color);
		color: white;
		border: none;
		@include base-button;

		#{$disabled} {
			background-color: var(--accent-color-disabled);
		}

		&:hover:not(#{$disabled}) {
			background-color: var(--accent-color-hover);
		}
	}

	.block {
		width: 100%;
	}

	.button-secondary {
		background-color: white;
		color: var(--accent-color);
		border: 1px solid var(--accent-color);
		@include base-button;

		#{$disabled} {
			border-color: var(--accent-color-disabled);
			color: var(--accent-color-disabled);
			background-color: #f4f4f4;
		}

		&:hover:not(#{$disabled}) {
			background-color: var(--accent-color-hover);
			color: white;
		}
	}

	.button-error {
		color: var(--error-color);
		background-color: white;
		border: 1px solid var(--error-color);
		@include base-button;

		#{$disabled} {
			border-color: var(--error-color-disabled);
			color: var(--error-color-disabled);
			background-color: #f4f4f4;
		}

		&:hover:not(#{$disabled}) {
			background-color: var(--error-color-hover);
			color: white;
		}
	}
</style>
