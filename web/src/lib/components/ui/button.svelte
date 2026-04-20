<script lang="ts">
	import type { Snippet } from 'svelte';

	type ButtonType = 'main' | 'secondary' | 'submit' | 'error' | 'link';
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
		italic?: boolean;
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
		slim = false,
		italic = false
	}: ButtonProps = $props();
</script>

<!-- svelte-ignore a11y_autofocus -->
{#if href == ''}
	<button
		type={type === 'submit' ? 'submit' : 'button'}
		class="button-{type}"
		class:center
		class:block
		class:slim
		class:italic
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
		class:italic
		{autofocus}
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

	.block {
		width: 100%;
	}

	.center {
		text-align: center;
	}

	.italic {
		font-style: italic;
	}

	.button-main,
	.button-submit {
		background-color: var(--primary-color);
		color: white;
		border: none;
		@include base-button;

		#{$disabled} {
			background-color: var(--primary-color-disabled);
		}

		&:hover:not(#{$disabled}) {
			background-color: var(--primary-color-hover);
		}
	}

	.button-secondary {
		background-color: white;
		color: var(--primary-color);
		border: 1px solid var(--primary-color);
		@include base-button;

		#{$disabled} {
			border-color: var(--primary-color-disabled);
			color: var(--primary-color-disabled);
			background-color: #f4f4f4;
		}

		&:hover:not(#{$disabled}) {
			background-color: var(--primary-color-hover);
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

	.button-link {
		color: var(--text-color);
		background-color: transparent;
		border: none;
		text-decoration: underline;
		text-align: left;
		font-size: 1rem;
		cursor: pointer;
		margin: 0;
		padding: 0;
	}
</style>
