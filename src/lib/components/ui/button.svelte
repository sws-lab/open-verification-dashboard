<script lang="ts">
	type ButtonType = 'main' | 'secondary';
	interface ButtonProps {
		children: any;
		type?: ButtonType;
		href?: string;
	}

	let { children, type = 'main', href = ''}: ButtonProps = $props();
</script>

{#if href == ''}
	<button class="button-{type}">
		{@render children()}
	</button>
{:else}
	<a class="button-{type}" href={href}>
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
	}

	.button-main {
		background-color: var(--accent-color);
		color: white;
		border: none;
		@include base-button;

		&:hover {
			background-color: var(--accent-color-hover);
		}
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