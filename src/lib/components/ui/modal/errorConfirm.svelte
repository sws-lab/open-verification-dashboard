<script lang="ts">
	import type { Snippet } from 'svelte';
	import { Modal } from '.';
	import Button from '../button.svelte';

	interface ErrorConfirmProps {
		title: string;
		onclose: (confirmed: boolean) => void;
		children: Snippet<[]>;
	}

	let { title, onclose, children }: ErrorConfirmProps = $props();

	let modal: Modal | null = $state(null);

	export function open() {
		modal?.open();
	}

	function customOnClose(returnValue: string) {
		onclose(returnValue === 'true');
	}
</script>

<Modal {title} onclose={customOnClose} bind:this={modal}>
	{#snippet content(close)}
		{@render children()}
		<nav class="actions">
			<Button type="error" onclick={() => close(true)}>Ok</Button>
			<Button type="main" onclick={() => close(false)} autofocus>Cancel</Button>
		</nav>
	{/snippet}
</Modal>

<style lang="scss">
	.actions {
		display: flex;
		justify-content: end;
		gap: 1rem;
		margin-top: 1rem;
	}
</style>
